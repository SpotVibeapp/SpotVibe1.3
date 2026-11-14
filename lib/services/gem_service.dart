import '../data/gem_listing.dart';
import '../data/gem_visibility.dart';
import '../models/event_social_link.dart';
import '../models/gem.dart';
import '../models/moderation_result.dart';
import '../repositories/gem_repository.dart';
import 'ai_moderation_service.dart';
import 'moderation_pipeline.dart';
import 'parallel_moderation_service.dart';

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
/// (matching the user-event flow), likes, and comments. The banned-word
/// Cloud Function and the parallel flagging function both run after write.
/// The parallel pass never changes the primary accept/reject decision.
class GemService {
  GemService({
    required GemRepository repository,
    AiModerationService? moderation,
    ParallelModerationService? parallelModeration,
  })  : _repository = repository,
        _moderation = moderation ?? AiModerationService(),
        _parallel = parallelModeration;

  final GemRepository _repository;
  final AiModerationService _moderation;
  final ParallelModerationService? _parallel;

  static const int maxGemPhotos = 5;

  Future<List<Gem>> getGems({
    double? lat,
    double? lng,
    double radiusMiles = 60,
    int limit = 200,
    bool applyEarlyAccess = false,
    bool isPremium = false,
    String? viewerId,
    int delayHours = 48,
  }) async {
    final list = await _repository.getGems(
        lat: lat, lng: lng, radiusMiles: radiusMiles, limit: limit);
    final visible = applyEarlyAccess
        ? filterGemsForViewer(
            list,
            isPremium: isPremium,
            viewerId: viewerId,
            delayHours: delayHours,
          )
        : list;
    return [
      for (final gem in visible) _publicView(gem, viewerId: viewerId),
    ];
  }

  Gem _publicView(Gem gem, {String? viewerId}) {
    if (viewerId != null && viewerId.isNotEmpty && viewerId == gem.creatorId) {
      return gem;
    }
    return gemForDisplay(gem);
  }

  Future<GemQueryPage> getGemsPage({
    double? lat,
    double? lng,
    double radiusMiles = 60,
    int limit = 40,
    Object? startAfter,
    bool applyEarlyAccess = false,
    bool isPremium = false,
    String? viewerId,
    int delayHours = 48,
  }) async {
    final page = await _repository.queryGems(
      lat: lat,
      lng: lng,
      radiusMiles: radiusMiles,
      limit: limit,
      startAfter: startAfter,
    );
    var list = page.gems;
    if (applyEarlyAccess) {
      list = filterGemsForViewer(
        list,
        isPremium: isPremium,
        viewerId: viewerId,
        delayHours: delayHours,
      );
    }
    list = [for (final gem in list) _publicView(gem, viewerId: viewerId)];
    return GemQueryPage(gems: list, cursor: page.cursor, hasMore: page.hasMore);
  }

  Future<Gem?> getGemById(
    String id, {
    String? viewerId,
    bool applyEarlyAccess = false,
    bool isPremium = false,
    int delayHours = 48,
  }) async {
    final gem = await _repository.getGemById(id, viewerId: viewerId);
    if (gem == null) return null;
    if (applyEarlyAccess &&
        !gemVisibleToViewer(
          gem,
          isPremium: isPremium,
          viewerId: viewerId,
          delayHours: delayHours,
        )) {
      return null;
    }
    return _publicView(gem, viewerId: viewerId);
  }

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
    GemListingKind listingKind = GemListingKind.community,
    String? contactPhone,
    String? contactWebsite,
    EventSocialLinks socialLinks = const EventSocialLinks.empty(),
    String? promoTitle,
    String? promoDetails,
    DateTime? promoStartsAt,
    DateTime? promoEndsAt,
    String? id,
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

    final moderation = await ModerationPipeline.moderateFields(
      primary: _moderation,
      parallel: _parallel,
      authorId: creatorId,
      fields: [name, summary, description, address],
    );
    if (moderation.isRejected) {
      return GemWriteResult.rejected(moderation);
    }

    final isBusiness = listingKind == GemListingKind.business;
    final gem = Gem(
      id: id ?? '',
      creatorId: creatorId,
      creatorName: creatorName.trim().isEmpty ? 'SpotVibe member' : creatorName.trim(),
      name: name.trim(),
      category: category,
      summary: summary.trim(),
      description: isBusiness ? description.trim() : '',
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      imageUrls: isBusiness ? imageUrls : const [],
      createdAt: DateTime.now(),
      listingKind: listingKind,
      contactPhone: isBusiness ? contactPhone : null,
      contactWebsite: isBusiness ? contactWebsite : null,
      socialLinks: isBusiness ? socialLinks : const EventSocialLinks.empty(),
      promoTitle: isBusiness ? promoTitle : null,
      promoDetails: isBusiness ? promoDetails : null,
      promoStartsAt: isBusiness ? promoStartsAt : null,
      promoEndsAt: isBusiness ? promoEndsAt : null,
    );
    final created = await _repository.createGem(gem);
    return GemWriteResult.ok(created);
  }

  /// Update an existing gem's editable fields after moderating the new text.
  /// Only the original creator (or an admin) may edit. Returns a rejection
  /// result when the content is blocked.
  Future<GemWriteResult<Gem>> updateGem({
    required String gemId,
    required String requestingUserId,
    bool isAdmin = false,
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
    GemListingKind? listingKind,
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
  }) async {
    final existing = await _repository.getGemById(gemId);
    if (existing == null) {
      throw StateError('This gem no longer exists.');
    }
    if (!isAdmin && existing.creatorId != requestingUserId) {
      throw StateError('Only the person who added this gem can edit it.');
    }
    if (name.trim().isEmpty) throw ArgumentError('A name is required.');
    if (summary.trim().isEmpty) throw ArgumentError('A short summary is required.');
    if (latitude == 0 && longitude == 0) {
      throw ArgumentError('A location is required.');
    }
    if (imageUrls.length > maxGemPhotos) {
      throw ArgumentError('Gems can include up to $maxGemPhotos photos.');
    }

    final moderation = await ModerationPipeline.moderateFields(
      primary: _moderation,
      parallel: _parallel,
      authorId: requestingUserId,
      fields: [name, summary, description, address],
    );
    if (moderation.isRejected) {
      return GemWriteResult.rejected(moderation);
    }

    final kind = listingKind ?? existing.listingKind;
    final isBusiness = kind == GemListingKind.business;
    final updated = existing.copyWith(
      name: name.trim(),
      category: category,
      summary: summary.trim(),
      description: isBusiness ? description.trim() : '',
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      imageUrls: isBusiness ? imageUrls : const [],
      listingKind: kind,
      contactPhone: isBusiness ? contactPhone : null,
      clearContactPhone: !isBusiness || clearContactPhone,
      contactWebsite: isBusiness ? contactWebsite : null,
      clearContactWebsite: !isBusiness || clearContactWebsite,
      socialLinks: isBusiness ? (socialLinks ?? existing.socialLinks) : const EventSocialLinks.empty(),
      promoTitle: isBusiness ? promoTitle : null,
      clearPromoTitle: !isBusiness || clearPromoTitle,
      promoDetails: isBusiness ? promoDetails : null,
      clearPromoDetails: !isBusiness || clearPromoDetails,
      promoStartsAt: isBusiness ? promoStartsAt : null,
      clearPromoStartsAt: !isBusiness || clearPromoStartsAt,
      promoEndsAt: isBusiness ? promoEndsAt : null,
      clearPromoEndsAt: !isBusiness || clearPromoEndsAt,
    );
    final saved = await _repository.updateGem(updated);
    return GemWriteResult.ok(saved);
  }

  Future<Gem> renewGemRich({
    required String gemId,
    required String requestingUserId,
    bool isAdmin = false,
  }) {
    return _repository.renewGemRich(
      gemId,
      requestingUserId: requestingUserId,
      isAdmin: isAdmin,
    );
  }

  Future<void> deleteGem(
    String gemId,
    String requestingUserId, {
    bool isAdmin = false,
  }) async {
    final gem = await _repository.getGemById(gemId);
    if (gem == null) return;
    if (!isAdmin && gem.creatorId != requestingUserId) {
      throw StateError('Only the person who added this gem can remove it.');
    }
    await _repository.deleteGem(gemId);
  }

  // ── Admin moderation ────────────────────────────────────────────────────

  /// Every gem regardless of hidden state, newest first (admin dashboard).
  Future<List<Gem>> getAllForModeration({int limit = 300}) =>
      _repository.getAllForModeration(limit: limit);

  /// Hide (or unhide) a gem so it is excluded from public browsing without
  /// permanently deleting it. Admin-gated by Firestore rules.
  Future<void> setGemHidden(String gemId, bool hidden) =>
      _repository.setHidden(gemId, hidden);

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

    final moderation = await ModerationPipeline.moderateText(
      primary: _moderation,
      parallel: _parallel,
      text: trimmed,
      authorId: authorId,
    );
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
