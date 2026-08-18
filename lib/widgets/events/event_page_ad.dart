import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// In-feed promo shown on free event pages. Premium listings omit this.
class EventPageAd extends StatelessWidget {
  const EventPageAd({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sponsored,
            style: text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            l10n.goingOutThisWeek,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.pageAdBody,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.browseEvents),
            ),
          ),
        ],
      ),
    );
  }
}
