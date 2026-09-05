import 'package:flutter/foundation.dart';

import '../data/event_time.dart';
import '../data/media_urls.dart';
import 'event_social_link.dart';

/// How often a Premium event auto-repeats.
enum RecurringType { none, weekly, monthly }

@immutable
class UserCreatedEvent {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  /// Event start date and time.
  final DateTime dateTime;
  /// Explicit event end time. Legacy event documents can omit this value.
  final DateTime? endDateTime;
  final String location;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? cost;
  final String imageUrl;
  /// Ordered photo gallery. The cover [imageUrl] remains for legacy readers.
  final List<String> imageUrls;
  final String? videoUrl;
  /// Ordered video gallery. The first entry is mirrored in [videoUrl].
  final List<String> videoUrls;
  final String category;
  final String organizerName;
  final String? mapLink;
  final String? chatLink;
  final bool isPremiumListing;
  final int interestedCount;
  final DateTime createdAt;

  // ── Premium fields (`isCreatorPro` kept for stored documents) ──────────────
  /// Whether this event was created by a Premium subscriber.
  final bool isCreatorPro;
  /// Recurring schedule — none, weekly, or monthly.
  final RecurringType recurringType;
  /// Optional phone number shown on event page (Premium only).
  final String? contactPhone;
  /// Optional website URL shown on event page (Premium only).
  final String? contactWebsite;
  /// Legacy generic social handle/link shown with Premium contact details.
  final String? contactSocial;
  /// Hex color string for custom brand accent, e.g. '#FF5733' (Premium only).
  final String? brandColor;
  /// URL for custom brand logo shown on event page (Premium only).
  final String? brandLogoUrl;
  /// ISO week this event is featured in the category feed, e.g. `2026-W33`.
  final String? featuredWeekKey;
  /// Live search impressions — times the event appeared in a feed or search.
  final int analyticsSearchImpressions;
  /// Live view count for the analytics dashboard.
  final int analyticsViews;
  /// Live save count for the analytics dashboard.
  final int analyticsSaves;
  /// Live click-through count for the analytics dashboard.
  final int analyticsClicks;
  /// Public organizer profile links shown on this event page.
  final EventSocialLinks socialLinks;

  const UserCreatedEvent({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.dateTime,
    this.endDateTime,
    required this.location,
    required this.address,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.cost,
    this.imageUrl = '',
    this.imageUrls = const [],
    this.videoUrl,
    this.videoUrls = const [],
    required this.category,
    required this.organizerName,
    this.mapLink,
    this.chatLink,
    this.isPremiumListing = false,
    this.interestedCount = 0,
    required this.createdAt,
    this.isCreatorPro = false,
    this.recurringType = RecurringType.none,
    this.contactPhone,
    this.contactWebsite,
    this.contactSocial,
    this.brandColor,
    this.brandLogoUrl,
    this.featuredWeekKey,
    this.analyticsSearchImpressions = 0,
    this.analyticsViews = 0,
    this.analyticsSaves = 0,
    this.analyticsClicks = 0,
    this.socialLinks = const EventSocialLinks.empty(),
  });

  bool get isFree => cost == null || cost == 0;
  /// True while the event has started and its explicit end time is still ahead.
  bool get isHappeningNow => isEventHappeningNow(dateTime, endDateTime);
  /// Whether the event belongs in an active feed at [now].
  bool isVisibleAt({DateTime? now}) =>
      isEventVisibleInFeed(dateTime, endDateTime, now: now);
  String get costLabel => isFree ? 'Free' : '\$${cost!.toStringAsFixed(2)}';
  List<String> get allImageUrls => List.unmodifiable(
        normalizeMediaUrls([imageUrl, ...imageUrls]).take(kMaxEventPhotos),
      );
  List<String> get allVideoUrls => List.unmodifiable(
        normalizeMediaUrls([videoUrl, ...videoUrls]).take(kMaxEventVideos),
      );
  String get fullLocation => [location, city, state].where((s) => s.isNotEmpty).join(', ');
  bool get hasContactInfo =>
      (contactPhone?.isNotEmpty ?? false) ||
      (contactWebsite?.isNotEmpty ?? false) ||
      (contactSocial?.isNotEmpty ?? false);
  bool get isRecurring => recurringType != RecurringType.none;
  String get recurringLabel {
    switch (recurringType) {
      case RecurringType.weekly:
        return 'Weekly';
      case RecurringType.monthly:
        return 'Monthly';
      case RecurringType.none:
        return '';
    }
  }

  UserCreatedEvent copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? endDateTime,
    bool clearEndDateTime = false,
    String? location,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? cost,
    bool clearCost = false,
    String? imageUrl,
    List<String>? imageUrls,
    String? videoUrl,
    bool clearVideoUrl = false,
    List<String>? videoUrls,
    String? category,
    String? organizerName,
    String? mapLink,
    bool clearMapLink = false,
    String? chatLink,
    bool clearChatLink = false,
    bool? isPremiumListing,
    int? interestedCount,
    bool? isCreatorPro,
    RecurringType? recurringType,
    String? contactPhone,
    bool clearContactPhone = false,
    String? contactWebsite,
    bool clearContactWebsite = false,
    String? contactSocial,
    bool clearContactSocial = false,
    String? brandColor,
    bool clearBrandColor = false,
    String? brandLogoUrl,
    bool clearBrandLogoUrl = false,
    String? featuredWeekKey,
    bool clearFeaturedWeekKey = false,
    int? analyticsSearchImpressions,
    int? analyticsViews,
    int? analyticsSaves,
    int? analyticsClicks,
    EventSocialLinks? socialLinks,
  }) =>
      UserCreatedEvent(
        id: id,
        creatorId: creatorId,
        title: title ?? this.title,
        description: description ?? this.description,
        dateTime: dateTime ?? this.dateTime,
        endDateTime:
            clearEndDateTime ? null : (endDateTime ?? this.endDateTime),
        location: location ?? this.location,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        zipCode: zipCode ?? this.zipCode,
        cost: clearCost ? null : (cost ?? this.cost),
        imageUrl: imageUrl ?? this.imageUrl,
        imageUrls: imageUrls ?? this.imageUrls,
        videoUrl: clearVideoUrl ? null : (videoUrl ?? this.videoUrl),
        videoUrls: videoUrls ?? this.videoUrls,
        category: category ?? this.category,
        organizerName: organizerName ?? this.organizerName,
        mapLink: clearMapLink ? null : (mapLink ?? this.mapLink),
        chatLink: clearChatLink ? null : (chatLink ?? this.chatLink),
        isPremiumListing: isPremiumListing ?? this.isPremiumListing,
        interestedCount: interestedCount ?? this.interestedCount,
        createdAt: createdAt,
        isCreatorPro: isCreatorPro ?? this.isCreatorPro,
        recurringType: recurringType ?? this.recurringType,
        contactPhone: clearContactPhone ? null : (contactPhone ?? this.contactPhone),
        contactWebsite: clearContactWebsite ? null : (contactWebsite ?? this.contactWebsite),
        contactSocial: clearContactSocial ? null : (contactSocial ?? this.contactSocial),
        brandColor: clearBrandColor ? null : (brandColor ?? this.brandColor),
        brandLogoUrl: clearBrandLogoUrl ? null : (brandLogoUrl ?? this.brandLogoUrl),
        featuredWeekKey: clearFeaturedWeekKey
            ? null
            : (featuredWeekKey ?? this.featuredWeekKey),
        analyticsSearchImpressions: analyticsSearchImpressions ?? this.analyticsSearchImpressions,
        analyticsViews: analyticsViews ?? this.analyticsViews,
        analyticsSaves: analyticsSaves ?? this.analyticsSaves,
        analyticsClicks: analyticsClicks ?? this.analyticsClicks,
        socialLinks: socialLinks ?? this.socialLinks,
      );
}
