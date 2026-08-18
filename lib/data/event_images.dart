/// Empty / avatar — do not try to load this as a cover photo.
bool isMissingEventImage(String url) {
  if (url.isEmpty) return true;
  return url.toLowerCase().contains('ui-avatars.com');
}

/// Ticketmaster classification stock (`/dam/c/…`) — reused across many events.
/// Still a real photo; just not unique. Prefer something else when we have it.
bool isStockTicketmasterImage(String url) =>
    url.toLowerCase().contains('/dam/c/');

/// Missing, avatar, or TM genre stock. Used by dedupe to decide whether to
/// steal a venue photo from the other listing.
bool isGenericEventImage(String url) =>
    isMissingEventImage(url) || isStockTicketmasterImage(url);
