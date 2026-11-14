/// Empty / avatar — do not try to load this as a cover photo.
bool isMissingEventImage(String url) {
  if (url.isEmpty) return true;
  return url.toLowerCase().contains('ui-avatars.com');
}

/// Ticketmaster classification stock (`/dam/c/…`) — reused across many events
/// (genre art such as the baseball-glove 16:9 crop). Documented in
/// [isStockTicketmasterImage] and ticketmaster_service image scoring.
bool isStockTicketmasterImage(String url) =>
    url.toLowerCase().contains('/dam/c/');

/// Bundled venue photos under `assets/venues/`, used as a generic fallback
/// when a provider listing has no unique art. These are stock for the app,
/// not a photo of that night's event.
bool isAppStockFallbackImage(String url) {
  final lower = url.toLowerCase();
  return lower.startsWith('assets/venues/') || lower.contains('/assets/venues/');
}

/// Missing, avatar, Ticketmaster genre stock, or the app's bundled venue
/// fallback. SeatGeek and JamBase have no additional default-image URL
/// patterns in this codebase; empty or avatar URLs are already covered.
bool isGenericEventImage(String url) =>
    isMissingEventImage(url) ||
    isStockTicketmasterImage(url) ||
    isAppStockFallbackImage(url);

bool hasRealEventImage(String url) => !isGenericEventImage(url);

/// Headline drawn on a text-only cover: the event title, or the venue
/// when the title is missing, tiny, or just repeats the venue name.
String eventPlaceholderHeadline({
  required String title,
  required String venue,
}) {
  final trimmedTitle = title.trim();
  final trimmedVenue = venue.trim();
  if (isWeakEventTitle(trimmedTitle, trimmedVenue) && trimmedVenue.isNotEmpty) {
    return trimmedVenue;
  }
  if (trimmedTitle.isNotEmpty) return trimmedTitle;
  return trimmedVenue;
}

bool isWeakEventTitle(String title, String venue) {
  final t = title.trim();
  if (t.isEmpty || t.length < 3) return true;
  final v = venue.trim();
  if (v.isNotEmpty && t.toLowerCase() == v.toLowerCase()) return true;
  return false;
}
