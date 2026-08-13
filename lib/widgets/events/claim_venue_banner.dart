import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/event.dart';
import '../../theme/theme.dart';

/// A small, subtle banner shown on auto-generated event pages that invites
/// venue owners to claim the page and access Premium controls.
class ClaimVenueBanner extends StatelessWidget {
  final Event event;
  const ClaimVenueBanner({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/claim-venue', extra: event),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.store_rounded,
              size: AppTheme.iconSm + 2,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'Promoter? Claim this event with Premium (\$15/mo).',
                style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppTheme.iconSm + 4,
              color: colors.onSurfaceVariant.withValues(alpha: AppTheme.opacityHint),
            ),
          ],
        ),
      ),
    );
  }
}
