import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Shimmer placeholders that match [EventCard] while the feed loads.
class EventFeedSkeleton extends StatefulWidget {
  final int count;

  const EventFeedSkeleton({super.key, this.count = 4});

  @override
  State<EventFeedSkeleton> createState() => _EventFeedSkeletonState();
}

class _EventFeedSkeletonState extends State<EventFeedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          itemCount: widget.count,
          itemBuilder: (_, __) => _SkeletonCard(t: _pulse.value),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double t;

  const _SkeletonCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final base = appColors.shimmer;
    final highlight = Color.lerp(base, colors.surface, 0.45)!;
    final fill = Color.lerp(base, highlight, t)!;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(fill, width: 72, height: 16),
                const SizedBox(height: AppTheme.spacingSm),
                _bar(fill, width: double.infinity, height: 18),
                const SizedBox(height: AppTheme.spacingXs),
                _bar(fill, width: 180, height: 14),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    _bar(fill, width: 64, height: 28, radius: 20),
                    const SizedBox(width: AppTheme.spacingSm),
                    _bar(fill, width: 64, height: 28, radius: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double width, required double height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
