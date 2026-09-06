import 'package:flutter/material.dart';

import '../data/event_time.dart';
import '../data/media_urls.dart';
import '../data/pricing.dart';
import 'event_social_link.dart';

enum EventSource {
  facebook,
  instagram,
  twitter,
  google,
  ticketmaster,
  local;

  String get displayName {
    switch (this) {
      case EventSource.facebook:
        return 'Facebook';
      case EventSource.instagram:
        return 'Instagram';
      case EventSource.twitter:
        return 'X (Twitter)';
      case EventSource.google:
        return 'Google';
      case EventSource.ticketmaster:
        return 'Ticketmaster';
      case EventSource.local:
        return 'Local';
    }
  }

  Color get brandColor {
    switch (this) {
      case EventSource.facebook:
        return const Color(0xFF1877F2);
      case EventSource.instagram:
        return const Color(0xFFE1306C);
      case EventSource.twitter:
        return const Color(0xFF14171A);
      case EventSource.google:
        return const Color(0xFF4285F4);
      case EventSource.ticketmaster:
        return const Color(0xFF026CDF);
      case EventSource.local:
        return const Color(0xFF6C5CE7);
    }
  }

  IconData get icon {
    switch (this) {
      case EventSource.facebook:
        return Icons.facebook_rounded;
      case EventSource.instagram:
        return Icons.camera_alt_rounded;
      case EventSource.twitter:
        return Icons.tag_rounded;
      case EventSource.google:
        return Icons.g_mobiledata_rounded;
      case EventSource.ticketmaster:
        return Icons.confirmation_number_rounded;
      case EventSource.local:
        return Icons.location_city_rounded;
    }
  }
}

class Event {
  final String id;
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
  /// True for listings that are known to be ticketed even when no price was
  /// published (e.g. Ticketmaster events without priceRanges). Prevents
  /// paid listings from showing a misleading "Free" badge.
  final bool isTicketed;
  final String imageUrl;
  /// Ordered event photo gallery. The cover [imageUrl] is also included for
  /// new events; [allImageUrls] deduplicates legacy and gallery data.
  final List<String> imageUrls;
  /// First video kept for backwards compatibility with older event documents.
  final String? videoUrl;
  /// Ordered event video gallery.
  final List<String> videoUrls;
  final String category;
  final String organizerName;
  final String organizerAvatarUrl;
  final int bookmarkedCount;
  final int interestedCount;
  final bool isBookmarked;
  final bool isInterested;
  final double latitude;
  final double longitude;
  final EventSource source;
  final String? sourceUrl;
  final bool isPremiumListing;
  final bool isCreatorPro;
  final String? featuredWeekKey;
  final bool isUserCreated;
  /// Public organizer profile links associated with this event.
  final EventSocialLinks socialLinks;

  const Event({
    required this.id,
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
    this.isTicketed = false,
    required this.imageUrl,
    this.imageUrls = const [],
    this.videoUrl,
    this.videoUrls = const [],
    required this.category,
    required this.organizerName,
    required this.organizerAvatarUrl,
    this.bookmarkedCount = 0,
    this.interestedCount = 0,
    this.isBookmarked = false,
    this.isInterested = false,
    this.latitude = 0,
    this.longitude = 0,
    this.source = EventSource.local,
    this.sourceUrl,
    this.isPremiumListing = false,
    this.isCreatorPro = false,
    this.featuredWeekKey,
    this.isUserCreated = false,
    this.socialLinks = const EventSocialLinks.empty(),
  });

  Event copyWith({
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
    bool? isTicketed,
    String? imageUrl,
    List<String>? imageUrls,
    String? videoUrl,
    bool clearVideoUrl = false,
    List<String>? videoUrls,
    String? category,
    int? bookmarkedCount,
    int? interestedCount,
    bool? isBookmarked,
    bool? isInterested,
    double? latitude,
    double? longitude,
    EventSource? source,
    String? sourceUrl,
    bool? isPremiumListing,
    bool? isCreatorPro,
    String? featuredWeekKey,
    bool? isUserCreated,
    EventSocialLinks? socialLinks,
  }) =>
      Event(
        id: id,
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
        cost: cost ?? this.cost,
        isTicketed: isTicketed ?? this.isTicketed,
        imageUrl: imageUrl ?? this.imageUrl,
        imageUrls: imageUrls ?? this.imageUrls,
        videoUrl: clearVideoUrl ? null : (videoUrl ?? this.videoUrl),
        videoUrls: videoUrls ?? this.videoUrls,
        category: category ?? this.category,
        organizerName: organizerName,
        organizerAvatarUrl: organizerAvatarUrl,
        bookmarkedCount: bookmarkedCount ?? this.bookmarkedCount,
        interestedCount: interestedCount ?? this.interestedCount,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        isInterested: isInterested ?? this.isInterested,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        source: source ?? this.source,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        isPremiumListing: isPremiumListing ?? this.isPremiumListing,
        isCreatorPro: isCreatorPro ?? this.isCreatorPro,
        featuredWeekKey: featuredWeekKey ?? this.featuredWeekKey,
        isUserCreated: isUserCreated ?? this.isUserCreated,
        socialLinks: socialLinks ?? this.socialLinks,
      );

  /// Ticketed listings (e.g. Ticketmaster) are never "free" just because the
  /// source did not publish a price range.
  bool get isFree => !isTicketed && (cost == null || cost == 0);

  /// True while the event has started and its explicit end time is still ahead.
  bool get isHappeningNow => isEventHappeningNow(dateTime, endDateTime);

  /// Whether the event belongs in the active discovery feed at [now].
  bool isVisibleAt({DateTime? now}) =>
      isEventVisibleInFeed(dateTime, endDateTime, now: now);

  /// Ticketed events without a published price show a neutral "Tickets"
  /// label instead of a misleading "Free" (or a crash on a null cost).
  String get costLabel {
    if (isFree) return 'Free';
    final c = cost;
    if (c == null) return 'Tickets';
    return '\$${c.toStringAsFixed(2)}';
  }

  /// Cover first, followed by up to four additional event photos.
  List<String> get allImageUrls => List.unmodifiable(
        normalizeMediaUrls([imageUrl, ...imageUrls]).take(kMaxEventPhotos),
      );

  /// First video first, followed by up to two additional event videos.
  List<String> get allVideoUrls => List.unmodifiable(
        normalizeMediaUrls([videoUrl, ...videoUrls]).take(kMaxEventVideos),
      );

  String get fullLocation => [location, city, state].where((s) => s.isNotEmpty).join(', ');

  /// True when this event holds the current week's "featured" slot.
  bool get isFeaturedThisWeek => isFeaturedInCurrentWeek(featuredWeekKey);

  /// True when the event page should show the in-feed promo — i.e. the
  /// listing owner hasn't paid for Premium (which removes ads).
  bool get showsAds => !isPremiumListing;
}
