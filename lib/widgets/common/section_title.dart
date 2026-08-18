import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Section header with a small colored accent bar before the title. Shared
/// across the event detail, practical info, comments, and attendees sections
/// so every heading carries the same lively, category-matched pop while the
/// text keeps the standard high-contrast title style.
class SectionTitle extends StatelessWidget {
  final String title;

  /// Accent color for the little bar (usually the event's category color).
  final Color accent;

  const SectionTitle({super.key, required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(title, style: text.titleMedium)),
      ],
    );
  }
}
