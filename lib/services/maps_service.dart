import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';

/// Opens turn-by-turn directions in Apple Maps, Google Maps, or the browser.
class MapsService {
  /// Address or "lat,lng" used as the maps destination.
  static String destinationQuery(Event event) {
    if (event.latitude != 0 || event.longitude != 0) {
      return '${event.latitude},${event.longitude}';
    }
    final parts = [
      event.address,
      event.location,
      event.city,
      event.state,
      event.zipCode,
    ].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  static Uri googleDirectionsUri(Event event) {
    final dest = destinationQuery(event);
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(dest)}',
    );
  }

  static Uri appleDirectionsUri(Event event) {
    final dest = destinationQuery(event);
    return Uri.parse(
      'https://maps.apple.com/?daddr=${Uri.encodeComponent(dest)}',
    );
  }

  static Future<bool> openDirections(Event event) async {
    final dest = destinationQuery(event);
    if (dest.trim().isEmpty) return false;

    final candidates = <Uri>[];
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        candidates.add(appleDirectionsUri(event));
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        candidates.add(Uri.parse('geo:0,0?q=${Uri.encodeComponent(dest)}'));
      }
    }
    candidates.add(googleDirectionsUri(event));

    // Launch directly and catch — canLaunchUrl is unreliable on Android 11+
    // (package visibility) even when a handler exists.
    for (final uri in candidates) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {
        // try the next candidate
      }
    }
    return false;
  }

  /// Open directions to a raw coordinate (used by Hidden Gems, which are places
  /// identified by lat/lng rather than [Event]s).
  static Future<bool> openDirectionsToCoords(
    double lat,
    double lng, {
    String? label,
  }) async {
    final dest = '$lat,$lng';
    final candidates = <Uri>[];
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        candidates.add(Uri.parse('https://maps.apple.com/?daddr=$dest'));
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final q = label != null && label.trim().isNotEmpty
            ? '$dest(${Uri.encodeComponent(label)})'
            : dest;
        candidates.add(Uri.parse('geo:$dest?q=$q'));
      }
    }
    candidates.add(Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$dest'));

    for (final uri in candidates) {
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      } catch (_) {
        // try next
      }
    }
    return false;
  }

  static Future<bool> openTickets(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
