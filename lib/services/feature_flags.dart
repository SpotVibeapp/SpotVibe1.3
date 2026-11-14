import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config / `meta/feature_flags` keys. Changing a value in the
/// Firebase console (or the Firestore overlay) updates the running app
/// without a store release.
const String kGateRsvpTicketsPremiumFlag = 'gate_rsvp_tickets_premium';
const String kGateBasicRsvpPremiumFlag = 'gate_basic_rsvp_premium';
const String kGateTicketLinkPremiumFlag = 'gate_ticket_link_premium';
const String kGemEarlyAccessHoursFlag = 'gem_early_access_hours';
const String kFreeEventPostsPerMonthFlag = 'free_event_posts_per_month';
const String kFreeEventDescriptionMaxFlag = 'free_event_description_max';

/// [kGateRsvpTicketsPremiumFlag] now gates the outbound ticket link (and,
/// historically, used to gate RSVP confirmation). Basic RSVP — going, a
/// headcount, and the attendee name list — is free unless
/// [kGateBasicRsvpPremiumFlag] is explicitly turned on.
const bool kDefaultGateRsvpTicketsPremium = true;
const bool kDefaultGateBasicRsvpPremium = false;
const int kDefaultGemEarlyAccessHours = 48;
const int kDefaultFreeEventPostsPerMonth = 4;
const int kDefaultFreeEventDescriptionMax = 300;
const int kFreeEventDescriptionMaxFloor = 80;
const int kFreeEventDescriptionMaxCeiling = 400;

int clampFreeEventDescriptionMax(int value) {
  if (value < kFreeEventDescriptionMaxFloor) {
    return kFreeEventDescriptionMaxFloor;
  }
  if (value > kFreeEventDescriptionMaxCeiling) {
    return kFreeEventDescriptionMaxCeiling;
  }
  return value;
}

/// Free posts may keep a grandfathered description that is already longer
/// than the live cap, but they cannot grow past the greater of the two.
int allowedFreeDescriptionLength({
  required int cap,
  int existingLength = 0,
}) {
  final clamped = clampFreeEventDescriptionMax(cap);
  return existingLength > clamped ? existingLength : clamped;
}

/// Ticket-link gate. Defaults to the master [flagOn] value
/// (`gate_rsvp_tickets_premium`). An explicit [ticketLinkOverride] wins.
bool shouldGateTicketLink({
  required bool masterFlagOn,
  bool? ticketLinkOverride,
  required bool isSubscribed,
}) =>
    (ticketLinkOverride ?? masterFlagOn) && !isSubscribed;

/// Basic RSVP (going / headcount / attendee list). Off by default so casual
/// hosts can take RSVPs. Set [basicRsvpFlagOn] to true to put it behind
/// Premium again without an app release.
bool shouldGateBasicRsvp({
  required bool basicRsvpFlagOn,
  required bool isSubscribed,
}) =>
    basicRsvpFlagOn && !isSubscribed;

/// Historical combined helper. Prefer [shouldGateBasicRsvp] or
/// [shouldGateTicketLink]. Kept so older call sites still compile.
bool shouldGateRsvpTickets({
  required bool flagOn,
  required bool isSubscribed,
}) =>
    flagOn && !isSubscribed;

bool canPostAnotherFreeEventThisMonth(
  int postedThisMonth, {
  required bool isPremium,
  int cap = kDefaultFreeEventPostsPerMonth,
}) {
  if (isPremium) return true;
  return postedThisMonth < cap;
}

/// Live feature flags. Defaults are baked in so a fetch miss never opens a
/// paid ticket gate by accident (`gate_rsvp_tickets_premium` stays on),
/// never turns basic RSVP back into a paid feature, and never zeroes the
/// monthly cap or description length.
class FeatureFlags extends ChangeNotifier {
  FeatureFlags({
    FirebaseRemoteConfig? remoteConfig,
    FirebaseFirestore? firestore,
    bool autoFetch = true,
  })  : _remoteConfig = remoteConfig,
        _db = firestore {
    if (autoFetch) {
      // ignore: discarded_futures
      refresh();
    }
  }

  final FirebaseRemoteConfig? _remoteConfig;
  final FirebaseFirestore? _db;

  bool _gateRsvpTicketsPremium = kDefaultGateRsvpTicketsPremium;
  bool _gateBasicRsvpPremium = kDefaultGateBasicRsvpPremium;
  bool? _gateTicketLinkPremium;
  int _gemEarlyAccessHours = kDefaultGemEarlyAccessHours;
  int _freeEventPostsPerMonth = kDefaultFreeEventPostsPerMonth;
  int _freeEventDescriptionMax = kDefaultFreeEventDescriptionMax;
  bool _ready = false;

  bool get isReady => _ready;
  bool get gateRsvpTicketsPremium => _gateRsvpTicketsPremium;
  bool get gateBasicRsvpPremium => _gateBasicRsvpPremium;
  bool? get gateTicketLinkPremium => _gateTicketLinkPremium;
  int get gemEarlyAccessHours => _gemEarlyAccessHours;
  int get freeEventPostsPerMonth => _freeEventPostsPerMonth;
  int get freeEventDescriptionMax => _freeEventDescriptionMax;

  Future<void> refresh() async {
    try {
      await _applyRemoteConfig();
    } catch (e) {
      debugPrint('Remote Config fetch skipped: $e');
    }
    try {
      await _applyFirestoreOverlay();
    } catch (e) {
      debugPrint('feature_flags overlay skipped: $e');
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _applyRemoteConfig() async {
    final rc = _remoteConfig ?? FirebaseRemoteConfig.instance;
    await rc.setDefaults({
      kGateRsvpTicketsPremiumFlag: kDefaultGateRsvpTicketsPremium,
      kGateBasicRsvpPremiumFlag: kDefaultGateBasicRsvpPremium,
      kGemEarlyAccessHoursFlag: kDefaultGemEarlyAccessHours,
      kFreeEventPostsPerMonthFlag: kDefaultFreeEventPostsPerMonth,
      kFreeEventDescriptionMaxFlag: kDefaultFreeEventDescriptionMax,
    });
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 15),
      minimumFetchInterval:
          kReleaseMode ? const Duration(hours: 1) : Duration.zero,
    ));
    await rc.fetchAndActivate();
    _gateRsvpTicketsPremium = rc.getBool(kGateRsvpTicketsPremiumFlag);
    _gateBasicRsvpPremium = rc.getBool(kGateBasicRsvpPremiumFlag);
    final ticketOverride = rc.getValue(kGateTicketLinkPremiumFlag);
    _gateTicketLinkPremium =
        ticketOverride.source == ValueSource.valueRemote
            ? ticketOverride.asBool()
            : null;
    final hours = rc.getInt(kGemEarlyAccessHoursFlag);
    final cap = rc.getInt(kFreeEventPostsPerMonthFlag);
    final descMax = rc.getInt(kFreeEventDescriptionMaxFlag);
    if (hours >= 0) _gemEarlyAccessHours = hours;
    if (cap >= 0) _freeEventPostsPerMonth = cap;
    if (descMax > 0) {
      _freeEventDescriptionMax = clampFreeEventDescriptionMax(descMax);
    }
  }

  /// Optional server-side overlay (`meta/feature_flags`) so functions and
  /// the app can share a kill switch even if Remote Config is delayed.
  Future<void> _applyFirestoreOverlay() async {
    final db = _db ?? FirebaseFirestore.instance;
    final snap = await db.collection('meta').doc('feature_flags').get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    if (data.containsKey(kGateRsvpTicketsPremiumFlag)) {
      _gateRsvpTicketsPremium = data[kGateRsvpTicketsPremiumFlag] != false;
    }
    if (data.containsKey(kGateBasicRsvpPremiumFlag)) {
      _gateBasicRsvpPremium = data[kGateBasicRsvpPremiumFlag] == true;
    }
    if (data.containsKey(kGateTicketLinkPremiumFlag)) {
      _gateTicketLinkPremium = data[kGateTicketLinkPremiumFlag] != false;
    }
    final hours = (data[kGemEarlyAccessHoursFlag] as num?)?.toInt();
    final cap = (data[kFreeEventPostsPerMonthFlag] as num?)?.toInt();
    final descMax = (data[kFreeEventDescriptionMaxFlag] as num?)?.toInt();
    if (hours != null && hours >= 0) _gemEarlyAccessHours = hours;
    if (cap != null && cap >= 0) _freeEventPostsPerMonth = cap;
    if (descMax != null && descMax > 0) {
      _freeEventDescriptionMax = clampFreeEventDescriptionMax(descMax);
    }
  }
}
