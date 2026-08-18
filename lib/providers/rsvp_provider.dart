import 'package:flutter/foundation.dart';
import '../models/rsvp.dart';
import '../repositories/rsvp_repository.dart';

class RsvpProvider extends ChangeNotifier {
  final RsvpRepository _repository;
  final String eventId;
  final String currentUserId;

  RsvpProvider({
    required RsvpRepository repository,
    required this.eventId,
    required this.currentUserId,
  }) : _repository = repository;

  List<EventComment> _comments = [];
  List<EventComment> get comments => _comments;

  List<RsvpEntry> _rsvps = [];
  List<RsvpEntry> get rsvps => _rsvps;

  /// Public attendees (non-private RSVPs).
  List<RsvpEntry> get publicAttendees => _rsvps.where((r) => !r.isPrivate).toList();

  /// Total count including private RSVPs.
  int get totalRsvpCount => _rsvps.length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// Whether the current user has RSVP'd.
  bool get hasRsvp => _rsvps.any((r) => r.userId == currentUserId);

  /// Whether the current user's RSVP is private.
  bool get myRsvpIsPrivate {
    try {
      return _rsvps.firstWhere((r) => r.userId == currentUserId).isPrivate;
    } catch (_) {
      return false;
    }
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getComments(eventId),
        _repository.getRsvps(eventId),
      ]);
      _comments = results[0] as List<EventComment>;
      _rsvps = results[1] as List<RsvpEntry>;
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addComment({
    required String text,
    required String authorName,
    required String authorAvatar,
  }) async {
    try {
      final comment = await _repository.addComment(
        eventId: eventId,
        text: text,
        authorId: currentUserId,
        authorName: authorName,
        authorAvatar: authorAvatar,
      );
      _comments = [..._comments, comment];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> rsvp({
    required String userName,
    required String avatarUrl,
    required bool isPrivate,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final entry = await _repository.addRsvp(
        eventId: eventId,
        userId: currentUserId,
        userName: userName,
        avatarUrl: avatarUrl,
        isPrivate: isPrivate,
      );
      _rsvps = [
        ..._rsvps.where((r) => r.userId != currentUserId),
        entry,
      ];
    } catch (_) {}
    _isSubmitting = false;
    notifyListeners();
  }

  Future<void> cancelRsvp() async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.removeRsvp(eventId: eventId, userId: currentUserId);
      _rsvps = _rsvps.where((r) => r.userId != currentUserId).toList();
    } catch (_) {}
    _isSubmitting = false;
    notifyListeners();
  }

  /// Removes a comment (admin/moderation). Returns false on failure.
  Future<bool> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(
        eventId: eventId,
        commentId: commentId,
      );
      _comments = _comments.where((c) => c.id != commentId).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
