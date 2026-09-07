import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/el_paso_events.dart';
import '../data/event_dedupe.dart';
import '../data/event_images.dart';
import '../models/event.dart';
import 'live_event_source.dart';

/// Live SeatGeek Platform API (https://seatgeek.github.io/).
///
/// The client id is supplied at build/run time and must never be committed:
///   flutter run --dart-define=SEATGEEK_CLIENT_ID=your_client_id
/// or via `--dart-define-from-file=secrets.json`.
///
/// Get a free client id: https://seatgeek.com/account/develop
///
/// Without a client id the source is simply skipped; the feed keeps
/// working from Ticketmaster and curated rows exactly as before.
const String kSeatGeekClientId = String.fromEnvironment('SEATGEEK_CLIENT_ID');

/// Largest page SeatGeek serves per request.
const int kSeatGeekPageSize = 100;

/// Pages per search. Two full pages already exceed what a 200-mile El Paso
/// circle returns; the cap mostly protects denser metros and the quota.
const int kSeatGeekMaxPages = 3;

/// SeatGeek accepts any range, but the feed never needs more than the same
/// ceiling Ticketmaster imposes, and matching it keeps the two comparable.
const double kSeatGeekMaxRadiusMiles = 200;

/// SeatGeek taxonomy names for the SpotVibe categories that map cleanly.
/// Others are left unfiltered so nothing real is hidden.
String? seatGeekTaxonomyFor(String? category) {
  switch (category) {
    case 'Music':
      return 'concert';
    case 'Sports':
      return 'sports';
    case 'Arts':
      return 'theater';
    case 'Fun & Games':
      return 'comedy';
    case 'Family':
      return 'family';
    case 'Dance':
      return 'dance_performance_tour';
    case 'Film':
      return 'film';
    default:
      return null;
  }
}

/// `range` query value: whole miles, at least 1, at most the shared ceiling.
String seatGeekRangeParam(double miles) {
  if (!miles.isFinite) return '1mi';
  final whole = miles.round();
  final clamped = whole < 1
      ? 1
      : (whole > kSeatGeekMaxRadiusMiles.round()
          ? kSeatGeekMaxRadiusMiles.round()
          : whole);
  return '${clamped}mi';
}

class SeatGeekService implements LiveEventSource {
  SeatGeekService({
    Dio? dio,
    String? clientId,
    DateTime Function()? clock,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            )),
        _clientId = clientId ?? kSeatGeekClientId,
        _clock = clock ?? DateTime.now;

  final Dio _dio;
  final String _clientId;
  final DateTime Function() _clock;

  static const _endpoint = 'https://api.seatgeek.com/2/events';

  @override
  EventSource get source => EventSource.seatgeek;

  @override
  bool get isConfigured => _clientId.isNotEmpty;

  @override
  bool ownsId(String id) => id.startsWith('sg_');

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
    int maxPages = kSeatGeekMaxPages,
  }) async {
    if (!isConfigured) return const [];

    try {
      final now = _clock();
      final params = <String, dynamic>{
        'client_id': _clientId,
        'per_page': kSeatGeekPageSize,
        'sort': 'datetime_utc.asc',
        // SeatGeek publishes no end times, so a show that has already
        // started can never be proven still-on. Ask from now and let the
        // visibility check below drop anything the clock has passed.
        'datetime_utc.gte': _isoUtc(now),
      };
      final cleanedKeyword = keyword?.trim() ?? '';
      if (cleanedKeyword.isNotEmpty) params['q'] = cleanedKeyword;
      final taxonomy = seatGeekTaxonomyFor(category);
      if (taxonomy != null) params['taxonomies.name'] = taxonomy;

      if (lat != null && lng != null) {
        params['lat'] = lat.toStringAsFixed(4);
        params['lon'] = lng.toStringAsFixed(4);
        params['range'] = seatGeekRangeParam(radiusMiles);
      } else if (city != null && city.isNotEmpty) {
        params['venue.city'] = city;
        if (stateCode != null && stateCode.isNotEmpty) {
          params['venue.state'] = stateCode;
        }
      } else {
        return const [];
      }

      final events = <Event>[];
      // SeatGeek pages are 1-indexed.
      for (var page = 1; page <= maxPages; page++) {
        final List<dynamic> raw;
        try {
          final response = await _dio.get(
            _endpoint,
            queryParameters: {...params, 'page': page},
          );
          raw = _eventsFromPage(response.data);
        } catch (error) {
          if (page == 1) rethrow;
          debugPrint(
            'SeatGeek page $page failed (${error.runtimeType}); '
            'keeping ${events.length} events from earlier pages.',
          );
          break;
        }

        for (final item in raw) {
          if (item is! Map) continue;
          final event = eventFromSeatGeek(Map<String, dynamic>.from(item));
          if (event == null) continue;
          if (looksLikeStandaloneAddon(event.title)) continue;
          if (!event.isVisibleAt(now: now)) continue;
          events.add(event);
          _byId[event.id] = event;
        }

        if (raw.length < kSeatGeekPageSize) break;
      }
      return events;
    } catch (error) {
      // Dio errors can include the full request URL, i.e. the client id.
      debugPrint('SeatGeek search failed (${error.runtimeType}).');
      return const [];
    }
  }

  static List<dynamic> _eventsFromPage(Object? data) {
    if (data is! Map) return const [];
    final raw = data['events'];
    return raw is List ? raw : const [];
  }

  @override
  Future<Event?> getEventById(String id) async {
    final cached = _byId[id];
    if (cached != null) return cached;
    if (!isConfigured || !ownsId(id)) return null;
    final sgId = id.substring(3);
    if (sgId.isEmpty || int.tryParse(sgId) == null) return null;
    try {
      final response = await _dio.get(
        '$_endpoint/$sgId',
        queryParameters: {'client_id': _clientId},
      );
      final data = response.data;
      if (data is! Map) return null;
      final event = eventFromSeatGeek(Map<String, dynamic>.from(data));
      if (event != null) _byId[event.id] = event;
      return event;
    } catch (error) {
      debugPrint('SeatGeek event lookup failed (${error.runtimeType}).');
      return null;
    }
  }
}

String _isoUtc(DateTime time) {
  final utc = time.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}';
}

/// SeatGeek's `datetime_utc` carries no zone suffix; treat it as UTC and
/// hand back a local time like the Ticketmaster mapper does.
DateTime? _parseSeatGeekUtc(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final text = value.endsWith('Z') ? value : '${value}Z';
  return DateTime.tryParse(text)?.toLocal();
}

String _mapSeatGeekCategory(Map<String, dynamic> json) {
  final names = <String>{};
  final type = json['type'];
  if (type is String) names.add(type.toLowerCase());
  final taxonomies = json['taxonomies'];
  if (taxonomies is List) {
    for (final t in taxonomies) {
      if (t is Map && t['name'] is String) {
        names.add((t['name'] as String).toLowerCase());
      }
    }
  }
  bool has(String needle) => names.any((n) => n.contains(needle));
  if (has('sports') || has('baseball') || has('basketball') ||
      has('football') || has('hockey') || has('soccer') || has('mma') ||
      has('boxing') || has('wrestling') || has('racing') || has('golf')) {
    return 'Sports';
  }
  if (has('comedy')) return 'Fun & Games';
  if (has('dance')) return 'Dance';
  if (has('family') || has('circus')) return 'Family';
  if (has('film')) return 'Film';
  if (has('concert') || has('music')) return 'Music';
  if (has('theater') || has('broadway') || has('classical') ||
      has('opera') || has('literary')) {
    return 'Arts';
  }
  return 'Arts';
}

/// Best performer image, largest first. Null when SeatGeek has none.
String? _seatGeekImage(Map<String, dynamic> json) {
  final performers = json['performers'];
  if (performers is! List) return null;
  // Primary performer first, then anyone with art.
  final ordered = [
    ...performers.where((p) => p is Map && p['primary'] == true),
    ...performers.where((p) => p is Map && p['primary'] != true),
  ];
  for (final p in ordered) {
    if (p is! Map) continue;
    final images = p['images'];
    if (images is Map) {
      for (final key in const ['huge', 'large', 'medium', 'small']) {
        final url = images[key];
        if (url is String && url.isNotEmpty) return url;
      }
    }
    final single = p['image'];
    if (single is String && single.isNotEmpty) return single;
  }
  return null;
}

/// Maps one SeatGeek event document to an [Event]. Null when the document
/// lacks an id, a title, or a usable start time.
Event? eventFromSeatGeek(Map<String, dynamic> json) {
  final rawId = json['id'];
  final id = rawId is int ? rawId.toString() : (rawId is String ? rawId : '');
  final rawTitle = json['title'];
  final title = rawTitle is String ? rawTitle.trim() : '';
  if (id.isEmpty || title.isEmpty) return null;

  // SeatGeek marks unknown dates rather than omitting them; a date that is
  // only an estimate is not something the feed should promise.
  if (json['date_tbd'] == true) return null;
  final start = _parseSeatGeekUtc(json['datetime_utc']);
  if (start == null) return null;
  // A TBD time still has a real date; the sentinel time is 03:30 local,
  // which the mapper cannot improve on, so keep the date but say nothing
  // about an end.
  final timeTbd = json['time_tbd'] == true;

  String venueName = '';
  String address = '';
  String city = '';
  String state = '';
  String zip = '';
  double lat = 0;
  double lng = 0;
  final venue = json['venue'];
  if (venue is Map) {
    venueName = venue['name'] as String? ?? '';
    address = venue['address'] as String? ?? '';
    city = venue['city'] as String? ?? '';
    state = venue['state'] as String? ?? '';
    zip = venue['postal_code'] as String? ?? '';
    final loc = venue['location'];
    if (loc is Map) {
      lat = double.tryParse('${loc['lat']}') ?? 0;
      lng = double.tryParse('${loc['lon']}') ?? 0;
    }
  }

  var imageUrl = _seatGeekImage(json) ?? '';
  if (isGenericEventImage(imageUrl)) {
    final venuePhoto = venueImageFor(venueName, title: title);
    if (venuePhoto != null) imageUrl = venuePhoto;
  }

  // SeatGeek stopped populating `stats` prices in mid-2026; read them when
  // present but never invent a number.
  double? cost;
  final stats = json['stats'];
  if (stats is Map) {
    final lowest = stats['lowest_price'];
    if (lowest is num && lowest > 0) cost = lowest.toDouble();
  }

  final where = venueName.isEmpty ? city : venueName;
  final description = timeTbd
      ? '$title at $where. Start time to be announced. Tickets via SeatGeek.'
      : '$title at $where. Tickets via SeatGeek.';

  return Event(
    id: 'sg_$id',
    title: title,
    description: description,
    dateTime: start,
    location: venueName,
    address: address,
    city: city,
    state: state,
    zipCode: zip,
    cost: cost,
    // Every SeatGeek document is a ticketed listing.
    isTicketed: true,
    imageUrl: imageUrl,
    category: _mapSeatGeekCategory(json),
    organizerName: venueName.isEmpty ? 'SeatGeek' : venueName,
    organizerAvatarUrl:
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(venueName.isEmpty ? 'SG' : venueName)}&size=200&background=FF5B49&color=fff',
    latitude: lat,
    longitude: lng,
    source: EventSource.seatgeek,
    sourceUrl: json['url'] as String?,
  );
}
