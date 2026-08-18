import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/el_paso_events.dart';
import '../data/event_dedupe.dart';
import '../data/event_images.dart';
import '../models/event.dart';

export '../data/event_images.dart';

/// Live Ticketmaster Discovery API.
///
/// The API key is supplied at build/run time and must never be committed:
///   flutter run --dart-define=TICKETMASTER_API_KEY=your_key
///
/// Get a free key: https://developer.ticketmaster.com/
///
/// Without a key the feed still shows the curated El Paso seed and stays
/// empty for other cities instead of failing.
const String kTicketmasterApiKey = String.fromEnvironment(
  'TICKETMASTER_API_KEY',
);

class TicketmasterService {
  TicketmasterService({Dio? dio, String? apiKey})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            )),
        _apiKey = apiKey ?? kTicketmasterApiKey;

  final Dio _dio;
  final String _apiKey;

  static const _endpoint =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  bool get isConfigured => _apiKey.isNotEmpty;

  final Map<String, Event> _byId = {};

  Future<List<Event>> search({
    String? city,
    String? stateCode,
    double? lat,
    double? lng,
    double radiusMiles = 40,
    int size = 80,
  }) async {
    if (!isConfigured) {
      debugPrint('Ticketmaster: no API key. '
          'Run with --dart-define=TICKETMASTER_API_KEY=...');
      return const [];
    }

    try {
      final params = <String, dynamic>{
        'apikey': _apiKey,
        'countryCode': 'US',
        'size': size.clamp(1, 200),
        'sort': 'date,asc',
        'radius': radiusMiles.round().clamp(1, 200),
        'unit': 'miles',
        'includeTBA': 'no',
        'includeTBD': 'no',
        'includeTest': 'no',
      };
      if (lat != null && lng != null) {
        params['latlong'] = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
      } else if (city != null && city.isNotEmpty) {
        params['city'] = city;
        if (stateCode != null && stateCode.isNotEmpty) {
          params['stateCode'] = stateCode;
        }
      } else {
        return const [];
      }

      final response = await _dio.get(_endpoint, queryParameters: params);
      final data = response.data;
      if (data is! Map) return const [];
      final embedded = data['_embedded'];
      if (embedded is! Map) return const [];
      final raw = embedded['events'];
      if (raw is! List) return const [];

      final events = <Event>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final event = eventFromTicketmaster(Map<String, dynamic>.from(item));
        if (event == null) continue;
        if (looksLikeStandaloneAddon(event.title)) continue;
        if (!event.dateTime.isAfter(DateTime.now().subtract(const Duration(hours: 2)))) {
          continue;
        }
        events.add(event);
        _byId[event.id] = event;
      }
      return events;
    } catch (e) {
      debugPrint('Ticketmaster search failed: $e');
      return const [];
    }
  }

  Future<Event?> getEventById(String id) async {
    final cached = _byId[id];
    if (cached != null) return cached;
    if (!isConfigured || !id.startsWith('tm_')) return null;
    final tmId = id.substring(3);
    try {
      final response = await _dio.get(
        'https://app.ticketmaster.com/discovery/v2/events/$tmId.json',
        queryParameters: {'apikey': _apiKey},
      );
      final data = response.data;
      if (data is! Map) return null;
      final event = eventFromTicketmaster(Map<String, dynamic>.from(data));
      if (event != null) _byId[event.id] = event;
      return event;
    } catch (e) {
      debugPrint('Ticketmaster getEventById failed: $e');
      return null;
    }
  }
}

bool _isTmFallbackFlag(dynamic value) => value == true || value == 'true';

bool _isAttractionPath(String url) {
  final lower = url.toLowerCase();
  return lower.contains('/dam/a/') || lower.contains('/dam/t/');
}

bool _isUniqueTmImage(Map raw) {
  final url = raw['url'] as String? ?? '';
  if (url.isEmpty || isStockTicketmasterImage(url)) return false;
  // Team / artist art is unique even when TM marks it fallback:true.
  if (_isAttractionPath(url)) return true;
  if (_isTmFallbackFlag(raw['fallback'])) return false;
  return true;
}

int _imageScore(Map raw, {required bool preferLarge}) {
  final url = raw['url'] as String? ?? '';
  final width = (raw['width'] as num?)?.toInt() ?? 0;
  if (preferLarge && width > 0 && width < 400) return -1;
  final ratio = (raw['ratio'] as String? ?? '').toLowerCase();
  var score = width;
  // Cards are wide. A 16:9 crop should beat a same-size square, but a much
  // larger 3:2 artist photo can still win.
  if (ratio == '16_9') score += 1500;
  if (ratio == '3_2' || ratio == '4_3') score += 150;
  if (_isAttractionPath(url)) score += 2500;
  // Genre stock (baseball glove, concert crowd) must never beat team art.
  if (isStockTicketmasterImage(url)) score -= 10000;
  if (_isTmFallbackFlag(raw['fallback']) && !_isAttractionPath(url)) {
    score -= 2000;
  }
  return score;
}

String _bestUrl(List<Map> pool) {
  if (pool.isEmpty) return '';
  String pickFrom(List<Map> images, {required bool preferLarge}) {
    String best = '';
    var bestScore = -1;
    for (final raw in images) {
      final score = _imageScore(raw, preferLarge: preferLarge);
      if (score > bestScore) {
        bestScore = score;
        best = raw['url'] as String? ?? '';
      }
    }
    return best;
  }

  final large = pickFrom(pool, preferLarge: true);
  if (large.isNotEmpty) return large;
  return pickFrom(pool, preferLarge: false);
}

/// Picks a Ticketmaster image.
///
/// Prefer unique attraction art (`/dam/a/`, `fallback: false`). If that's all
/// the event has, still return the best stock / fallback photo — a repeated
/// concert shot is better than a blank card. El Paso listings are often
/// stock-only.
String pickTicketmasterImage(List images) {
  final unique = <Map>[];
  final any = <Map>[];
  for (final raw in images) {
    if (raw is! Map) continue;
    final url = raw['url'] as String? ?? '';
    if (url.isEmpty) continue;
    any.add(raw);
    if (_isUniqueTmImage(raw)) unique.add(raw);
  }
  final preferred = _bestUrl(unique);
  if (preferred.isNotEmpty) return preferred;
  return _bestUrl(any);
}

/// Event images first, then attractions (artist), then venues.
List<Map<String, dynamic>> collectTicketmasterImages(Map<String, dynamic> json) {
  final out = <Map<String, dynamic>>[];
  void addAll(dynamic raw) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is Map) out.add(Map<String, dynamic>.from(item));
    }
  }

  addAll(json['images']);
  final embedded = json['_embedded'];
  if (embedded is Map) {
    for (final key in const ['attractions', 'venues']) {
      final list = embedded[key];
      if (list is! List) continue;
      for (final entity in list) {
        if (entity is Map) addAll(entity['images']);
      }
    }
  }
  return out;
}

String _mapClassification(Map<String, dynamic> json) {
  final classifications = json['classifications'];
  String segment = '';
  String genre = '';
  if (classifications is List && classifications.isNotEmpty) {
    final first = classifications.first;
    if (first is Map) {
      segment = ((first['segment'] as Map?)?['name'] as String? ?? '')
          .toLowerCase();
      genre =
          ((first['genre'] as Map?)?['name'] as String? ?? '').toLowerCase();
    }
  }
  if (segment.contains('sport')) return 'Sports';
  if (segment.contains('music')) return 'Music';
  if (genre.contains('dance')) return 'Dance';
  if (segment.contains('art') ||
      segment.contains('theatre') ||
      segment.contains('theater')) {
    return 'Arts';
  }
  if (genre.contains('comedy')) return 'Fun & Games';
  if (segment.contains('misc') && genre.contains('food')) return 'Food';
  return 'Arts';
}

DateTime? _parseStart(Map<String, dynamic> json) {
  final dates = json['dates'];
  if (dates is! Map) return null;
  final start = dates['start'];
  if (start is! Map) return null;
  final dateTime = start['dateTime'] as String?;
  if (dateTime != null) return DateTime.tryParse(dateTime)?.toLocal();
  final localDate = start['localDate'] as String?;
  final localTime = start['localTime'] as String? ?? '19:00:00';
  if (localDate == null) return null;
  return DateTime.tryParse('${localDate}T$localTime');
}

/// Visible for tests.
Event? eventFromTicketmaster(Map<String, dynamic> json) {
  final id = json['id'] as String?;
  final name = json['name'] as String?;
  if (id == null || name == null || name.trim().isEmpty) return null;
  final start = _parseStart(json);
  if (start == null) return null;

  String venueName = '';
  String address = '';
  String city = '';
  String state = '';
  String zip = '';
  double lat = 0;
  double lng = 0;
  final embedded = json['_embedded'];
  if (embedded is Map) {
    final venues = embedded['venues'];
    if (venues is List && venues.isNotEmpty && venues.first is Map) {
      final venue = Map<String, dynamic>.from(venues.first as Map);
      venueName = venue['name'] as String? ?? '';
      final addr = venue['address'];
      if (addr is Map) {
        address = addr['line1'] as String? ?? '';
      }
      final cityMap = venue['city'];
      if (cityMap is Map) city = cityMap['name'] as String? ?? '';
      final stateMap = venue['state'];
      if (stateMap is Map) {
        state = stateMap['stateCode'] as String? ??
            stateMap['name'] as String? ??
            '';
      }
      zip = venue['postalCode'] as String? ?? '';
      final loc = venue['location'];
      if (loc is Map) {
        lat = double.tryParse('${loc['latitude']}') ?? 0;
        lng = double.tryParse('${loc['longitude']}') ?? 0;
      }
    }
  }

  var imageUrl = pickTicketmasterImage(collectTicketmasterImages(json));
  if (isGenericEventImage(imageUrl)) {
    final venuePhoto = venueImageFor(venueName, title: name);
    if (venuePhoto != null) imageUrl = venuePhoto;
  }

  double? cost;
  final priceRanges = json['priceRanges'];
  if (priceRanges is List && priceRanges.isNotEmpty && priceRanges.first is Map) {
    final min = (priceRanges.first as Map)['min'];
    if (min is num) cost = min.toDouble();
  }

  final info = (json['info'] as String?) ??
      (json['pleaseNote'] as String?) ??
      '';
  final description = info.trim().isNotEmpty
      ? info.trim()
      : '$name at ${venueName.isEmpty ? city : venueName}. Tickets via Ticketmaster.';

  return Event(
    id: 'tm_$id',
    title: name.trim(),
    description: description,
    dateTime: start,
    location: venueName,
    address: address,
    city: city,
    state: state,
    zipCode: zip,
    cost: cost,
    imageUrl: imageUrl,
    category: _mapClassification(json),
    organizerName: venueName.isEmpty ? 'Ticketmaster' : venueName,
    organizerAvatarUrl:
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(venueName.isEmpty ? 'TM' : venueName)}&size=200&background=026CDF&color=fff',
    latitude: lat,
    longitude: lng,
    source: EventSource.ticketmaster,
    sourceUrl: json['url'] as String?,
  );
}
