/// Weekday opening hours stored on a Hidden Gem. Keys are ISO weekdays
/// (1 = Monday … 7 = Sunday). A missing or null day means closed.
class GemOpenInterval {
  final int openMinutes;
  final int closeMinutes;

  const GemOpenInterval({required this.openMinutes, required this.closeMinutes});

  factory GemOpenInterval.fromHours({
    required int openHour,
    int openMinute = 0,
    required int closeHour,
    int closeMinute = 0,
  }) =>
      GemOpenInterval(
        openMinutes: openHour * 60 + openMinute,
        closeMinutes: closeHour * 60 + closeMinute,
      );

  static GemOpenInterval? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final open = _parseClock(raw['open']);
    final close = _parseClock(raw['close']);
    if (open == null || close == null) return null;
    return GemOpenInterval(openMinutes: open, closeMinutes: close);
  }

  Map<String, String> toStorageMap() => {
        'open': _formatClock(openMinutes),
        'close': _formatClock(closeMinutes),
      };

  bool contains(int minutes) {
    if (closeMinutes > openMinutes) {
      return minutes >= openMinutes && minutes < closeMinutes;
    }
    // Overnight, e.g. 18:00–02:00.
    return minutes >= openMinutes || minutes < closeMinutes;
  }
}

class GemWeeklyHours {
  final Map<int, GemOpenInterval?> days;

  const GemWeeklyHours(this.days);

  static const empty = GemWeeklyHours({});

  bool get isEmpty => days.values.every((d) => d == null);
  bool get isNotEmpty => !isEmpty;

  factory GemWeeklyHours.fromStorage(dynamic raw) {
    if (raw is! Map) return empty;
    final days = <int, GemOpenInterval?>{};
    raw.forEach((key, value) {
      final weekday = int.tryParse(key.toString());
      if (weekday == null || weekday < 1 || weekday > 7) return;
      days[weekday] = GemOpenInterval.tryParse(value);
    });
    return GemWeeklyHours(days);
  }

  Map<String, dynamic> toStorageMap() => {
        for (final entry in days.entries)
          if (entry.value != null) '${entry.key}': entry.value!.toStorageMap(),
      };

  bool isOpenAt(DateTime time) {
    final interval = days[time.weekday];
    if (interval == null) return false;
    return interval.contains(time.hour * 60 + time.minute);
  }
}

int? _parseClock(dynamic value) {
  if (value is num) return value.toInt();
  if (value is! String) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

String _formatClock(int minutes) {
  final hour = (minutes ~/ 60) % 24;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
