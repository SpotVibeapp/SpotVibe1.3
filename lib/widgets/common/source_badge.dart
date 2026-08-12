import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../theme/theme.dart';

class SourceBadge extends StatelessWidget {
  final EventSource source;
  final bool compact;

  const SourceBadge({super.key, required this.source, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = source.brandColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTheme.spacingXs + 2 : AppTheme.spacingSm,
        vertical: compact ? 3 : AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            source.icon,
            size: compact ? 10 : AppTheme.iconSm,
            color: Colors.white,
          ),
          if (!compact) ...[
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              source.displayName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
