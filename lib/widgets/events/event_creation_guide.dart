import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// Opens the creator guide in a large, scrollable bottom sheet.
///
/// The guide intentionally explains plan limits before a creator starts adding
/// media, and stays available from the Create Event app bar after the first
/// automatic presentation.
Future<void> showEventCreationGuide(
  BuildContext context, {
  required bool isPremium,
  required bool isAdmin,
  required VoidCallback onUpgrade,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, scrollController) => EventCreationGuide(
        scrollController: scrollController,
        isPremium: isPremium,
        isAdmin: isAdmin,
        onClose: () => Navigator.of(sheetContext).pop(),
        onUpgrade: isPremium || isAdmin
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onUpgrade();
              },
      ),
    ),
  );
}

/// A persistent entry point near the top of the creation form.
///
/// Keeping the exact media comparison visible here means a creator does not
/// have to remember the first-run tutorial to understand the Free/Premium
/// difference.
class EventCreationGuideCard extends StatelessWidget {
  final VoidCallback onOpen;

  const EventCreationGuideCard({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.eventCreationGuide,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: colors.primary,
                    size: AppTheme.iconMd,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    l10n.eventCreationGuideCardTitle,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              l10n.eventCreationGuideCardBody,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              l10n.eventCreationGuideMediaSummary,
              style: text.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(l10n.openEventCreationGuide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The actual event-creation tutorial content.
///
/// It is public so the contents can be widget-tested independently of the
/// bottom-sheet route.
class EventCreationGuide extends StatelessWidget {
  final ScrollController? scrollController;
  final bool isPremium;
  final bool isAdmin;
  final VoidCallback onClose;
  final VoidCallback? onUpgrade;

  const EventCreationGuide({
    super.key,
    this.scrollController,
    required this.isPremium,
    required this.isAdmin,
    required this.onClose,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final premiumColor = appColors?.proGold ?? AppTheme.brandGold;
    final currentPlanTitle = isAdmin
        ? l10n.eventCreationGuideAdminAccess
        : isPremium
            ? l10n.eventCreationGuidePremiumActive
            : l10n.eventCreationGuideFreeActive;
    final currentPlanColor = isAdmin
        ? AppTheme.brandViolet
        : isPremium
            ? premiumColor
            : colors.primary;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _GuideHeader(onClose: onClose),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  0,
                  AppTheme.spacingMd,
                  AppTheme.spacingXl,
                ),
                children: [
                  _CurrentPlanBanner(
                    label: l10n.eventCreationGuideCurrentPlan,
                    value: currentPlanTitle,
                    color: currentPlanColor,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _GuideStep(
                    number: '1',
                    icon: Icons.edit_note_rounded,
                    title: l10n.eventCreationGuideDetailsTitle,
                    body: l10n.eventCreationGuideDetailsBody,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _GuideStep(
                    number: '2',
                    icon: Icons.auto_awesome_rounded,
                    title: l10n.eventCreationGuideVisualsTitle,
                    body: l10n.eventCreationGuideVisualsBody,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    l10n.eventCreationGuideMediaTitle,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    // Administrators already have full creator access. Show
                    // the capability note without a Free/Premium comparison
                    // or subscription promotion.
                    _AdminAccessNote(text: l10n.eventCreationGuideAdminNote),
                  ] else ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      l10n.eventCreationGuidePlanIntro,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _CreatorPlanComparison(
                      isPremium: isPremium,
                      isAdmin: false,
                      premiumColor: premiumColor,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _SharedToolsNote(text: l10n.eventCreationGuideSharedTools),
                  ],
                  const SizedBox(height: AppTheme.spacingLg),
                  _GuideStep(
                    number: '4',
                    icon: Icons.publish_rounded,
                    title: l10n.eventCreationGuideReviewTitle,
                    body: l10n.eventCreationGuideReviewBody,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  if (onUpgrade != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onClose,
                            child: Text(l10n.eventCreationGuideStart),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onUpgrade,
                            icon: const Icon(Icons.workspace_premium_rounded),
                            label: Text(l10n.eventCreationGuideExplorePremium),
                          ),
                        ),
                      ],
                    )
                  else
                    FilledButton(
                      onPressed: onClose,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                      ),
                      child: Text(l10n.eventCreationGuideStart),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _GuideHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: AppTheme.iconMd,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.eventCreationGuide,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.eventCreationGuideIntro,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.close,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CurrentPlanBanner({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: color, size: AppTheme.iconMd),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    value,
                    style: text.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String body;

  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: text.labelLarge?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: colors.primary, size: AppTheme.iconSm),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  body,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorPlanComparison extends StatelessWidget {
  final bool isPremium;
  final bool isAdmin;
  final Color premiumColor;

  const _CreatorPlanComparison({
    required this.isPremium,
    required this.isAdmin,
    required this.premiumColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final freePlan = _PlanCard(
      title: l10n.freePlan,
      accent: colors.primary,
      isCurrent: !isPremium && !isAdmin,
      currentPlanLabel: l10n.eventCreationGuideCurrentPlan,
      perks: [
        l10n.eventCreationGuideFreeEvents,
        l10n.eventCreationGuideFreeMedia,
        l10n.eventCreationGuideFreePublish,
      ],
    );
    final premiumPlan = _PlanCard(
      title: l10n.premium,
      accent: premiumColor,
      isCurrent: isPremium && !isAdmin,
      currentPlanLabel: l10n.eventCreationGuideCurrentPlan,
      perks: [
        l10n.eventCreationGuidePremiumEvents,
        l10n.eventCreationGuidePremiumMedia,
        l10n.eventCreationGuidePremiumTools,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              freePlan,
              const SizedBox(height: AppTheme.spacingSm),
              premiumPlan,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: freePlan),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(child: premiumPlan),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final Color accent;
  final bool isCurrent;
  final String currentPlanLabel;
  final List<String> perks;

  const _PlanCard({
    required this.title,
    required this.accent,
    required this.isCurrent,
    required this.currentPlanLabel,
    required this.perks,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isCurrent ? 0.11 : 0.055),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: accent.withValues(alpha: isCurrent ? 0.75 : 0.32),
          width: isCurrent ? AppTheme.borderSelected : AppTheme.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Text(
                    currentPlanLabel,
                    style: text.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...perks.map(
            (perk) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: accent, size: 18),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      perk,
                      style: text.bodySmall?.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedToolsNote extends StatelessWidget {
  final String text;

  const _SharedToolsNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.onSecondaryContainer,
            size: AppTheme.iconSm,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAccessNote extends StatelessWidget {
  final String text;

  const _AdminAccessNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.brandViolet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.brandViolet.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_rounded,
            color: AppTheme.brandViolet,
            size: AppTheme.iconSm,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
