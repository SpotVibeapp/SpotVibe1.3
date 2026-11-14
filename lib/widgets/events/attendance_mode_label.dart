import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/attendance_mode.dart';

String attendanceModeLabel(AppLocalizations l10n, AttendanceMode mode) {
  switch (mode) {
    case AttendanceMode.dropIn:
      return l10n.attendanceModeDropIn;
    case AttendanceMode.rsvpRequested:
      return l10n.attendanceModeRsvp;
    case AttendanceMode.tickets:
      return l10n.attendanceModeTickets;
  }
}

/// Plain-text attendance mode for cards and detail pages. Not a badge.
class AttendanceModeLabel extends StatelessWidget {
  final AttendanceMode mode;
  final TextStyle? style;

  const AttendanceModeLabel({super.key, required this.mode, this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      attendanceModeLabel(l10n, mode),
      style: style ??
          Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
    );
  }
}
