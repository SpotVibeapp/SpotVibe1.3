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

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {
        // try the next candidate
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
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
