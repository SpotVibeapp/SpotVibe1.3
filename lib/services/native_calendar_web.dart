/// Browsers have no calendar provider plugin. The button falls back to a
/// Google Calendar link and an `.ics` download.
Future<bool> addNativeCalendarEvent({
  required String title,
  required String description,
  required String location,
  required DateTime start,
  required DateTime end,
}) async =>
    false;
