import 'package:flutter/foundation.dart';

/// How often a Creator Pro event auto-repeats.
enum RecurringType { none, weekly, monthly }

@immutable
class UserCreatedEvent {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? cost;
  final String imageUrl;
  final String? videoUrl;
  final String category;
  final String organizerName;
  final String? mapLink;
  final String? chatLink;
  final bool isPremiumListing;
  final int interestedCount;
  final DateTime createdAt;

  // ── Creator Pro fields ──────────────────────────────────────────────────────
  /// Whether this event was created by a Creator Pro subscriber.
  final bool isCreatorPro;
  /// Recurring schedule — none, weekly, or monthly.
  final RecurringType recurringType;
  /// Optional phone number shown on event page (Creator Pro only).
  final String? contactPhone;
  /// Optional website URL shown on event page (Creator Pro only).
  final String? contactWebsite;
  /// Optional social handle/link shown on event page (Creator Pro only).
  final String? contactSocial;
  /// Hex color string for custom brand accent, e.g. '#FF5733' (Creator Pro only).
  final String? brandColor;
  /// URL for custom brand logo shown on event page (Creator Pro only).
  final String? brandLogoUrl;
  /// Simulated search impressions count — how many times the event appeared in a search this week.
  final int analyticsSearchImpressions;
  /// Simulated view count for the analytics dashboard.
  final int analyticsViews;
  /// Simulated save count for the analytics dashboard.
  final int analyticsSaves;
  /// Simulated click-through count for the analytics dashboard.
  final int analyticsClicks;

  const UserCreatedEvent({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.address,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.cost,
    this.imageUrl = '',
    this.videoUrl,
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
    this.analyticsSearchImpressions = 0,
    this.analyticsViews = 0,
    this.analyticsSaves = 0,
    this.analyticsClicks = 0,
  });

  bool get isFree => cost == null || cost == 0;
  String get costLabel => isFree ? 'Free' : '\$${cost!.toStringAsFixed(2)}';
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
    String? location,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? cost,
    bool clearCost = false,
    String? imageUrl,
    String? videoUrl,
    bool clearVideoUrl = false,
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
    int? analyticsSearchImpressions,
    int? analyticsViews,
    int? analyticsSaves,
    int? analyticsClicks,
  }) =>
      UserCreatedEvent(
        id: id,
        creatorId: creatorId,
        title: title ?? this.title,
        description: description ?? this.description,
        dateTime: dateTime ?? this.dateTime,
        location: location ?? this.location,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        zipCode: zipCode ?? this.zipCode,
        cost: clearCost ? null : (cost ?? this.cost),
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: clearVideoUrl ? null : (videoUrl ?? this.videoUrl),
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
        analyticsSearchImpressions: analyticsSearchImpressions ?? this.analyticsSearchImpressions,
        analyticsViews: analyticsViews ?? this.analyticsViews,
        analyticsSaves: analyticsSaves ?? this.analyticsSaves,
        analyticsClicks: analyticsClicks ?? this.analyticsClicks,
      );
}
