import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// user completed first-run setup (permissions screen). Consumed once on the
/// first launch after installation so the user lands on the right event.
const String _kPendingLinkKey = 'spotvibe_pending_deep_link';
const String _kPendingLinkKeyLegacy = 'vibely_pending_deep_link';

/// Deep-link helpers. Uses the platform's App Links / universal links /
/// custom-scheme routing (`app_links`) — no third-party link SDK.
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
  /// and is restored immediately after.
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

  /// Shares the event via the native OS share sheet with a rich message that
  /// includes the formatted date, venue, and a deep link.
  static Future<void> shareEvent(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
    required bool isUserEvent,
    DateTime? eventDateTime,
    String? eventLocation,
  }) async {
    final link =
        isUserEvent ? userEventLink(eventId) : eventLink(eventId);

    final message = _buildShareMessage(
      title: eventTitle,
      link: link,
      dateTime: eventDateTime,
      location: eventLocation,
    );

    if (kIsWeb) {
      // Web: copy to clipboard (Share.share is not supported in all browsers).
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
  /// SnackBar. Lightweight fallback when full share UI is not desired.
  static Future<void> copyEventLink(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
    required bool isUserEvent,
  }) async {
    final link = isUserEvent ? userEventLink(eventId) : eventLink(eventId);
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
