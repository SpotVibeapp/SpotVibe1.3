import '../models/event.dart';
import '../models/rsvp.dart';
import '../models/user_event.dart';

/// Parses Firestore `Timestamp`, millis, ISO strings, or [DateTime].
DateTime parseStoreDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  try {
    final ms = (value as dynamic).millisecondsSinceEpoch;
    if (ms is int) return DateTime.fromMillisecondsSinceEpoch(ms);
  } catch (_) {}
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {}
  return DateTime.now();
}

EventSource eventSourceFromName(String? name) {
  if (name == null || name.isEmpty) return EventSource.local;
  for (final value in EventSource.values) {
    if (value.name == name) return value;
  }
  return EventSource.local;
}

RecurringType recurringTypeFromName(String? name) {
  switch (name) {
    case 'weekly':
      return RecurringType.weekly;
    case 'monthly':
      return RecurringType.monthly;
    default:
      return RecurringType.none;
  }
}

Map<String, dynamic> eventToMap(Event event, {String kind = 'curated'}) {
  return {
    'title': event.title,
    'description': event.description,
    'dateTimeMs': event.dateTime.millisecondsSinceEpoch,
    'location': event.location,
    'address': event.address,
    'city': event.city,
    'state': event.state,
    'zipCode': event.zipCode,
    'cost': event.cost,
    'imageUrl': event.imageUrl,
    'category': event.category,
    'organizerName': event.organizerName,
    'organizerAvatarUrl': event.organizerAvatarUrl,
    'bookmarkedCount': event.bookmarkedCount,
    'interestedCount': event.interestedCount,
    'latitude': event.latitude,
    'longitude': event.longitude,
    'source': event.source.name,
    'sourceUrl': event.sourceUrl,
    'kind': kind,
    'cityKey': event.city.toLowerCase().trim(),
    'isPremiumListing': event.isPremiumListing,
    'isCreatorPro': event.isCreatorPro,
    'featuredWeekKey': event.featuredWeekKey,
  };
}

Event eventFromMap(String id, Map<String, dynamic> data) {
  return Event(
    id: id,
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    dateTime: parseStoreDate(data['dateTime'] ?? data['dateTimeMs']),
    location: data['location'] as String? ?? '',
    address: data['address'] as String? ?? '',
    city: data['city'] as String? ?? '',
    state: data['state'] as String? ?? '',
    zipCode: data['zipCode'] as String? ?? '',
    cost: (data['cost'] as num?)?.toDouble(),
    imageUrl: data['imageUrl'] as String? ?? '',
    category: data['category'] as String? ?? 'Community',
    organizerName: data['organizerName'] as String? ?? '',
    organizerAvatarUrl: data['organizerAvatarUrl'] as String? ?? '',
    bookmarkedCount: (data['bookmarkedCount'] as num?)?.toInt() ?? 0,
    interestedCount: (data['interestedCount'] as num?)?.toInt() ?? 0,
    latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
    source: eventSourceFromName(data['source'] as String?),
    sourceUrl: data['sourceUrl'] as String?,
    isPremiumListing: data['isPremiumListing'] as bool? ?? false,
    isCreatorPro: data['isCreatorPro'] as bool? ?? false,
    featuredWeekKey: data['featuredWeekKey'] as String?,
    isUserCreated: data['kind'] == 'user' ||
        (data['creatorId'] as String?)?.isNotEmpty == true,
  );
}

Map<String, dynamic> commentToMap(EventComment comment) {
  return {
    'authorId': comment.authorId,
    'authorName': comment.authorName,
    'authorAvatarUrl': comment.authorAvatarUrl,
    'text': comment.text,
    'createdAtMs': comment.createdAt.millisecondsSinceEpoch,
  };
}

EventComment commentFromMap(String id, Map<String, dynamic> data) {
  return EventComment(
    id: id,
    authorId: data['authorId'] as String? ?? '',
    authorName: data['authorName'] as String? ?? '',
    authorAvatarUrl: data['authorAvatarUrl'] as String? ?? '',
    text: data['text'] as String? ?? '',
    createdAt: parseStoreDate(data['createdAt'] ?? data['createdAtMs']),
  );
}

Map<String, dynamic> rsvpToMap(RsvpEntry entry) {
  return {
    'userId': entry.userId,
    'userName': entry.userName,
    'avatarUrl': entry.avatarUrl,
    'isPrivate': entry.isPrivate,
    'rsvpAtMs': entry.rsvpAt.millisecondsSinceEpoch,
  };
}

RsvpEntry rsvpFromMap(Map<String, dynamic> data) {
  return RsvpEntry(
    userId: data['userId'] as String? ?? '',
    userName: data['userName'] as String? ?? '',
    avatarUrl: data['avatarUrl'] as String? ?? '',
    isPrivate: data['isPrivate'] as bool? ?? false,
    rsvpAt: parseStoreDate(data['rsvpAt'] ?? data['rsvpAtMs']),
  );
}

Map<String, dynamic> userEventToMap(UserCreatedEvent event) {
  return {
    ...eventToMap(
      Event(
        id: event.id,
        title: event.title,
        description: event.description,
        dateTime: event.dateTime,
        location: event.location,
        address: event.address,
        city: event.city,
        state: event.state,
        zipCode: event.zipCode,
        cost: event.cost,
        imageUrl: event.imageUrl,
        category: event.category,
        organizerName: event.organizerName,
        organizerAvatarUrl: '',
        interestedCount: event.interestedCount,
        latitude: 0,
        longitude: 0,
        source: EventSource.local,
        isPremiumListing: event.isPremiumListing,
        isCreatorPro: event.isCreatorPro,
        featuredWeekKey: event.featuredWeekKey,
        isUserCreated: true,
      ),
      kind: 'user',
    ),
    'creatorId': event.creatorId,
    'videoUrl': event.videoUrl,
    'mapLink': event.mapLink,
    'chatLink': event.chatLink,
    'isPremiumListing': event.isPremiumListing,
    'createdAtMs': event.createdAt.millisecondsSinceEpoch,
    'isCreatorPro': event.isCreatorPro,
    'recurringType': event.recurringType.name,
    'contactPhone': event.contactPhone,
    'contactWebsite': event.contactWebsite,
    'contactSocial': event.contactSocial,
    'brandColor': event.brandColor,
    'brandLogoUrl': event.brandLogoUrl,
    'featuredWeekKey': event.featuredWeekKey,
    'analyticsSearchImpressions': event.analyticsSearchImpressions,
    'analyticsViews': event.analyticsViews,
    'analyticsSaves': event.analyticsSaves,
    'analyticsClicks': event.analyticsClicks,
  };
}

UserCreatedEvent userEventFromMap(String id, Map<String, dynamic> data) {
  return UserCreatedEvent(
    id: id,
    creatorId: data['creatorId'] as String? ?? '',
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    dateTime: parseStoreDate(data['dateTime'] ?? data['dateTimeMs']),
    location: data['location'] as String? ?? '',
    address: data['address'] as String? ?? '',
    city: data['city'] as String? ?? '',
    state: data['state'] as String? ?? '',
    zipCode: data['zipCode'] as String? ?? '',
    cost: (data['cost'] as num?)?.toDouble(),
    imageUrl: data['imageUrl'] as String? ?? '',
    videoUrl: data['videoUrl'] as String?,
    category: data['category'] as String? ?? 'Community',
    organizerName: data['organizerName'] as String? ?? '',
    mapLink: data['mapLink'] as String?,
    chatLink: data['chatLink'] as String?,
    isPremiumListing: data['isPremiumListing'] as bool? ?? false,
    interestedCount: (data['interestedCount'] as num?)?.toInt() ?? 0,
    createdAt: parseStoreDate(data['createdAt'] ?? data['createdAtMs']),
    isCreatorPro: data['isCreatorPro'] as bool? ?? false,
    recurringType: recurringTypeFromName(data['recurringType'] as String?),
    contactPhone: data['contactPhone'] as String?,
    contactWebsite: data['contactWebsite'] as String?,
    contactSocial: data['contactSocial'] as String?,
    brandColor: data['brandColor'] as String?,
    brandLogoUrl: data['brandLogoUrl'] as String?,
    analyticsSearchImpressions:
        (data['analyticsSearchImpressions'] as num?)?.toInt() ?? 0,
    analyticsViews: (data['analyticsViews'] as num?)?.toInt() ?? 0,
    analyticsSaves: (data['analyticsSaves'] as num?)?.toInt() ?? 0,
    analyticsClicks: (data['analyticsClicks'] as num?)?.toInt() ?? 0,
  );
}
