import 'package:flutter/material.dart';

import '../data/gem_hours.dart';
import 'event_social_link.dart';

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
  bikeTrail,
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
        return 'Hiking trails';
      case GemCategory.bikeTrail:
        return 'Bike trails';
      case GemCategory.park:
        return 'Parks';
      case GemCategory.viewpoint:
        return 'Viewpoints';
      case GemCategory.water:
        return 'Community pools';
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
        return 'Restaurants & food';
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
      case GemCategory.bikeTrail:
        return Icons.pedal_bike_rounded;
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


enum GemListingKind { community, business }

GemListingKind gemListingKindFromName(String? name) =>
    name == 'business' ? GemListingKind.business : GemListingKind.community;

enum GemListingTier { basic, promoted }

GemListingTier gemListingTierFromName(String? name) =>
    name == 'promoted' ? GemListingTier.promoted : GemListingTier.basic;

/// Finer business-type filter than [GemCategory], used on the Gems tab.
enum GemBusinessType {
  restaurant,
  bar,
  cafe,
  hikingTrail,
  bikeTrail,
  pool,
  park,
  museum,
  shop,
  other;

  String get key => name;

  String get label {
    switch (this) {
      case GemBusinessType.restaurant:
        return 'Restaurant';
      case GemBusinessType.bar:
        return 'Bar';
      case GemBusinessType.cafe:
        return 'Cafe';
      case GemBusinessType.hikingTrail:
        return 'Hiking trail';
      case GemBusinessType.bikeTrail:
        return 'Bike trail';
      case GemBusinessType.pool:
        return 'Pool';
      case GemBusinessType.park:
        return 'Park';
      case GemBusinessType.museum:
        return 'Museum';
      case GemBusinessType.shop:
        return 'Shop';
      case GemBusinessType.other:
        return 'Other';
    }
  }

  static GemBusinessType? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final value in GemBusinessType.values) {
      if (value.name == key) return value;
    }
    return GemBusinessType.other;
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

  /// When the gem became publicly approved (usually [createdAt] unless a
  /// moderator later un-hid it). The early-access delay applies only to
  /// new business promo listings; casual shares are visible immediately.
  final DateTime? approvedAt;

  /// Server-computed instant when free users may see this gem.
  final DateTime? visibleToFreeAt;

  /// Community (casual share) or business (30-day promotional listing).
  final GemListingKind listingKind;
  /// End of the current Premium promotional window, set only by the server.
  final DateTime? richUntil;
  final DateTime? richActivatedAt;
  final String? contactPhone;
  final String? contactWebsite;
  final EventSocialLinks socialLinks;
  final String? promoTitle;
  final String? promoDetails;
  final DateTime? promoStartsAt;
  final DateTime? promoEndsAt;
  final GemBusinessType? businessType;
  final GemWeeklyHours hours;
  final String? offerTitle;
  final String? offerText;
  final DateTime? offerUntil;
  final bool hasOffer;
  final GemListingTier listingTier;
  final List<String> searchTokens;
  final List<String> geoCells;

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
    this.approvedAt,
    this.visibleToFreeAt,
    this.listingKind = GemListingKind.community,
    this.richUntil,
    this.richActivatedAt,
    this.contactPhone,
    this.contactWebsite,
    this.socialLinks = const EventSocialLinks.empty(),
    this.promoTitle,
    this.promoDetails,
    this.promoStartsAt,
    this.promoEndsAt,
    this.businessType,
    this.hours = GemWeeklyHours.empty,
    this.offerTitle,
    this.offerText,
    this.offerUntil,
    this.hasOffer = false,
    this.listingTier = GemListingTier.basic,
    this.searchTokens = const [],
    this.geoCells = const [],
  });

  /// Alias of [richUntil]; both are written by the server.
  DateTime? get promoUntil => richUntil;

  String get imageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  Gem copyWith({
    String? name,
    GemCategory? category,
    String? summary,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    bool? hidden,
    DateTime? approvedAt,
    DateTime? visibleToFreeAt,
    GemListingKind? listingKind,
    DateTime? richUntil,
    bool clearRichUntil = false,
    DateTime? richActivatedAt,
    String? contactPhone,
    bool clearContactPhone = false,
    String? contactWebsite,
    bool clearContactWebsite = false,
    EventSocialLinks? socialLinks,
    String? promoTitle,
    bool clearPromoTitle = false,
    String? promoDetails,
    bool clearPromoDetails = false,
    DateTime? promoStartsAt,
    bool clearPromoStartsAt = false,
    DateTime? promoEndsAt,
    bool clearPromoEndsAt = false,
    GemBusinessType? businessType,
    bool clearBusinessType = false,
    GemWeeklyHours? hours,
    String? offerTitle,
    bool clearOfferTitle = false,
    String? offerText,
    bool clearOfferText = false,
    DateTime? offerUntil,
    bool clearOfferUntil = false,
    bool? hasOffer,
    GemListingTier? listingTier,
    List<String>? searchTokens,
    List<String>? geoCells,
  }) {
    return Gem(
      id: id,
      creatorId: creatorId,
      creatorName: creatorName,
      name: name ?? this.name,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      hidden: hidden ?? this.hidden,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      visibleToFreeAt: visibleToFreeAt ?? this.visibleToFreeAt,
      listingKind: listingKind ?? this.listingKind,
      richUntil: clearRichUntil ? null : (richUntil ?? this.richUntil),
      richActivatedAt: richActivatedAt ?? this.richActivatedAt,
      contactPhone: clearContactPhone ? null : (contactPhone ?? this.contactPhone),
      contactWebsite: clearContactWebsite ? null : (contactWebsite ?? this.contactWebsite),
      socialLinks: socialLinks ?? this.socialLinks,
      promoTitle: clearPromoTitle ? null : (promoTitle ?? this.promoTitle),
      promoDetails: clearPromoDetails ? null : (promoDetails ?? this.promoDetails),
      promoStartsAt: clearPromoStartsAt ? null : (promoStartsAt ?? this.promoStartsAt),
      promoEndsAt: clearPromoEndsAt ? null : (promoEndsAt ?? this.promoEndsAt),
      businessType: clearBusinessType ? null : (businessType ?? this.businessType),
      hours: hours ?? this.hours,
      offerTitle: clearOfferTitle ? null : (offerTitle ?? this.offerTitle),
      offerText: clearOfferText ? null : (offerText ?? this.offerText),
      offerUntil: clearOfferUntil ? null : (offerUntil ?? this.offerUntil),
      hasOffer: hasOffer ?? this.hasOffer,
      listingTier: listingTier ?? this.listingTier,
      searchTokens: searchTokens ?? this.searchTokens,
      geoCells: geoCells ?? this.geoCells,
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
