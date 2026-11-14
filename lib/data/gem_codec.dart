import '../models/event_social_link.dart';
import '../models/gem.dart';
import 'event_codec.dart' show parseStoreDate;
import 'gem_hours.dart';

/// Serializes [Gem]s and [GemComment]s to and from Firestore maps.
Map<String, dynamic> gemToMap(Gem gem) {
  return {
    'creatorId': gem.creatorId,
    'creatorName': gem.creatorName,
    'name': gem.name,
    'category': gem.category.key,
    'summary': gem.summary,
    'description': gem.description,
    'latitude': gem.latitude,
    'longitude': gem.longitude,
    'address': gem.address,
    'city': gem.city,
    'state': gem.state,
    'imageUrls': gem.imageUrls,
    'likeCount': gem.likeCount,
    'commentCount': gem.commentCount,
    'hidden': gem.hidden,
    'createdAtMs': gem.createdAt.millisecondsSinceEpoch,
    'approvedAtMs': (gem.approvedAt ?? gem.createdAt).millisecondsSinceEpoch,
    if (gem.visibleToFreeAt != null)
      'visibleToFreeAtMs': gem.visibleToFreeAt!.millisecondsSinceEpoch,
    'listingKind': gem.listingKind.name,
    if (gem.richUntil != null) 'richUntilMs': gem.richUntil!.millisecondsSinceEpoch,
    if (gem.richActivatedAt != null)
      'richActivatedAtMs': gem.richActivatedAt!.millisecondsSinceEpoch,
    if (gem.contactPhone != null) 'contactPhone': gem.contactPhone,
    if (gem.contactWebsite != null) 'contactWebsite': gem.contactWebsite,
    if (gem.socialLinks.isNotEmpty) 'socialLinks': gem.socialLinks.toStorageMap(),
    if (gem.promoTitle != null) 'promoTitle': gem.promoTitle,
    if (gem.promoDetails != null) 'promoDetails': gem.promoDetails,
    if (gem.promoStartsAt != null)
      'promoStartsAtMs': gem.promoStartsAt!.millisecondsSinceEpoch,
    if (gem.promoEndsAt != null)
      'promoEndsAtMs': gem.promoEndsAt!.millisecondsSinceEpoch,
    if (gem.businessType != null) 'businessType': gem.businessType!.key,
    if (gem.hours.isNotEmpty) 'hours': gem.hours.toStorageMap(),
    if (gem.offerTitle != null) 'offerTitle': gem.offerTitle,
    if (gem.offerText != null) 'offerText': gem.offerText,
    if (gem.offerUntil != null)
      'offerUntilMs': gem.offerUntil!.millisecondsSinceEpoch,
    'hasOffer': gem.hasOffer,
    'listingTier': gem.listingTier.name,
    if (gem.richUntil != null) 'promoUntilMs': gem.richUntil!.millisecondsSinceEpoch,
    if (gem.searchTokens.isNotEmpty) 'searchTokens': gem.searchTokens,
    if (gem.geoCells.isNotEmpty) 'geoCells': gem.geoCells,
  };
}

Gem gemFromMap(
  String id,
  Map<String, dynamic> data, {
  bool likedByMe = false,
}) {
  return Gem(
    id: id,
    creatorId: (data['creatorId'] as String?) ?? '',
    creatorName: (data['creatorName'] as String?) ?? 'SpotVibe member',
    name: (data['name'] as String?) ?? '',
    category: GemCategory.fromKey(data['category'] as String?),
    summary: (data['summary'] as String?) ?? '',
    description: (data['description'] as String?) ?? '',
    latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
    address: (data['address'] as String?) ?? '',
    city: (data['city'] as String?) ?? '',
    state: (data['state'] as String?) ?? '',
    imageUrls: ((data['imageUrls'] as List?)?.cast<String>()) ?? const [],
    likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
    commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    likedByMe: likedByMe,
    hidden: (data['hidden'] as bool?) ?? false,
    createdAt: parseStoreDate(data['createdAt'] ?? data['createdAtMs']),
    approvedAt: data['approvedAt'] != null || data['approvedAtMs'] != null
        ? parseStoreDate(data['approvedAt'] ?? data['approvedAtMs'])
        : null,
    visibleToFreeAt: data['visibleToFreeAt'] != null || data['visibleToFreeAtMs'] != null
        ? parseStoreDate(data['visibleToFreeAt'] ?? data['visibleToFreeAtMs'])
        : null,
    listingKind: gemListingKindFromName(data['listingKind'] as String?),
    richUntil: data['richUntil'] != null || data['richUntilMs'] != null
        ? parseStoreDate(data['richUntil'] ?? data['richUntilMs'])
        : null,
    richActivatedAt: data['richActivatedAt'] != null || data['richActivatedAtMs'] != null
        ? parseStoreDate(data['richActivatedAt'] ?? data['richActivatedAtMs'])
        : null,
    contactPhone: data['contactPhone'] as String?,
    contactWebsite: data['contactWebsite'] as String?,
    socialLinks: EventSocialLinks.fromStorage(data['socialLinks'] ?? data['contactSocial']),
    promoTitle: data['promoTitle'] as String?,
    promoDetails: data['promoDetails'] as String?,
    promoStartsAt: data['promoStartsAt'] != null || data['promoStartsAtMs'] != null
        ? parseStoreDate(data['promoStartsAt'] ?? data['promoStartsAtMs'])
        : null,
    promoEndsAt: data['promoEndsAt'] != null || data['promoEndsAtMs'] != null
        ? parseStoreDate(data['promoEndsAt'] ?? data['promoEndsAtMs'])
        : null,
    businessType: GemBusinessType.fromKey(data['businessType'] as String?),
    hours: GemWeeklyHours.fromStorage(data['hours']),
    offerTitle: (data['offerTitle'] as String?) ?? (data['promoTitle'] as String?),
    offerText: (data['offerText'] as String?) ?? (data['promoDetails'] as String?),
    offerUntil: data['offerUntil'] != null || data['offerUntilMs'] != null
        ? parseStoreDate(data['offerUntil'] ?? data['offerUntilMs'])
        : (data['promoEndsAt'] != null || data['promoEndsAtMs'] != null
            ? parseStoreDate(data['promoEndsAt'] ?? data['promoEndsAtMs'])
            : null),
    hasOffer: data['hasOffer'] == true,
    listingTier: gemListingTierFromName(data['listingTier'] as String?),
    searchTokens: ((data['searchTokens'] as List?)?.map((e) => e.toString()).toList()) ?? const [],
    geoCells: ((data['geoCells'] as List?)?.map((e) => e.toString()).toList()) ?? const [],
  );
}

Map<String, dynamic> gemCommentToMap(GemComment comment) {
  return {
    'authorId': comment.authorId,
    'authorName': comment.authorName,
    'authorAvatarUrl': comment.authorAvatarUrl,
    'text': comment.text,
    'hidden': comment.hidden,
    'createdAtMs': comment.createdAt.millisecondsSinceEpoch,
  };
}

GemComment gemCommentFromMap(String id, Map<String, dynamic> data) {
  return GemComment(
    id: id,
    authorId: (data['authorId'] as String?) ?? '',
    authorName: (data['authorName'] as String?) ?? 'SpotVibe member',
    authorAvatarUrl: (data['authorAvatarUrl'] as String?) ?? '',
    text: (data['text'] as String?) ?? '',
    hidden: (data['hidden'] as bool?) ?? false,
    createdAt: parseStoreDate(data['createdAt'] ?? data['createdAtMs']),
  );
}
