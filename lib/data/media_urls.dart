/// Maximum media items in one event. The cover counts as one of the photos.
const int kMaxEventPhotos = 5;
const int kMaxEventVideos = 3;

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
