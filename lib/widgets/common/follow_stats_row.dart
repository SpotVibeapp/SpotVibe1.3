import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A horizontal row showing follower and following counts.
/// Used on the profile screen to surface social graph stats.
class FollowStatsRow extends StatelessWidget {
  final int followerCount;
  final int followingCount;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const FollowStatsRow({
    super.key,
    required this.followerCount,
    required this.followingCount,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatCell(
          count: followerCount,
          label: 'Followers',
          onTap: onFollowersTap,
          colors: colors,
          text: text,
        ),
        Container(
          height: 32,
          width: AppTheme.borderDefault,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          color: colors.outlineVariant,
        ),
        _StatCell(
          count: followingCount,
          label: 'Following',
          onTap: onFollowingTap,
          colors: colors,
          text: text,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;
  final ColorScheme colors;
  final TextTheme text;

  const _StatCell({
    required this.count,
    required this.label,
    required this.onTap,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCount(count),
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
