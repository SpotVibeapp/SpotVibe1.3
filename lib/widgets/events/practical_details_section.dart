import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';
import '../common/section_title.dart';

class PracticalDetailsSection extends StatelessWidget {
  final Event event;
  const PracticalDetailsSection({super.key, required this.event});

  // Derive duration from category since Event has no explicit end time.
  String _duration(AppLocalizations l10n) {
    switch (event.category.toLowerCase()) {
      case 'music':
      case 'concerts':
        return l10n.dur2to3;
      case 'sports':
        return l10n.dur2to4;
      case 'comedy':
        return l10n.dur1to2;
      case 'food & drink':
      case 'food':
        return l10n.dur1to3;
      case 'arts':
      case 'film':
        return l10n.dur15to25;
      case 'nightlife':
        return l10n.dur3to5;
      case 'fitness':
        return l10n.dur1to2;
      case 'community':
      case 'family':
        return l10n.dur2to4;
      default:
        return l10n.dur2to3;
    }
  }

  // Derive an age label from category and cost heuristics.
  String? _ageRestriction(AppLocalizations l10n) {
    final cat = event.category.toLowerCase();
    if (cat == 'nightlife') return l10n.age21plus;
    if (cat == 'music' && (event.cost ?? 0) > 30) return l10n.age18plus;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ageLabel = _ageRestriction(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.practicalInfo, accent: categoryAccent(event.category)),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFF59E0B),
                label: l10n.weather,
                value: l10n.weatherValue,
              ),
              _divider(colors),
              _DetailRow(
                icon: Icons.local_parking_rounded,
                iconColor: colors.primary,
                label: l10n.parking,
                value: l10n.parkingValue,
              ),
              _divider(colors),
              _DetailRow(
                icon: Icons.timer_outlined,
                iconColor: colors.secondary,
                label: l10n.duration,
                value: _duration(l10n),
              ),
              if (ageLabel != null) ...[
                _divider(colors),
                _DetailRow(
                  icon: Icons.person_outlined,
                  iconColor: colors.error,
                  label: l10n.age,
                  value: ageLabel,
                ),
              ],
              _divider(colors),
              _DetailRow(
                icon: Icons.accessible_rounded,
                iconColor: appColors(context).success,
                label: l10n.accessible,
                value: l10n.accessibleValue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(ColorScheme colors) => Divider(
        height: 1,
        indent: AppTheme.spacingMd + AppTheme.iconSm + AppTheme.spacingSm + AppTheme.spacingSm,
        endIndent: AppTheme.spacingMd,
        color: colors.outlineVariant.withValues(alpha: 0.3),
      );

  AppColorsExtension appColors(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>()!;
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          Container(
            width: AppTheme.iconSm + AppTheme.spacingSm * 2,
            height: AppTheme.iconSm + AppTheme.spacingSm * 2,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, size: AppTheme.iconSm, color: iconColor),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
