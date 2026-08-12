import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../theme/theme.dart';

class PracticalDetailsSection extends StatelessWidget {
  final Event event;
  const PracticalDetailsSection({super.key, required this.event});

  // Derive duration from category since Event has no explicit end time.
  String _duration() {
    switch (event.category.toLowerCase()) {
      case 'music':
      case 'concerts':
        return '2–3 hours';
      case 'sports':
        return '2–4 hours';
      case 'comedy':
        return '1–2 hours';
      case 'food & drink':
      case 'food':
        return '1–3 hours';
      case 'arts':
      case 'film':
        return '1.5–2.5 hours';
      case 'nightlife':
        return '3–5 hours';
      case 'fitness':
        return '1–2 hours';
      case 'community':
      case 'family':
        return '2–4 hours';
      default:
        return '2–3 hours';
    }
  }

  // Derive an age label from category and cost heuristics.
  String? _ageRestriction() {
    final cat = event.category.toLowerCase();
    if (cat == 'nightlife') return '21+ only';
    if (cat == 'music' && (event.cost ?? 0) > 30) return '18+';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ageLabel = _ageRestriction();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Practical Info', style: text.titleMedium),
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
                label: 'Weather',
                value: 'Check forecast closer to the date',
              ),
              _divider(colors),
              _DetailRow(
                icon: Icons.local_parking_rounded,
                iconColor: colors.primary,
                label: 'Parking',
                value: 'Street parking & nearby lots available',
              ),
              _divider(colors),
              _DetailRow(
                icon: Icons.timer_outlined,
                iconColor: colors.secondary,
                label: 'Duration',
                value: _duration(),
              ),
              if (ageLabel != null) ...[
                _divider(colors),
                _DetailRow(
                  icon: Icons.person_outlined,
                  iconColor: colors.error,
                  label: 'Age',
                  value: ageLabel,
                ),
              ],
              _divider(colors),
              _DetailRow(
                icon: Icons.accessible_rounded,
                iconColor: appColors(context).success,
                label: 'Accessible',
                value: 'Wheelchair accessible venue',
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
