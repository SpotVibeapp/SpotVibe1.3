import '../models/gem.dart';
import 'event_codec.dart' show parseStoreDate;

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
