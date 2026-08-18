import 'package:flutter/material.dart';
import '../../l10n/category_labels.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static const _categoryIcons = <String, IconData>{
    'All': Icons.grid_view_rounded,
    'Music': Icons.music_note_rounded,
    'Food': Icons.restaurant_rounded,
    'Arts': Icons.palette_rounded,
    'Wellness': Icons.self_improvement_rounded,
    'Social': Icons.people_rounded,
    'Community': Icons.volunteer_activism_rounded,
    'Markets': Icons.storefront_rounded,
    'Dance': Icons.nightlife_rounded,
    'Fun & Games': Icons.sports_esports_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selected;
          final catColor = categoryAccent(cat);
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: isSelected ? catColor : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcons[cat] ?? Icons.event,
                    size: AppTheme.iconSm,
                    color: isSelected ? Colors.white : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    categoryLabel(context, cat),
                    style: text.labelMedium?.copyWith(
                      color: isSelected ? Colors.white : colors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
