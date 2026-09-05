/// Absolute media safety limits in one event. The cover counts as one photo.
const int kMaxEventPhotos = 5;
const int kMaxEventVideos = 3;

/// A useful Free listing can still have a proper cover and a short clip.
const int kFreeEventPhotos = 1;
const int kFreeEventVideos = 1;

/// The gallery allowance shown in the creator UI. The full 5-photo / 3-video
/// experience belongs to Premium organizers and the official admin account.
class EventMediaAllowance {
  final int maxPhotos;
  final int maxVideos;
  final bool hasFullGallery;

  const EventMediaAllowance({
    required this.maxPhotos,
    required this.maxVideos,
    required this.hasFullGallery,
  });
}

EventMediaAllowance eventMediaAllowance({
  required bool isPremium,
  required bool isAdmin,
}) {
  if (isPremium || isAdmin) {
    return const EventMediaAllowance(
      maxPhotos: kMaxEventPhotos,
      maxVideos: kMaxEventVideos,
      hasFullGallery: true,
    );
  }
  return const EventMediaAllowance(
    maxPhotos: kFreeEventPhotos,
    maxVideos: kFreeEventVideos,
    hasFullGallery: false,
  );
}

/// Normalizes media URL lists stored with event documents.
///
/// Legacy events may only have a single `imageUrl` or `videoUrl`, while new
/// events carry ordered galleries. Keep URLs trimmed, non-empty, and unique so
/// the cover is never rendered twice in a gallery.
List<String> normalizeMediaUrls(Iterable<String?> values) {
  final seen = <String>{};
  final urls = <String>[];
  for (final value in values) {
    final url = value?.trim() ?? '';
    if (url.isNotEmpty && seen.add(url)) urls.add(url);
  }
  return List.unmodifiable(urls);
}

/// Safely converts Firestore/JSON list data into media URLs.
List<String> mediaUrlsFromValue(Object? value) {
  if (value is String || value is! Iterable) return const [];
  return normalizeMediaUrls(value.whereType<String>());
}
