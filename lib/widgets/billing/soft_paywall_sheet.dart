import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// A non-blocking sheet that explains a Premium-gated attendee action
/// (RSVP confirmation or an outbound ticket link) and offers the paywall.
Future<bool> showSoftPaywallSheet(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final text = Theme.of(ctx).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingMd,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppTheme.spacingSm),
            Text(body, style: text.bodyMedium),
            const SizedBox(height: AppTheme.spacingLg),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.goPremium),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.notNow),
            ),
          ],
        ),
      );
    },
  );
  if (result == true && context.mounted) {
    await context.push('/paywall');
    return true;
  }
  return false;
}
