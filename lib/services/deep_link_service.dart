import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL used for all SpotVibe deep links.
/// On Android this triggers the intent-filter; on iOS the associated domain.
const String kDeepLinkBase = 'https://spotvibe.app';

/// Hosts that map to in-app event routes (current brand + legacy Vibely links).
const Set<String> _kDeepLinkHosts = {'spotvibe.app', 'www.spotvibe.app', 'vibely.app'};

/// Custom URI schemes that map to in-app event routes.
const Set<String> _kDeepLinkSchemes = {'spotvibe', 'vibely'};

/// SharedPreferences key that stores a deep link path that arrived before the
/// user completed first-run setup (permissions screen).  Consumed once on the
/// first launch after installation so the user lands on the right event.
const String _kPendingLinkKey = 'spotvibe_pending_deep_link';
const String _kPendingLinkKeyLegacy = 'vibely_pending_deep_link';

class DeepLinkService {
  /// Returns the shareable deep link URL for a curated event.
  static String eventLink(String eventId) => '$kDeepLinkBase/event/$eventId';

  /// Returns the shareable deep link URL for a user-created event.
  static String userEventLink(String eventId) =>
      '$kDeepLinkBase/user-event/$eventId';

  /// Extracts the GoRouter path (e.g. `/event/42`) from either an https URL
  /// (`https://spotvibe.app/event/42`) or a custom-scheme URL
  /// (`spotvibe://event/42`). Legacy `vibely.app` / `vibely://` links still
  /// resolve. Returns `null` for unrecognised URLs.
  static String? pathFromUri(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        _kDeepLinkHosts.contains(uri.host)) {
      final p = uri.path;
      if (p.startsWith('/event/') || p.startsWith('/user-event/')) return p;
    }
    if (_kDeepLinkSchemes.contains(uri.scheme)) {
      final p = '/${uri.host}${uri.path}';
      if (p.startsWith('/event/') || p.startsWith('/user-event/')) return p;
    }
    return null;
  }

  /// Persists a GoRouter path so it survives the first-run permission screen
  /// and is restored immediately after.  Call this whenever a link arrives
  /// before the user reaches the main app (e.g. from [AppRouter]'s redirect).
  static Future<void> savePendingLink(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingLinkKey, path);
  }

  /// Returns and clears the stored pending link in one atomic operation.
  /// Returns `null` when nothing is stored.
  static Future<String?> consumePendingLink() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kPendingLinkKey) ??
        prefs.getString(_kPendingLinkKeyLegacy);
    if (path != null) {
      await prefs.remove(_kPendingLinkKey);
      await prefs.remove(_kPendingLinkKeyLegacy);
    }
    return path;
  }

  /// Generates a Branch short link for the given event.  Falls back to the
  /// standard HTTPS deep link if Branch is unavailable or on web.
  static Future<String> branchEventLink({
    required String eventId,
    required String eventTitle,
    required bool isUserEvent,
  }) async {
    final fallback =
        isUserEvent ? userEventLink(eventId) : eventLink(eventId);
    if (kIsWeb) return fallback;
    try {
      final buo = BranchUniversalObject(
        canonicalIdentifier: isUserEvent ? 'user-event/$eventId' : 'event/$eventId',
        title: eventTitle,
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('eventId', eventId)
          ..addCustomMetadata('isUserEvent', isUserEvent.toString()),
      );
      final lp = BranchLinkProperties(
        channel: 'app',
        feature: 'share',
      )..addControlParam(
          '\$deeplink_path',
          isUserEvent ? '/user-event/$eventId' : '/event/$eventId',
        );
      final response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: lp,
      );
      if (response.success && response.result != null) {
        return response.result!;
      }
    } catch (_) {}
    return fallback;
  }

  /// Shares the event via the native OS share sheet with a rich message that
  /// includes the formatted date, venue, and a Branch deep link (falls back to
  /// the plain HTTPS link on web or when Branch is unavailable).
  ///
  /// Pass [eventDateTime] and [eventLocation] to build the full message; if
  /// omitted the message falls back to title + link only.
  static Future<void> shareEvent(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
    required bool isUserEvent,
    DateTime? eventDateTime,
    String? eventLocation,
  }) async {
    // Resolve the deep link — try Branch first, fall back to HTTPS.
    final link = await branchEventLink(
      eventId: eventId,
      eventTitle: eventTitle,
      isUserEvent: isUserEvent,
    );

    final message = _buildShareMessage(
      title: eventTitle,
      link: link,
      dateTime: eventDateTime,
      location: eventLocation,
    );

    if (kIsWeb) {
      // Web: copy to clipboard (Share.share is not supported in all browsers)
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link copied — share "$eventTitle"'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    await Share.share(message, subject: '$eventTitle — SpotVibe');
  }

  /// Builds the shareable text message combining title, date, location & link.
  static String _buildShareMessage({
    required String title,
    required String link,
    DateTime? dateTime,
    String? location,
  }) {
    final dateLine = dateTime != null
        ? '📅 ${DateFormat('EEE, MMM d · h:mm a').format(dateTime)}\n'
        : '';
    final locationLine =
        (location != null && location.isNotEmpty) ? '📍 $location\n' : '';
    return 'Check out $title!\n\n'
        '$dateLine'
        '$locationLine'
        '\n$link';
  }

  /// Copies the event deep link to the clipboard and shows a confirmation
  /// SnackBar. Use this as a lightweight fallback when full share UI is
  /// not desired.
  static Future<void> copyEventLink(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
    required bool isUserEvent,
  }) async {
    final link =
        isUserEvent ? userEventLink(eventId) : eventLink(eventId);
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copied — share "$eventTitle"'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Thin wrapper around [FlutterBranchSdk] that isolates all Branch calls and
/// keeps the rest of the app free of direct SDK imports.
///
/// All public methods are no-ops on web ([kIsWeb] guard) so the app compiles
/// and runs without Branch on Flutter Web.
class BranchService {
  bool _initialized = false;

  /// Initialises the Branch SDK.  Must be called once before [runApp], after
  /// [WidgetsFlutterBinding.ensureInitialized].
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await FlutterBranchSdk.initSession();
      _initialized = true;
    } catch (_) {}
  }

  /// Returns the GoRouter path that Branch recovered from before/during this
  /// session's cold start, or `null` if Branch delivered no link.
  ///
  /// Branch fires the deferred link on the *first* open after a fresh install,
  /// which is the scenario that [app_links] + [SharedPreferences] cannot cover.
  Future<String?> getInitialLink() async {
    if (kIsWeb || !_initialized) return null;
    try {
      final completer = Completer<String?>();
      // initSession fires once immediately with the session data on cold
      // start, then stays live for foreground links.  We only want the first
      // event here — the runtime stream is handled separately in SpotVibeApp.
      StreamSubscription<Map<dynamic, dynamic>>? sub;
      sub = FlutterBranchSdk.initSession().listen((data) {
        sub?.cancel();
        final url = data['\$canonical_url'] as String? ??
            data['~referring_link'] as String?;
        final path = url != null ? DeepLinkService.pathFromUri(url) : null;
        if (!completer.isCompleted) completer.complete(path);
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      // Timeout: if Branch doesn't respond within 4 s, give up gracefully.
      return await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          sub?.cancel();
          return null;
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// A broadcast stream of GoRouter paths derived from Branch links that
  /// arrive while the app is running (foreground / background resume).
  /// Yields only non-null paths that map to a recognised event route.
  Stream<String> get linkStream {
    if (kIsWeb || !_initialized) return const Stream.empty();
    return FlutterBranchSdk.initSession()
        .where((data) =>
            data['\$canonical_url'] != null ||
            data['~referring_link'] != null)
        .map((data) {
          final url = data['\$canonical_url'] as String? ??
              data['~referring_link'] as String?;
          return url != null ? DeepLinkService.pathFromUri(url) : null;
        })
        .where((path) => path != null)
        .cast<String>();
  }
}
