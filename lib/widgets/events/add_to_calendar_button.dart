import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/calendar_ics.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/browser_download.dart';
import '../../services/native_calendar.dart';
import '../../theme/theme.dart';

/// Adds a calendar event to Apple Calendar (iOS) or Google Calendar (Android).
/// On web, opens the Google Calendar "new event" URL directly.
class AddToCalendarButton extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  /// The event's actual end when available; legacy listings fall back to two hours.
  final DateTime? endTime;

  const AddToCalendarButton({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    this.endTime,
  });

  // Legacy listings that did not publish an end time still use a conservative
  // two-hour calendar fallback. New creator listings pass their exact end.
  DateTime get _endTime => endTime ?? startTime.add(const Duration(hours: 2));

  Future<void> _addToCalendar(BuildContext context) async {
    final added = await addNativeCalendarEvent(
      title: title,
      description: description,
      location: location,
      start: startTime,
      end: _endTime,
    );
    if (!added) {
      // No native calendar handler accepted the insert (or this is the web
      // app). Fall back to the Google Calendar web form.
      if (context.mounted) await _openGoogleCalendarUrl(context);
    }
  }

  Future<void> _downloadIcs() async {
    final ics = buildEventIcs(
      uid: '${title.hashCode}-${startTime.millisecondsSinceEpoch}',
      title: title,
      description: description,
      location: location,
      start: startTime,
      end: _endTime,
    );
    await downloadBytes(
      filename: 'spotvibe-event.ics',
      bytes: Uint8List.fromList(utf8.encode(ics)),
      mimeType: 'text/calendar',
    );
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
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showCalendarError(context);
      }
    } catch (_) {
      if (context.mounted) _showCalendarError(context);
    }
  }

  void _showCalendarError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.googleCalendarError)),
    );
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
    final l10n = AppLocalizations.of(context)!;
    final calLabel = kIsWeb
        ? l10n.addToGoogleCalendar
        : defaultTargetPlatform == TargetPlatform.iOS
            ? l10n.addToAppleCalendar
            : l10n.addToGoogleCalendar;

    final button = OutlinedButton.icon(
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
    );

    if (!kIsWeb) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: AppTheme.spacingSm),
        OutlinedButton.icon(
          onPressed: _downloadIcs,
          icon: const Icon(Icons.download_rounded, size: AppTheme.iconSm),
          label: Text(l10n.downloadIcs),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: colors.primary,
            side: BorderSide(
              color: colors.primary.withValues(alpha: AppTheme.opacityHint),
            ),
          ),
        ),
      ],
    );
  }
}
