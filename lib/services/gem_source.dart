import 'dart:async';
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
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 25),
              sendTimeout: const Duration(seconds: 8),
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
    final radiusMeters = (radiusMiles * 1609.34).round().clamp(1000, 80000);
    final key =
        '${lat.toStringAsFixed(2)}:${lng.toStringAsFixed(2)}:$radiusMeters';
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expires)) {
      return cached.gems.take(limit).toList();
    }

    final query = _buildQuery(lat, lng, radiusMeters);
    for (final endpoint in _endpoints) {
      try {
        final res = await _dio.post<dynamic>(
          endpoint,
          data: {'data': query},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.json,
          ),
        );
        final data = res.data;
        if (data is! Map || data['elements'] is! List) continue;
        final gems = _parse(
          (data['elements'] as List).cast<dynamic>(),
          originLat: lat,
          originLng: lng,
        );
        if (gems.isEmpty) {
          // A valid-but-empty answer is still authoritative; cache briefly.
          _cache[key] = _CacheEntry(gems, DateTime.now().add(_cacheTtl));
          return const [];
        }
        _cache[key] = _CacheEntry(gems, DateTime.now().add(_cacheTtl));
        return gems.take(limit).toList();
      } catch (error) {
        debugPrint(
          'Overpass mirror failed ($endpoint): ${error.runtimeType}; trying next.',
        );
        // Try the next mirror.
      }
    }
    return const [];
  }

  /// Build a compact Overpass QL query covering the broad "interesting places"
  /// set the product cares about. `[out:json]` + `out center` gives a single
  /// representative coordinate for ways/relations too.
  String _buildQuery(double lat, double lng, int radiusMeters) {
    final around = 'around:$radiusMeters,$lat,$lng';
    // Each line is a targeted tag filter. Kept tight so the payload stays small
    // and relevant (no benches, bins, or generic amenities).
    final filters = <String>[
      // Trails & hiking
      'way["highway"="path"]["name"]($around);',
      'relation["route"="hiking"]["name"]($around);',
      // Parks, gardens, nature & recreation
      'node["leisure"="park"]["name"]($around);',
      'way["leisure"="park"]["name"]($around);',
      'way["leisure"="garden"]["name"]($around);',
      'way["leisure"="nature_reserve"]["name"]($around);',
      'node["leisure"="nature_reserve"]["name"]($around);',
      'way["boundary"="protected_area"]["name"]($around);',
      // Viewpoints & natural features
      'node["tourism"="viewpoint"]["name"]($around);',
      'node["natural"="peak"]["name"]($around);',
      'node["natural"="waterfall"]["name"]($around);',
      // Pools & swimming
      'node["leisure"="swimming_pool"]["name"]($around);',
      'way["leisure"="swimming_pool"]["name"]($around);',
      'node["leisure"="water_park"]["name"]($around);',
      'way["leisure"="water_park"]["name"]($around);',
      // Museums, galleries, art
      'node["tourism"="museum"]["name"]($around);',
      'way["tourism"="museum"]["name"]($around);',
      'node["tourism"="gallery"]["name"]($around);',
      'node["tourism"="artwork"]["name"]($around);',
      'node["historic"="memorial"]["name"]($around);',
      // Historic sites & landmarks
      'node["historic"="monument"]["name"]($around);',
      'way["historic"="monument"]["name"]($around);',
      'node["historic"="ruins"]["name"]($around);',
      'way["historic"]["name"]["historic"!="memorial"]($around);',
      // Attractions
      'node["tourism"="attraction"]["name"]($around);',
      'way["tourism"="attraction"]["name"]($around);',
      'node["tourism"="theme_park"]["name"]($around);',
      'node["tourism"="zoo"]["name"]($around);',
      'node["tourism"="aquarium"]["name"]($around);',
    ];
    return '[out:json][timeout:25];(${filters.join()});out center 300;';
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
