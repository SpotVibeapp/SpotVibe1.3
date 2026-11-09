/// Builds an iCalendar document for one event. Used by the web "Download .ics"
/// button. Times are UTC, which Google Calendar and Apple Calendar both accept.
String buildEventIcs({
  required String uid,
  required String title,
  required String description,
  required String location,
  required DateTime start,
  required DateTime end,
}) {
  String stamp(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  String escape(String raw) => raw
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//SpotVibe LLC//SpotVibe//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    'UID:$uid@spotvibeapp.com',
    'DTSTAMP:${stamp(DateTime.now())}',
    'DTSTART:${stamp(start)}',
    'DTEND:${stamp(end)}',
    'SUMMARY:${escape(title)}',
    'DESCRIPTION:${escape(description)}',
    'LOCATION:${escape(location)}',
    'END:VEVENT',
    'END:VCALENDAR',
    '',
  ].join('\r\n');
}
