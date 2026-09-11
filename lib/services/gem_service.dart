import '../models/gem.dart';
import '../models/moderation_result.dart';
import '../repositories/gem_repository.dart';
import 'ai_moderation_service.dart';

/// Result of a moderated write: either the created object, or a rejection the
/// UI can show to the submitter.
class GemWriteResult<T> {
  final T? value;
  final ModerationResult? rejection;
  const GemWriteResult.ok(this.value) : rejection = null;
  const GemWriteResult.rejected(this.rejection) : value = null;
  bool get isRejected => rejection != null;
}

/// Business logic for community gems: validation, client-side moderation
/// (matching the user-event flow), likes, and comments. A Cloud Function adds
/// a second server-side moderation pass after write.
class GemService {
  GemService({
    required GemRepository repository,
    AiModerationService? moderation,
  })  : _repository = repository,
        _moderation = moderation ?? AiModerationService();

  final GemRepository _repository;
  final AiModerationService _moderation;

  static const int maxGemPhotos = 5;

  Future<List<Gem>> getGems({
    double? lat,
    double? lng,
    double radiusMiles = 60,
    int limit = 200,
  }) =>
      _repository.getGems(
          lat: lat, lng: lng, radiusMiles: radiusMiles, limit: limit);

  Future<Gem?> getGemById(String id, {String? viewerId}) =>
      _repository.getGemById(id, viewerId: viewerId);

  Future<List<Gem>> getGemsForUser(String creatorId) =>
      _repository.getGemsForUser(creatorId);

  /// Create a gem after validating and moderating its text. Returns a rejection
  /// result when the content is blocked, so the caller can show the reason.
  Future<GemWriteResult<Gem>> createGem({
    required String creatorId,
    required String creatorName,
    required String name,
    required GemCategory category,
    required String summary,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    String city = '',
    String state = '',
    List<String> imageUrls = const [],
  }) async {
    if (creatorId.isEmpty || creatorId == 'guest') {
      throw StateError('Sign in to add a hidden gem.');
    }
    if (name.trim().isEmpty) throw ArgumentError('A name is required.');
    if (summary.trim().isEmpty) throw ArgumentError('A short summary is required.');
    if (latitude == 0 && longitude == 0) {
      throw ArgumentError('A location is required.');
    }
    if (imageUrls.length > maxGemPhotos) {
      throw ArgumentError('Gems can include up to $maxGemPhotos photos.');
    }

    final moderation = await _moderation.moderateFields([
      name,
      summary,
      description,
      address,
    ]);
    if (moderation.isRejected) {
      return GemWriteResult.rejected(moderation);
    }

    final gem = Gem(
      id: '',
      creatorId: creatorId,
      creatorName: creatorName.trim().isEmpty ? 'SpotVibe member' : creatorName.trim(),
      name: name.trim(),
      category: category,
      summary: summary.trim(),
      description: description.trim(),
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );
    final created = await _repository.createGem(gem);
    return GemWriteResult.ok(created);
  }

  Future<void> deleteGem(String gemId, String requestingUserId) async {
    final gem = await _repository.getGemById(gemId);
    if (gem == null) return;
    if (gem.creatorId != requestingUserId) {
      throw StateError('Only the person who added this gem can remove it.');
    }
    await _repository.deleteGem(gemId);
  }

  Future<bool> toggleLike(String gemId, String uid) {
    if (uid.isEmpty || uid == 'guest') {
      throw StateError('Sign in to like a gem.');
    }
    return _repository.toggleLike(gemId, uid);
  }

  Future<List<GemComment>> getComments(String gemId) =>
      _repository.getComments(gemId);

  /// Add a comment after moderating it. Returns a rejection when blocked.
  Future<GemWriteResult<GemComment>> addComment({
    required String gemId,
    required String authorId,
    required String authorName,
    String authorAvatarUrl = '',
    required String text,
  }) async {
    if (authorId.isEmpty || authorId == 'guest') {
      throw StateError('Sign in to comment.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('Comment cannot be empty.');
    if (trimmed.length > 2000) {
      throw ArgumentError('Comments are limited to 2000 characters.');
    }

    final moderation = await _moderation.moderateText(trimmed);
    if (moderation.isRejected) {
      return GemWriteResult.rejected(moderation);
    }

    final comment = GemComment(
      id: '',
      authorId: authorId,
      authorName: authorName.trim().isEmpty ? 'SpotVibe member' : authorName.trim(),
      authorAvatarUrl: authorAvatarUrl,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final created = await _repository.addComment(gemId, comment);
    return GemWriteResult.ok(created);
  }

  Future<void> deleteComment(String gemId, String commentId) =>
      _repository.deleteComment(gemId, commentId);
}
