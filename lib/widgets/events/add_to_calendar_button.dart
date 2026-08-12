import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme.dart';

/// Adds a calendar event to Apple Calendar (iOS) or Google Calendar (Android).
/// On web, opens the Google Calendar "new event" URL directly.
class AddToCalendarButton extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;

  const AddToCalendarButton({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
  });

  // Events default to 2 hours when no explicit end time is stored.
  DateTime get _endTime => startTime.add(const Duration(hours: 2));

  Future<void> _addToCalendar(BuildContext context) async {
    if (kIsWeb) {
      await _openGoogleCalendarUrl(context);
      return;
    }
    final event = Event(
      title: title,
      description: description,
      location: location,
      startDate: startTime,
      endDate: _endTime,
    );
    final added = await Add2Calendar.addEvent2Cal(event);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open calendar. Please add the event manually.')),
      );
    }
  }

  Future<void> _openGoogleCalendarUrl(BuildContext context) async {
    // Google Calendar "new event" URL with pre-filled fields.
    final start = _formatGCal(startTime);
    final end = _formatGCal(_endTime);
    final encodedTitle = Uri.encodeComponent(title);
    final encodedLocation = Uri.encodeComponent(location);
    final encodedDetails = Uri.encodeComponent(description);
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=$encodedTitle'
      '&dates=$start/$end'
      '&location=$encodedLocation'
      '&details=$encodedDetails',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Calendar.')),
      );
    }
  }

  /// Formats a DateTime to Google Calendar's YYYYMMDDTHHmmssZ format (UTC).
  String _formatGCal(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final mo = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final mi = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '${y}${mo}${d}T${h}${mi}${s}Z';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final calLabel = kIsWeb
        ? 'Add to Google Calendar'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'Add to Apple Calendar'
            : 'Add to Google Calendar';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _addToCalendar(context),
        icon: Icon(
          kIsWeb || defaultTargetPlatform == TargetPlatform.android
              ? Icons.event_rounded
              : Icons.calendar_month_rounded,
          size: AppTheme.iconSm,
        ),
        label: Text(calLabel),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withValues(alpha: AppTheme.opacityHint)),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        ),
      ),
    );
  }
}
