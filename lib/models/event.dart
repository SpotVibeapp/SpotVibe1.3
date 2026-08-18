import 'package:flutter/material.dart';

import '../data/pricing.dart';

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
  final DateTime dateTime;
  final String location;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? cost;
  final String imageUrl;
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

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.address,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.cost,
    required this.imageUrl,
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
  });

  Event copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? cost,
    String? imageUrl,
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
  }) =>
      Event(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dateTime: dateTime ?? this.dateTime,
        location: location ?? this.location,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        zipCode: zipCode ?? this.zipCode,
        cost: cost ?? this.cost,
        imageUrl: imageUrl ?? this.imageUrl,
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
      );

  bool get isFree => cost == null || cost == 0;

  String get costLabel => isFree ? 'Free' : '\$${cost!.toStringAsFixed(2)}';

  String get fullLocation => [location, city, state].where((s) => s.isNotEmpty).join(', ');

  /// True when this event holds the current week's "featured" slot.
  bool get isFeaturedThisWeek => isFeaturedInCurrentWeek(featuredWeekKey);

  /// True when the event page should show the in-feed promo — i.e. the
  /// listing owner hasn't paid for Premium (which removes ads).
  bool get showsAds => !isPremiumListing;
}
