import 'package:intl/intl.dart';

/// Whether an event window has an explicit end after its start.
///
/// New creator events must satisfy this check before they can be published.
bool hasValidEventWindow(DateTime dateTime, DateTime? endDateTime) =>
    endDateTime != null && endDateTime.isAfter(dateTime);

/// Whether an event has started but its explicit end time has not passed.
///
/// Legacy events without [endDateTime] remain visible only until their start
/// time, rather than guessing an end time and incorrectly calling a finished
/// event live.
bool isEventHappeningNow(
  DateTime dateTime,
  DateTime? endDateTime, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  return !dateTime.isAfter(clock) &&
      endDateTime != null &&
      endDateTime.isAfter(clock);
}

/// Whether an event should appear in the active discovery feed.
///
/// Upcoming events always appear. Events that have started stay visible only
/// when they have an explicit future end time.
bool isEventVisibleInFeed(
  DateTime dateTime,
  DateTime? endDateTime, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  return dateTime.isAfter(clock) ||
      isEventHappeningNow(dateTime, endDateTime, now: clock);
}

/// Full start/end range for an event detail page.
String formatEventTimeRange(DateTime dateTime, DateTime? endDateTime) {
  final start = dateTime.toLocal();
  if (endDateTime == null) {
    return DateFormat('EEEE, MMMM d, y · h:mm a').format(start);
  }

  final end = endDateTime.toLocal();
  final sameDay = start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (sameDay) {
    return '${DateFormat('EEEE, MMMM d, y').format(start)} · '
        '${DateFormat('h:mm a').format(start)} – '
        '${DateFormat('h:mm a').format(end)}';
  }

  return '${DateFormat('EEE, MMM d, y · h:mm a').format(start)} – '
      '${DateFormat('EEE, MMM d, y · h:mm a').format(end)}';
}

/// Human event time: "Tonight · 6:00 PM", "Tomorrow · 7:30 PM", "Sat, Aug 16 · 6:00 PM".
String formatEventWhen(DateTime dateTime, {DateTime? now}) {
  final local = dateTime.toLocal();
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = DateFormat('h:mm a').format(local);
  final delta = day.difference(today).inDays;

  if (delta == 0) {
    final label = local.hour >= 17 ? 'Tonight' : 'Today';
    return '$label · $time';
  }
  if (delta == 1) return 'Tomorrow · $time';
  if (delta == -1) return 'Yesterday · $time';
  if (delta > 1 && delta < 7) {
    return '${DateFormat('EEE, MMM d').format(local)} · $time';
  }
  return '${DateFormat('EEE, MMM d').format(local)} · $time';
}

/// Compact chip on a card image: "Tonight", "Sat", "Aug 16".
String formatEventDayChip(DateTime dateTime, {DateTime? now}) {
  final local = dateTime.toLocal();
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final day = DateTime(local.year, local.month, local.day);
  final delta = day.difference(today).inDays;

  if (delta == 0) return local.hour >= 17 ? 'Tonight' : 'Today';
  if (delta == 1) return 'Tomorrow';
  if (delta > 1 && delta < 7) return DateFormat('EEE').format(local);
  return DateFormat('MMM d').format(local);
}
