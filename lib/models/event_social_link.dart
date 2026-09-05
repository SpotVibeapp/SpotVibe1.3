import 'package:flutter/foundation.dart';

/// Social platforms that organizers can link from an event page.
///
/// These are public outbound profile links only. SpotVibe does not request
/// social-media passwords, connect accounts, or post on an organizer's behalf.
enum SocialPlatform {
  instagram,
  facebook,
  snapchat,
  tiktok,
  youtube,
}

extension SocialPlatformDetails on SocialPlatform {
  String get storageKey => name;

  String get label {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.snapchat:
        return 'Snapchat';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.youtube:
        return 'YouTube';
    }
  }

  /// Builds the official public-profile URL for a plain handle.
  String profileUrlForHandle(String handle) {
    final encoded = Uri.encodeComponent(handle);
    switch (this) {
      case SocialPlatform.instagram:
        return 'https://www.instagram.com/$encoded/';
      case SocialPlatform.facebook:
        return 'https://www.facebook.com/$encoded';
      case SocialPlatform.snapchat:
        return 'https://www.snapchat.com/add/$encoded';
      case SocialPlatform.tiktok:
        return 'https://www.tiktok.com/@$encoded';
      case SocialPlatform.youtube:
        return 'https://www.youtube.com/@$encoded';
    }
  }

  /// Only official platform hosts are accepted for a stored link. This keeps
  /// a public organizer link from turning into an arbitrary external redirect.
  bool acceptsHost(String host) {
    final value = host.toLowerCase();
    switch (this) {
      case SocialPlatform.instagram:
        return _isHost(value, 'instagram.com');
      case SocialPlatform.facebook:
        return _isHost(value, 'facebook.com') ||
            _isHost(value, 'fb.com') ||
            _isHost(value, 'fb.me');
      case SocialPlatform.snapchat:
        return _isHost(value, 'snapchat.com');
      case SocialPlatform.tiktok:
        return _isHost(value, 'tiktok.com');
      case SocialPlatform.youtube:
        return _isHost(value, 'youtube.com') || _isHost(value, 'youtu.be');
    }
  }
}

bool _isHost(String host, String root) =>
    host == root || host.endsWith('.$root');

const int kMaxSocialLinkLength = 512;

/// A verified-safe public social profile link for an event organizer.
@immutable
class EventSocialLink {
  final SocialPlatform platform;
  final String url;

  const EventSocialLink({required this.platform, required this.url});
}

/// Immutable event-level organizer social links.
///
/// URLs are normalized to HTTPS, limited to the matching official platform,
/// and never retain a query string or fragment. That avoids storing tracking
/// parameters or accidentally pasted access tokens in an otherwise public
/// listing document.
@immutable
class EventSocialLinks {
  final Map<SocialPlatform, String> _values;

  const EventSocialLinks.empty() : _values = const {};

  EventSocialLinks._(this._values);

  factory EventSocialLinks.fromInput(Map<SocialPlatform, String?> rawValues) {
    final normalized = <SocialPlatform, String>{};
    for (final platform in SocialPlatform.values) {
      final link = normalizeSocialProfileLink(platform, rawValues[platform]);
      if (link != null) normalized[platform] = link;
    }
    return EventSocialLinks._fromNormalized(normalized);
  }

  factory EventSocialLinks.fromStorage(dynamic stored) {
    if (stored is! Map) return const EventSocialLinks.empty();

    final normalized = <SocialPlatform, String>{};
    for (final platform in SocialPlatform.values) {
      final rawValue = stored[platform.storageKey];
      if (rawValue is! String) continue;
      final link = normalizeSocialProfileLink(platform, rawValue);
      if (link != null) normalized[platform] = link;
    }
    return EventSocialLinks._fromNormalized(normalized);
  }

  static EventSocialLinks _fromNormalized(
    Map<SocialPlatform, String> values,
  ) {
    if (values.isEmpty) return const EventSocialLinks.empty();
    return EventSocialLinks._(Map.unmodifiable(values));
  }

  bool get isEmpty => _values.isEmpty;
  bool get isNotEmpty => _values.isNotEmpty;
  int get length => _values.length;

  String? operator [](SocialPlatform platform) => _values[platform];

  Map<SocialPlatform, String> get values => Map.unmodifiable(_values);

  List<EventSocialLink> get entries => [
        for (final platform in SocialPlatform.values)
          if (_values[platform] != null)
            EventSocialLink(platform: platform, url: _values[platform]!),
      ];

  Map<String, String> toStorageMap() => Map.unmodifiable({
        for (final entry in _values.entries) entry.key.storageKey: entry.value,
      });
}

/// Returns the first platform whose nonempty form input cannot become a safe
/// public profile URL. Empty fields are intentionally valid and omitted.
SocialPlatform? firstInvalidSocialPlatform(
  Map<SocialPlatform, String?> rawValues,
) {
  for (final platform in SocialPlatform.values) {
    final value = rawValues[platform]?.trim() ?? '';
    if (value.isNotEmpty && normalizeSocialProfileLink(platform, value) == null) {
      return platform;
    }
  }
  return null;
}

/// Converts a public handle or an official platform URL into a safe HTTPS URL.
///
/// Examples:
/// - `@spotvibe` in the Instagram field becomes
///   `https://www.instagram.com/spotvibe/`.
/// - `facebook.com/spotvibe` becomes `https://facebook.com/spotvibe`.
/// - An unrelated host, custom URI scheme, or malformed handle is rejected.
String? normalizeSocialProfileLink(SocialPlatform platform, String? rawValue) {
  final raw = rawValue?.trim() ?? '';
  if (raw.isEmpty) return null;
  if (raw.length > kMaxSocialLinkLength) return null;

  final candidate = _looksLikeUrl(raw)
      ? _withHttpsScheme(raw)
      : _handleUrl(platform, raw);
  if (candidate == null) return null;

  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.path.isEmpty ||
      uri.path == '/' ||
      !platform.acceptsHost(uri.host)) {
    return null;
  }

  // Social profile links are public. Discard query/fragments so a copied
  // tracking parameter or temporary token cannot be republished by SpotVibe.
  return uri.replace(scheme: 'https', query: null, fragment: null).toString();
}

bool _looksLikeUrl(String value) {
  final lower = value.toLowerCase();
  if (lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('www.') ||
      value.contains('/')) {
    return true;
  }

  // A bare domain (for example, instagram.com) should be validated as a URL,
  // while an ordinary Instagram handle such as `spot.vibe` stays a handle.
  return RegExp(r'^[^\s]+\.(?:com|net|org|io|co|me)$', caseSensitive: false)
      .hasMatch(value);
}

String? _withHttpsScheme(String value) {
  final lower = value.toLowerCase();
  if (lower.startsWith('https://') || lower.startsWith('http://')) {
    return value;
  }
  if (value.contains('://')) return null;
  return 'https://$value';
}

String? _handleUrl(SocialPlatform platform, String value) {
  final handle = value.startsWith('@') ? value.substring(1) : value;
  if (!RegExp(r'^[A-Za-z0-9._-]{1,100}$').hasMatch(handle)) return null;
  return platform.profileUrlForHandle(handle);
}
