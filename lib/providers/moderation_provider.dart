import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/event_claim.dart';
import '../models/gem.dart';
import '../models/user_report.dart';
import '../repositories/event_claim_repository.dart';
import '../repositories/moderation_repository.dart';
import '../services/gem_service.dart';

/// State for the admin dashboard: the open report list, the events feed,
/// pending venue claims, community gems, and the ban list.
class ModerationProvider extends ChangeNotifier {
  final ModerationRepository _repository;
  final EventClaimRepository _claimsRepository;
  final GemService _gemService;

  ModerationProvider({
    required ModerationRepository repository,
    required EventClaimRepository claimsRepository,
    required GemService gemService,
  })  : _repository = repository,
        _claimsRepository = claimsRepository,
        _gemService = gemService;

  List<UserReport> _reports = [];
  List<UserReport> get reports => _reports;

  List<Event> _events = [];
  List<Event> get events => _events;

  List<Gem> _gems = [];
  List<Gem> get gems => _gems;

  List<EventClaim> _claims = [];
  List<EventClaim> get claims => _claims;
  List<EventClaim> get pendingClaims =>
      _claims.where((c) => c.status == ClaimStatus.pending).toList();

  List<String> _bannedUserIds = [];
  List<String> get bannedUserIds => _bannedUserIds;

  bool _loading = false;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getReports(),
        _repository.getEvents(),
        _claimsRepository.getClaims(),
        _repository.getBannedUserIds(),
        _gemService.getAllForModeration(),
      ]);
      _reports = results[0] as List<UserReport>;
      _events = results[1] as List<Event>;
      _claims = results[2] as List<EventClaim>;
      _bannedUserIds = results[3] as List<String>;
      _gems = results[4] as List<Gem>;
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  /// Marks a report resolved (removes it from the queue).
  Future<bool> resolveReport(String reportId) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      await _repository.resolveReport(reportId);
      _reports = _reports.where((r) => r.id != reportId).toList();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Permanently removes an event (and its mirror) from the public feed.
  Future<bool> deleteEvent(String eventId) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      await _repository.deleteEvent(eventId);
      _events = _events.where((e) => e.id != eventId).toList();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Hide or unhide a community gem so it drops out of (or returns to) public
  /// browsing without deleting it.
  Future<bool> setGemHidden(String gemId, bool hidden) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      await _gemService.setGemHidden(gemId, hidden);
      _gems = _gems
          .map((g) => g.id == gemId ? g.copyWith(hidden: hidden) : g)
          .toList();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Permanently deletes a community gem.
  Future<bool> deleteGem(String gemId) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      // Admin delete: requestingUserId is irrelevant when isAdmin is true.
      await _gemService.deleteGem(gemId, '', isAdmin: true);
      _gems = _gems.where((g) => g.id != gemId).toList();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Approves (unlocks) a venue claim.
  Future<bool> approveClaim(String claimId) => _setClaimStatus(claimId, approve: true);

  /// Rejects a venue claim.
  Future<bool> rejectClaim(String claimId) => _setClaimStatus(claimId, approve: false);

  Future<bool> _setClaimStatus(String claimId, {required bool approve}) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      await _claimsRepository.updateClaimStatus(claimId, approve: approve);
      _claims = _claims
          .map((c) => c.id == claimId
              ? c.copyWith(
                  status: approve ? ClaimStatus.approved : ClaimStatus.rejected,
                  unlocked: approve ? true : c.unlocked,
                )
              : c)
          .toList();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Bans a user — hides all of their content. Returns the fresh ban list.
  Future<bool> banUser(String userId) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      await _repository.banUser(userId);
      _bannedUserIds = await _repository.getBannedUserIds();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }

  /// Lifts a ban — the user's content becomes visible again.
  Future<bool> unbanUser(String userId) async {
    _busy = true;
    notifyListeners();
    var ok = false;
    try {
      await _repository.unbanUser(userId);
      _bannedUserIds = await _repository.getBannedUserIds();
      ok = true;
    } catch (_) {}
    _busy = false;
    notifyListeners();
    return ok;
  }
}
