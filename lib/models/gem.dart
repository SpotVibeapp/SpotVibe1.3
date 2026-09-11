import 'package:flutter/material.dart';

/// A user-submitted "hidden gem" — an overlooked local *place* worth
/// discovering (a mountain trail, a quiet neighborhood pool, a park, a mural,
/// a viewpoint, a small museum, and so on).
///
/// Gems are community content, free for everyone to submit, browse, like, and
/// comment on. They are moderated the same way user events are: a client-side
/// check blocks obvious violations before write, and a Cloud Function hides
/// anything matching the banned-word list after write (`hidden = true`).
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
  foodDrink,
  attraction,
  other;

  /// Stable string stored in Firestore (never localize the stored value).
  String get key => name;

  static GemCategory fromKey(String? key) {
    return GemCategory.values.firstWhere(
      (c) => c.name == key,
      orElse: () => GemCategory.other,
    );
  }

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
      case GemCategory.foodDrink:
        return 'Food & Drink';
      case GemCategory.attraction:
        return 'Attractions';
      case GemCategory.other:
        return 'Other';
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
      case GemCategory.foodDrink:
        return Icons.restaurant_rounded;
      case GemCategory.attraction:
        return Icons.attractions_rounded;
      case GemCategory.other:
        return Icons.place_rounded;
    }
  }
}

@immutable
class Gem {
  final String id;
  final String creatorId;
  final String creatorName;

  final String name;
  final GemCategory category;

  /// One-line "why it's a gem" hook shown on the card.
  final String summary;

  /// Longer description shown on the detail page.
  final String description;

  final double latitude;
  final double longitude;

  /// Free-text location the submitter typed (e.g. "McKelligon Canyon, El Paso").
  final String address;
  final String city;
  final String state;

  /// Ordered photo gallery; first entry is the cover. Empty → branded cover.
  final List<String> imageUrls;

  final int likeCount;
  final int commentCount;

  /// Whether the current viewer has liked this gem (set client-side).
  final bool likedByMe;

  /// Moderation: hidden gems are excluded from public browsing.
  final bool hidden;

  final DateTime createdAt;

  const Gem({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.name,
    required this.category,
    required this.summary,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city = '',
    this.state = '',
    this.imageUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.hidden = false,
    required this.createdAt,
  });

  String get imageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  Gem copyWith({
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    bool? hidden,
  }) {
    return Gem(
      id: id,
      creatorId: creatorId,
      creatorName: creatorName,
      name: name,
      category: category,
      summary: summary,
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      state: state,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      hidden: hidden ?? this.hidden,
      createdAt: createdAt,
    );
  }
}

/// A comment on a gem. Mirrors the events/{id}/comments moderation model.
@immutable
class GemComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String text;
  final bool hidden;
  final DateTime createdAt;

  const GemComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.text,
    this.hidden = false,
    required this.createdAt,
  });
}
