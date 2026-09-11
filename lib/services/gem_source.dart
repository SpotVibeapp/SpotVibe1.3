import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/gem.dart';

/// Fetches "hidden gems" — overlooked local places — for any city on demand.
///
/// Backed by OpenStreetMap through the free, keyless **Overpass API**, so the
/// feature scales nationally with zero per-city curation: give it a point and a
/// radius and it returns parks, trails, viewpoints, pools, museums, murals,
/// historic sites and quirky attractions near there.
///
/// Design mirrors [LiveEventSource]: it NEVER throws. Network failure, a slow
/// mirror, or a garbage response degrades to an empty list so the Gems screen
/// shows a friendly empty state instead of crashing.
///
/// Attribution: results are "© OpenStreetMap contributors" (ODbL). The Gems UI
/// must surface that credit.
class GemSource {
  GemSource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 10),
              // Accept any status so we can read error bodies instead of the
              // client throwing before we can log what went wrong.
              validateStatus: (_) => true,
              headers: const {
                'User-Agent':
                    'SpotVibe/1.0 (https://spotvibe.app; hello@spotvibeapp.com)',
              },
            ));

  final Dio _dio;

  /// Public Overpass mirrors, tried in order until one answers. Keyless.
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  /// Short in-memory cache so re-opening / re-filtering the Gems tab for the
  /// same area doesn't re-hit Overpass. Keyed by rounded lat/lng/radius.
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 30);

  /// Fetch gems near [lat]/[lng] within [radiusMiles]. Returns `[]` on any
  /// failure. [limit] caps how many are returned after ranking.
  Future<List<Gem>> nearby({
    required double lat,
    required double lng,
    double radiusMiles = 25,
    int limit = 80,
  }) async {
    // Cap the radius: a huge `around` makes free Overpass mirrors time out.
    final radiusMeters = (radiusMiles * 1609.34).round().clamp(1000, 40000);
    final key =
        '${lat.toStringAsFixed(2)}:${lng.toStringAsFixed(2)}:$radiusMeters';
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expires)) {
      return cached.gems.take(limit).toList();
    }

    final query = _buildQuery(lat, lng, radiusMeters);

    for (final endpoint in _endpoints) {
      final elements = await _requestElements(endpoint, query);
      if (elements == null) continue; // this mirror failed; try the next
      final gems = _parse(elements, originLat: lat, originLng: lng);
      _cache[key] = _CacheEntry(gems, DateTime.now().add(_cacheTtl));
      return gems.take(limit).toList();
    }
    return const [];
  }

  /// Query one mirror. Returns the parsed `elements` list, or null when this
  /// mirror should be skipped (network error, non-200, or unparseable body).
  /// Tries POST first, then a GET fallback which some mirrors accept when a
  /// POST is blocked by a proxy.
  Future<List<dynamic>?> _requestElements(
      String endpoint, String query) async {
    for (final usePost in [true, false]) {
      try {
        final Response<dynamic> res;
        if (usePost) {
          res = await _dio.post<dynamic>(
            endpoint,
            data: 'data=${Uri.encodeQueryComponent(query)}',
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              responseType: ResponseType.plain,
            ),
          );
        } else {
          res = await _dio.get<dynamic>(
            endpoint,
            queryParameters: {'data': query},
            options: Options(responseType: ResponseType.plain),
          );
        }

        final status = res.statusCode ?? 0;
        if (status != 200) {
          debugPrint(
            'Overpass ${usePost ? 'POST' : 'GET'} $endpoint -> HTTP $status '
            '${_snippet(res.data)}',
          );
          continue; // try GET, or next mirror
        }

        final body = res.data;
        final Map<String, dynamic> json;
        if (body is String) {
          json = jsonDecode(body) as Map<String, dynamic>;
        } else if (body is Map) {
          json = body.cast<String, dynamic>();
        } else {
          continue;
        }
        final elements = json['elements'];
        if (elements is List) return elements;
      } on DioException catch (e) {
        debugPrint(
          'Overpass ${usePost ? 'POST' : 'GET'} $endpoint failed: '
          '${e.type} ${e.message ?? ''} '
          '${e.response?.statusCode ?? ''}',
        );
      } catch (e) {
        debugPrint('Overpass $endpoint parse error: ${e.runtimeType}');
      }
    }
    return null;
  }

  String _snippet(dynamic data) {
    final s = data?.toString() ?? '';
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  /// Build a compact Overpass QL query covering the broad "interesting places"
  /// set the product cares about. Uses `nwr` + regex so the whole thing is a
  /// handful of statements (light enough for the free mirrors). `out center`
  /// gives a single representative coordinate for ways/relations too.
  String _buildQuery(double lat, double lng, int radiusMeters) {
    final around = 'around:$radiusMeters,$lat,$lng';
    final filters = <String>[
      // Parks, gardens, nature reserves, water parks, pools.
      'nwr["leisure"~"^(park|garden|nature_reserve|water_park|swimming_pool)\$"]["name"]($around);',
      // Protected natural areas.
      'nwr["boundary"="protected_area"]["name"]($around);',
      // Tourism: viewpoints, museums, galleries, artwork, attractions, zoos…
      'nwr["tourism"~"^(viewpoint|museum|gallery|artwork|attraction|theme_park|zoo|aquarium)\$"]["name"]($around);',
      // Natural landmarks.
      'nwr["natural"~"^(peak|waterfall)\$"]["name"]($around);',
      // Historic sites.
      'nwr["historic"]["name"]($around);',
      // Named hiking trails and routes.
      'way["highway"="path"]["name"]($around);',
      'relation["route"="hiking"]["name"]($around);',
    ];
    return '[out:json][timeout:25];(${filters.join()});out center 250;';
  }

  List<Gem> _parse(
    List<dynamic> elements, {
    required double originLat,
    required double originLng,
  }) {
    final seenNames = <String>{};
    final gems = <_ScoredGem>[];

    for (final raw in elements) {
      if (raw is! Map) continue;
      final tags = (raw['tags'] as Map?)?.cast<String, dynamic>();
      if (tags == null) continue;
      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      // Coordinates: nodes carry lat/lon directly; ways/relations use `center`.
      double? lat = (raw['lat'] as num?)?.toDouble();
      double? lng = (raw['lon'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        final center = (raw['center'] as Map?)?.cast<String, dynamic>();
        lat = (center?['lat'] as num?)?.toDouble();
        lng = (center?['lon'] as num?)?.toDouble();
      }
      if (lat == null || lng == null) continue;

      final category = _classify(tags);
      if (category == null) continue;

      // De-dupe by lowercased name (parks often appear as node + way).
      final dedupeKey = name.toLowerCase();
      if (!seenNames.add(dedupeKey)) continue;

      final type = (raw['type'] as String?) ?? 'node';
      final osmId = raw['id']?.toString() ?? '${lat}_$lng';
      final distance =
          _haversineMiles(originLat, originLng, lat, lng);

      gems.add(
        _ScoredGem(
          gem: Gem(
            id: 'osm_${type}_$osmId',
            name: name,
            category: category,
            latitude: lat,
            longitude: lng,
            summary: _summaryFor(category, tags),
            description: (tags['description'] as String?)?.trim(),
            address: _addressFor(tags),
            city: (tags['addr:city'] as String?)?.trim(),
            state: (tags['addr:state'] as String?)?.trim(),
            website: _firstNonEmpty([
              tags['website'] as String?,
              tags['contact:website'] as String?,
              tags['url'] as String?,
            ]),
            phone: _firstNonEmpty([
              tags['phone'] as String?,
              tags['contact:phone'] as String?,
            ]),
            imageUrl: _imageFor(tags),
            details: _detailTags(tags),
          ),
          distanceMiles: distance,
        ),
      );
    }

    // Nearer places first — "hidden gems near you" should feel local.
    gems.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
    return gems.map((s) => s.gem).toList();
  }

  GemCategory? _classify(Map<String, dynamic> tags) {
    final leisure = tags['leisure'] as String?;
    final tourism = tags['tourism'] as String?;
    final historic = tags['historic'] as String?;
    final natural = tags['natural'] as String?;
    final highway = tags['highway'] as String?;
    final route = tags['route'] as String?;
    final boundary = tags['boundary'] as String?;

    if (highway == 'path' || route == 'hiking') return GemCategory.trail;
    if (leisure == 'swimming_pool' || leisure == 'water_park') {
      return GemCategory.water;
    }
    if (natural == 'waterfall') return GemCategory.water;
    if (leisure == 'park' || leisure == 'garden') return GemCategory.park;
    if (leisure == 'nature_reserve' || boundary == 'protected_area') {
      return GemCategory.nature;
    }
    if (tourism == 'viewpoint' || natural == 'peak') {
      return GemCategory.viewpoint;
    }
    if (tourism == 'museum') return GemCategory.museum;
    if (tourism == 'gallery' || tourism == 'artwork') return GemCategory.art;
    if (historic == 'memorial' || historic == 'monument' ||
        historic == 'ruins' || historic != null) {
      return GemCategory.historic;
    }
    if (tourism == 'theme_park' ||
        tourism == 'zoo' ||
        tourism == 'aquarium' ||
        tourism == 'attraction') {
      return GemCategory.attraction;
    }
    if (tourism != null) return GemCategory.landmark;
    return null;
  }

  String _summaryFor(GemCategory category, Map<String, dynamic> tags) {
    final desc = (tags['description'] as String?)?.trim();
    if (desc != null && desc.isNotEmpty) return desc;

    switch (category) {
      case GemCategory.trail:
        final len = tags['distance'] as String?;
        return len != null
            ? 'Hiking trail · $len'
            : 'A local hiking trail worth exploring.';
      case GemCategory.park:
        return 'A local park to relax, walk, or gather.';
      case GemCategory.viewpoint:
        return 'A scenic viewpoint with a view worth the trip.';
      case GemCategory.water:
        final fee = tags['fee'] as String?;
        return fee == 'no'
            ? 'A swimming spot — free to use.'
            : 'A local swimming spot.';
      case GemCategory.nature:
        return 'A protected natural area to explore outdoors.';
      case GemCategory.museum:
        return 'A local museum you may have overlooked.';
      case GemCategory.art:
        return 'Local art worth a closer look.';
      case GemCategory.historic:
        return 'A piece of local history.';
      case GemCategory.landmark:
        return 'A notable local landmark.';
      case GemCategory.attraction:
        return 'A local attraction worth a visit.';
    }
  }

  String _addressFor(Map<String, dynamic> tags) {
    final parts = <String>[
      if ((tags['addr:housenumber'] as String?)?.isNotEmpty ?? false)
        '${tags['addr:housenumber']} ${tags['addr:street'] ?? ''}'.trim()
      else if ((tags['addr:street'] as String?)?.isNotEmpty ?? false)
        tags['addr:street'] as String,
      if ((tags['addr:city'] as String?)?.isNotEmpty ?? false)
        tags['addr:city'] as String,
      if ((tags['addr:state'] as String?)?.isNotEmpty ?? false)
        tags['addr:state'] as String,
    ];
    return parts.where((p) => p.trim().isNotEmpty).join(', ');
  }

  String? _imageFor(Map<String, dynamic> tags) {
    final image = (tags['image'] as String?)?.trim();
    if (image != null && image.startsWith('http')) return image;
    // Wikimedia Commons filename → we don't resolve it here (can hang); the
    // branded gem cover handles the no-image case cleanly.
    return null;
  }

  Map<String, String> _detailTags(Map<String, dynamic> tags) {
    final keep = <String, String>{};
    void add(String key, String label) {
      final v = (tags[key] as String?)?.trim();
      if (v != null && v.isNotEmpty) keep[label] = v;
    }

    add('opening_hours', 'Hours');
    add('fee', 'Fee');
    add('wheelchair', 'Wheelchair access');
    add('operator', 'Operated by');
    add('surface', 'Surface');
    add('distance', 'Distance');
    return keep;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final trimmed = v?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  double _haversineMiles(
      double lat1, double lng1, double lat2, double lng2) {
    const earthMiles = 3958.8;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthMiles * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class _ScoredGem {
  final Gem gem;
  final double distanceMiles;
  const _ScoredGem({required this.gem, required this.distanceMiles});
}

class _CacheEntry {
  final List<Gem> gems;
  final DateTime expires;
  const _CacheEntry(this.gems, this.expires);
}
