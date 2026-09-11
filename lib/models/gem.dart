import 'package:flutter/material.dart';

/// A "hidden gem" — an overlooked local *place* worth discovering, as opposed
/// to an [Event] which is something happening at a time. Gems are sourced
/// nationally (any city) from OpenStreetMap via the Overpass API, so the app
/// needs zero per-city curation: a search resolves to coordinates and gems are
/// fetched for that area on the fly.
///
/// Gems are first-party discovery content, not licensed event listings, so they
/// live in a parallel pipeline from [LiveEventSource]; nothing here touches the
/// Ticketmaster / JamBase / SeatGeek quota logic.
enum GemCategory {
  trail,
  park,
  viewpoint,
  water,
  nature,
  museum,
  art,
  historic,
  landmark,
  attraction;

  /// Broad display label shown on chips and cards.
  String get label {
    switch (this) {
      case GemCategory.trail:
        return 'Trails';
      case GemCategory.park:
        return 'Parks';
      case GemCategory.viewpoint:
        return 'Viewpoints';
      case GemCategory.water:
        return 'Pools & Water';
      case GemCategory.nature:
        return 'Nature';
      case GemCategory.museum:
        return 'Museums';
      case GemCategory.art:
        return 'Art & Murals';
      case GemCategory.historic:
        return 'Historic';
      case GemCategory.landmark:
        return 'Landmarks';
      case GemCategory.attraction:
        return 'Attractions';
    }
  }

  IconData get icon {
    switch (this) {
      case GemCategory.trail:
        return Icons.hiking_rounded;
      case GemCategory.park:
        return Icons.park_rounded;
      case GemCategory.viewpoint:
        return Icons.landscape_rounded;
      case GemCategory.water:
        return Icons.pool_rounded;
      case GemCategory.nature:
        return Icons.forest_rounded;
      case GemCategory.museum:
        return Icons.museum_rounded;
      case GemCategory.art:
        return Icons.palette_rounded;
      case GemCategory.historic:
        return Icons.account_balance_rounded;
      case GemCategory.landmark:
        return Icons.location_city_rounded;
      case GemCategory.attraction:
        return Icons.attractions_rounded;
    }
  }
}

@immutable
class Gem {
  /// Prefixed, stable id (e.g. `osm_node_12345`) so gems never collide with
  /// event ids and cold-start deep links can round-trip.
  final String id;
  final String name;
  final GemCategory category;
  final double latitude;
  final double longitude;

  /// One-line "why it's a gem" blurb, derived from tags when OSM has no
  /// description of its own.
  final String summary;

  /// Longer free-text description when the source provides one.
  final String? description;

  /// Best-effort human address / locality (may be just a city).
  final String address;
  final String? city;
  final String? state;

  /// Optional outbound links surfaced on the detail page.
  final String? website;
  final String? phone;
  final String? imageUrl;

  /// Raw OSM tag hints kept for richer detail rendering (opening hours,
  /// fees, wheelchair access, etc.). Always safe to be empty.
  final Map<String, String> details;

  const Gem({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.summary,
    required this.address,
    this.description,
    this.city,
    this.state,
    this.website,
    this.phone,
    this.imageUrl,
    this.details = const {},
  });

  Gem copyWith({
    String? summary,
    String? address,
    String? city,
    String? state,
  }) {
    return Gem(
      id: id,
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      summary: summary ?? this.summary,
      description: description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      website: website,
      phone: phone,
      imageUrl: imageUrl,
      details: details,
    );
  }
}
