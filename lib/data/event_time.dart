import 'package:intl/intl.dart';

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
