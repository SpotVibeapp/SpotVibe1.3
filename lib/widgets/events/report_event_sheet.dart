import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';

/// Why someone is reporting an event.
///
/// The reasons mirror the top listing complaints at aggregators (fake or
/// copied events, wrong dates/places, events that never happened) plus the
/// store-required "offensive" bucket (App Store guideline 1.2, Google Play
/// User Generated Content policy). [code] is what the moderation queue sees;
/// it is stable and not localized.
enum EventReportReason {
  fakeOrSpam('fake_or_spam'),
  wrongDetails('wrong_details'),
  cancelled('cancelled'),
  offensive('offensive'),
  other('other');

  const EventReportReason(this.code);
  final String code;
}

/// Builds the `reason` string stored in `user_reports`.
///
/// Format: `<code>` or `<code>: <note>`. Notes are trimmed and the whole
/// string is capped so it always passes the rules' 1000-character limit
/// (the repository adds a short `[event] ` prefix).
String buildEventReportReason(EventReportReason reason, String note) {
  final trimmed = note.trim().replaceAll(RegExp(r'\s+'), ' ');
  final full = trimmed.isEmpty ? reason.code : '${reason.code}: $trimmed';
  const maxLen = 900;
  return full.length <= maxLen ? full : full.substring(0, maxLen);
}

String eventReportReasonLabel(AppLocalizations l10n, EventReportReason r) {
  switch (r) {
    case EventReportReason.fakeOrSpam:
      return l10n.reportReasonFake;
    case EventReportReason.wrongDetails:
      return l10n.reportReasonWrongDetails;
    case EventReportReason.cancelled:
      return l10n.reportReasonCancelled;
    case EventReportReason.offensive:
      return l10n.reportReasonOffensive;
    case EventReportReason.other:
      return l10n.reportReasonOther;
  }
}

/// Opens the report flow for [event] and files a real moderation report.
///
/// Replaces an older dialog that only showed "thanks" without saving
/// anything. Reports need an account (Firestore rules), so signed-out people
/// are offered sign-in instead of a fake confirmation.
Future<void> showEventReportSheet(BuildContext context,
    {required Event event}) async {
  final l10n = AppLocalizations.of(context)!;
  final auth = context.read<AuthProvider>();
  final messenger = ScaffoldMessenger.of(context);

  if (!auth.isLoggedIn) {
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.reportSignInRequired),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: l10n.signIn,
        onPressed: () => context.push('/login'),
      ),
    ));
    return;
  }

  final result = await showModalBottomSheet<_ReportChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ReportSheet(),
  );
  if (result == null) return;

  final ok = await auth.reportContent(
    contentType: 'event',
    contentId: event.id,
    reportedUserId: event.creatorId,
    reason: buildEventReportReason(result.reason, result.note),
  );
  messenger.showSnackBar(SnackBar(
    content: Text(ok ? l10n.reportSubmittedThanks : l10n.reportFailed),
    behavior: SnackBarBehavior.floating,
  ));
}

class _ReportChoice {
  final EventReportReason reason;
  final String note;
  const _ReportChoice(this.reason, this.note);
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  EventReportReason? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingMd,
          right: AppTheme.spacingMd,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingMd,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reportEvent, style: text.titleMedium),
              const SizedBox(height: AppTheme.spacingXs),
              Text(l10n.whatsWrong,
                  style: text.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppTheme.spacingSm),
              RadioGroup<EventReportReason>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in EventReportReason.values)
                      RadioListTile<EventReportReason>(
                        key: ValueKey('report-reason-${r.code}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: r,
                        title: Text(eventReportReasonLabel(l10n, r)),
                      ),
                  ],
                ),
              ),
              TextField(
                key: const ValueKey('report-note'),
                controller: _note,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(hintText: l10n.reportNoteHint),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ElevatedButton(
                key: const ValueKey('report-submit'),
                onPressed: _reason == null
                    ? null
                    : () => Navigator.pop(
                        context, _ReportChoice(_reason!, _note.text)),
                child: Text(l10n.submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
