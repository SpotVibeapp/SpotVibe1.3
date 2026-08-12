import 'package:flutter/material.dart';
import '../../providers/event_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/events/filter_sheet.dart';

/// Airbnb-style horizontal scrollable filter chips.
/// Shows active filter state per dimension; tapping any chip opens FilterSheet.
/// A "Clear all" chip appears as the first item whenever any filter is active.
class FilterQuickChips extends StatelessWidget {
  final EventProvider eventProvider;

  const FilterQuickChips({super.key, required this.eventProvider});

  // ── helpers ──────────────────────────────────────────────────────────────────

  String _dateLabel() {
    switch (eventProvider.filterDate) {
      case 'today':
        return 'Today';
      case 'tomorrow':
        return 'Tomorrow';
      case 'this_weekend':
        return 'This weekend';
      case 'this_week':
        return 'This week';
      case 'custom':
        return 'Custom date';
      default:
        return 'Date';
    }
  }

  String _priceLabel() {
    switch (eventProvider.filterPrice) {
      case 'free':
        return 'Free';
      case 'under_20':
        return 'Under \$20';
      case 'under_50':
        return 'Under \$50';
      default:
        return 'Price';
    }
  }

  String _timeLabel() {
    switch (eventProvider.filterTime) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      default:
        return 'Time';
    }
  }

  bool get _dateActive => eventProvider.filterDate != 'all' ||
      eventProvider.filterDateFrom != null ||
      eventProvider.filterDateTo != null;
  bool get _priceActive => eventProvider.filterPrice != 'all';
  bool get _timeActive => eventProvider.filterTime != 'all';
  bool get _sourcesActive => eventProvider.selectedSources.isNotEmpty;

  void _openSheet(BuildContext context) {
    FilterSheet.show(
      context,
      initialDatePreset: eventProvider.filterDate,
      initialDateFrom: eventProvider.filterDateFrom,
      initialDateTo: eventProvider.filterDateTo,
      initialPrice: eventProvider.filterPrice,
      initialCostType: eventProvider.filterCostType,
      initialTimeOfDay: eventProvider.filterTime,
      initialLocation: eventProvider.filterLocation,
      initialSources: eventProvider.selectedSources,
      initialRadius: eventProvider.searchRadius,
      onApply: ({
        datePreset = 'all',
        dateFrom,
        dateTo,
        priceFilter = 'all',
        costType,
        timeOfDay = 'all',
        locationQuery = '',
        sources = const {},
        radius = 25.0,
      }) {
        eventProvider.applyFilters(
          datePreset: datePreset,
          dateFrom: dateFrom,
          dateTo: dateTo,
          priceFilter: priceFilter,
          costType: costType,
          timeOfDay: timeOfDay,
          locationQuery: locationQuery,
          sources: sources,
          radius: radius,
        );
      },
      onClear: eventProvider.clearFilters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasAny = eventProvider.activeFilterCount > 0;

    final chips = <_QuickChipData>[
      if (hasAny)
        _QuickChipData(
          label: 'Clear all',
          icon: Icons.close_rounded,
          isActive: true,
          isClearAll: true,
        ),
      _QuickChipData(
        label: _dateLabel(),
        icon: Icons.calendar_today_outlined,
        isActive: _dateActive,
      ),
      _QuickChipData(
        label: _priceLabel(),
        icon: Icons.attach_money_rounded,
        isActive: _priceActive,
      ),
      _QuickChipData(
        label: _timeLabel(),
        icon: Icons.schedule_outlined,
        isActive: _timeActive,
      ),
      _QuickChipData(
        label: _sourcesActive
            ? '${eventProvider.selectedSources.length} source${eventProvider.selectedSources.length == 1 ? '' : 's'}'
            : 'Sources',
        icon: Icons.rss_feed_rounded,
        isActive: _sourcesActive,
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return _QuickChip(
            data: chip,
            colors: colors,
            text: text,
            onTap: () {
              if (chip.isClearAll) {
                eventProvider.clearFilters();
              } else {
                _openSheet(context);
              }
            },
          );
        },
      ),
    );
  }
}

// ── Private data + chip widget ─────────────────────────────────────────────────

class _QuickChipData {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isClearAll;

  const _QuickChipData({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.isClearAll = false,
  });
}

class _QuickChip extends StatelessWidget {
  final _QuickChipData data;
  final ColorScheme colors;
  final TextTheme text;
  final VoidCallback onTap;

  const _QuickChip({
    required this.data,
    required this.colors,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data.isActive;
    final bg = isActive ? colors.primary : colors.surfaceContainerHighest;
    final fg = isActive ? colors.onPrimary : colors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd - 2,
          vertical: AppTheme.spacingXs + 1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: isActive
              ? null
              : Border.all(
                  color: colors.outline.withValues(alpha: 0.35),
                  width: AppTheme.borderDefault,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: AppTheme.iconSm - 2, color: fg),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              data.label,
              style: text.labelSmall?.copyWith(
                color: fg,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (!data.isClearAll) ...[
              const SizedBox(width: AppTheme.spacingXs - 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppTheme.iconSm - 2,
                color: fg.withValues(alpha: isActive ? 0.85 : 0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
