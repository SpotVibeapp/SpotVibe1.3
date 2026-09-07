import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/el_paso_events.dart';
import '../data/event_dedupe.dart';
import '../data/event_images.dart';
import '../models/event.dart';
import 'live_event_source.dart';

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

/// Recent start window used to find Ticketmaster events that may still be
/// happening now. They remain in the feed only when Ticketmaster supplies an
/// explicit end time that is still ahead; SpotVibe never invents one.
const kTicketmasterOngoingLookback = Duration(hours: 24);

/// Largest page the Discovery API will return.
const int kTicketmasterPageSize = 200;

/// Most pages fetched per search. Ticketmaster caps deep paging at
/// `size * page < 1000`, so 5 full pages is the hard ceiling; 3 keeps every
/// feed refresh (once a minute) inside the 5 req/s and 5000/day quotas.
const int kTicketmasterMaxPages = 3;

/// Ticketmaster rejects radii above 200 miles.
const double kTicketmasterMaxRadiusMiles = 200;

/// Whole-mile radius accepted by the Discovery API. Non-finite or tiny
/// values fall back to 1 mile; anything above the API ceiling is clamped
/// rather than rejected with a 400.
int ticketmasterRadiusParam(double miles) {
  if (!miles.isFinite) return 1;
  return _clampInt(miles.round(), 1, kTicketmasterMaxRadiusMiles.round());
}

/// `num.clamp` is typed as returning `num`; this keeps ints as ints.
int _clampInt(int value, int min, int max) =>
    value < min ? min : (value > max ? max : value);

/// Number of pages a search may fetch: the caller's budget, cut down so
/// `size * page` never crosses Ticketmaster's 1000-item deep-paging limit.
int ticketmasterPageBudget(int pageSize, int maxPages) {
  if (pageSize <= 0 || maxPages <= 0) return 0;
  // Page indices are 0-based; the last allowed index p satisfies
  // pageSize * p < 1000, so the count is that index + 1.
  final deepPagingCap = ((1000 - 1) ~/ pageSize) + 1;
  return maxPages < deepPagingCap ? maxPages : deepPagingCap;
}

/// Formats an exact UTC lower-bound accepted by the Discovery API.
///
/// A lower-bound prevents an ascending first page from being consumed by old
/// listings that the app correctly removes. The short lookback above keeps
/// source-defined ongoing events eligible as well as future events.
/// Ticketmaster's documented classifications for the SpotVibe categories
/// that map unambiguously. Other categories stay broad because forcing them
/// into Ticketmaster's different taxonomy would hide real listings.
String? ticketmasterClassificationFor(String? category) {
  switch (category) {
    case 'Music':
      return 'Music';
    case 'Sports':
      return 'Sports';
    case 'Arts':
      return 'Arts & Theatre';
    case 'Family':
      return 'Family';
    case 'Film':
      return 'Film';
    default:
      return null;
  }
}

String ticketmasterStartDateTime(DateTime time) {
  final utc = time.toUtc();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${twoDigits(utc.month)}-${twoDigits(utc.day)}T'
      '${twoDigits(utc.hour)}:${twoDigits(utc.minute)}:${twoDigits(utc.second)}Z';
}

class TicketmasterService implements LiveEventSource {
  TicketmasterService({
    Dio? dio,
    String? apiKey,
    DateTime Function()? clock,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            )),
        _apiKey = apiKey ?? kTicketmasterApiKey,
        _clock = clock ?? DateTime.now;

  final Dio _dio;
  final String _apiKey;
  final DateTime Function() _clock;

  static const _endpoint =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  @override
  EventSource get source => EventSource.ticketmaster;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  bool ownsId(String id) => id.startsWith('tm_');

  final Map<String, Event> _byId = {};

  @override
  Future<List<Event>> search({
    String? city,
    String? stateCode,
    String? keyword,
    String? category,
    double? lat,
    double? lng,
    double radiusMiles = 40,
    int size = kTicketmasterPageSize,
    int maxPages = kTicketmasterMaxPages,
  }) async {
    if (!isConfigured) {
      debugPrint('Ticketmaster: no API key. '
          'Run with --dart-define=TICKETMASTER_API_KEY=...');
      return const [];
    }

    try {
      // Include a small source-defined live-event window as well as future
      // listings. A strict `startDateTime: now` would permanently remove an
      // ongoing Ticketmaster event after a feed refresh, even when the API
      // supplied a real end time.
      final now = _clock();
      final pageSize = _clampInt(size, 1, kTicketmasterPageSize);
      final params = <String, dynamic>{
        'apikey': _apiKey,
        'countryCode': 'US',
        'size': pageSize,
        'sort': 'date,asc',
        'startDateTime': ticketmasterStartDateTime(
          now.subtract(kTicketmasterOngoingLookback),
        ),
        'radius': ticketmasterRadiusParam(radiusMiles),
        'unit': 'miles',
        'includeTBA': 'no',
        'includeTBD': 'no',
        'includeTest': 'no',
      };
      final cleanedKeyword = keyword?.trim() ?? '';
      if (cleanedKeyword.isNotEmpty) {
        params['keyword'] = cleanedKeyword;
      }
      final classification = ticketmasterClassificationFor(category);
      if (classification != null) {
        params['classificationName'] = classification;
      }
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

      // Walk pages in date order until one comes back short (no more
      // listings) or the page budget is spent. The first page is fetched
      // even if a later one fails, so a flaky page 2 degrades to "fewer
      // events" rather than an empty feed.
      final events = <Event>[];
      final pages = ticketmasterPageBudget(pageSize, maxPages);
      for (var page = 0; page < pages; page++) {
        final List<dynamic> raw;
        try {
          final response = await _dio.get(
            _endpoint,
            queryParameters: {...params, 'page': page},
          );
          raw = _eventsFromPage(response.data);
        } catch (error) {
          if (page == 0) rethrow;
          debugPrint(
            'Ticketmaster page $page failed (${error.runtimeType}); '
            'keeping ${events.length} events from earlier pages.',
          );
          break;
        }

        for (final item in raw) {
          if (item is! Map) continue;
          final event = eventFromTicketmaster(Map<String, dynamic>.from(item));
          if (event == null) continue;
          if (looksLikeStandaloneAddon(event.title)) continue;
          // Future listings are visible normally. A started listing stays
          // visible only if its source supplied a real end after `now`.
          if (!event.isVisibleAt(now: now)) continue;
          events.add(event);
          _byId[event.id] = event;
        }

        if (raw.length < pageSize) break;
      }
      return events;
    } catch (error) {
      // Dio errors can contain the complete request URL, including the key.
      debugPrint('Ticketmaster search failed (${error.runtimeType}).');
      return const [];
    }
  }

  /// Pulls the raw event list out of one Discovery response body. An empty
  /// list also covers the "no results" shape, where `_embedded` is absent.
  static List<dynamic> _eventsFromPage(Object? data) {
    if (data is! Map) return const [];
    final embedded = data['_embedded'];
    if (embedded is! Map) return const [];
    final raw = embedded['events'];
    return raw is List ? raw : const [];
  }

  @override
  Future<Event?> getEventById(String id) async {
    final cached = _byId[id];
    if (cached != null) return cached;
    if (!isConfigured || !ownsId(id)) return null;
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
    } catch (error) {
      // Avoid logging a Dio request URL that could include the API key.
      debugPrint('Ticketmaster getEventById failed (${error.runtimeType}).');
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
  final dateTime = (start['dateTime'] as String?)?.trim();
  if (dateTime != null && dateTime.isNotEmpty) {
    final parsed = DateTime.tryParse(dateTime);
    if (parsed != null) return parsed.toLocal();
  }
  final localDate = start['localDate'] as String?;
  final localTime = start['localTime'] as String? ?? '19:00:00';
  if (localDate == null) return null;
  return DateTime.tryParse('${localDate}T$localTime');
}

/// Reads Ticketmaster's explicit event end only. Unlike the start parser,
/// there is deliberately no default end time: a made-up duration could keep a
/// finished event in the discovery feed and falsely label it as live.
DateTime? _parseEnd(Map<String, dynamic> json) {
  final dates = json['dates'];
  if (dates is! Map) return null;
  final end = dates['end'];
  if (end is! Map) return null;

  final dateTime = (end['dateTime'] as String?)?.trim();
  if (dateTime != null && dateTime.isNotEmpty) {
    final parsed = DateTime.tryParse(dateTime);
    if (parsed != null) return parsed.toLocal();
  }

  final localDate = end['localDate'] as String?;
  final localTime = end['localTime'] as String?;
  if (localDate == null || localTime == null || localTime.isEmpty) return null;
  return DateTime.tryParse('${localDate}T$localTime');
}

/// Visible for tests.
Event? eventFromTicketmaster(Map<String, dynamic> json) {
  final id = json['id'] as String?;
  final name = json['name'] as String?;
  if (id == null || name == null || name.trim().isEmpty) return null;
  final start = _parseStart(json);
  if (start == null) return null;
  final rawEnd = _parseEnd(json);
  // Ignore malformed/source-inconsistent ends rather than claiming an event
  // is live past its real boundary.
  final end = rawEnd != null && rawEnd.isAfter(start) ? rawEnd : null;

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
    endDateTime: end,
    location: venueName,
    address: address,
    city: city,
    state: state,
    zipCode: zip,
    cost: cost,
    // Ticketmaster listings are ticketed by definition — never show "Free"
    // just because this event had no published price range.
    isTicketed: true,
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
