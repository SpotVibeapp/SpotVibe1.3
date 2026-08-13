import 'package:flutter/material.dart';
import '../models/user_event.dart';
import '../theme/theme.dart';

/// Analytics dashboard for a single Premium event.
/// Shows views, saves, and click-throughs with a visual bar chart.
class CreatorAnalyticsScreen extends StatelessWidget {
  final UserCreatedEvent event;
  const CreatorAnalyticsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Analytics'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTheme.spacingSm),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appColors.creatorTeal, appColors.creatorTealLight],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.campaign_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'CREATOR PRO',
                  style: text.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Event title card
          _EventSummaryCard(event: event, colors: colors, appColors: appColors, text: text),
          const SizedBox(height: AppTheme.spacingMd),

          // Search impressions sentence — the "hero" stat
          _SearchInsightCard(event: event, colors: colors, appColors: appColors, text: text),
          const SizedBox(height: AppTheme.spacingMd),

          // Stat tiles row
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.visibility_rounded,
                  label: 'Views',
                  value: event.analyticsViews,
                  color: appColors.creatorTeal,
                  text: text,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _StatTile(
                  icon: Icons.bookmark_rounded,
                  label: 'Saves',
                  value: event.analyticsSaves,
                  color: appColors.proGold,
                  text: text,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _StatTile(
                  icon: Icons.touch_app_rounded,
                  label: 'Clicks',
                  value: event.analyticsClicks,
                  color: colors.tertiary,
                  text: text,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Bar chart
          _AnalyticsBarChart(event: event, colors: colors, appColors: appColors, text: text),
          const SizedBox(height: AppTheme.spacingMd),

          // Engagement rate
          _EngagementCard(event: event, colors: colors, appColors: appColors, text: text),
          const SizedBox(height: AppTheme.spacingMd),

          // Tips section
          _TipsCard(colors: colors, appColors: appColors, text: text),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

// ── Event Summary ──────────────────────────────────────────────────────────────

class _EventSummaryCard extends StatelessWidget {
  final UserCreatedEvent event;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _EventSummaryCard({required this.event, required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppTheme.spacingXs),
                Text(event.category, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                if (event.isRecurring) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded, size: 12, color: appColors.creatorTeal),
                      const SizedBox(width: 4),
                      Text(
                        '${event.recurringLabel} recurring',
                        style: text.labelSmall?.copyWith(color: appColors.creatorTeal, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appColors.creatorTeal.withValues(alpha: 0.15), appColors.creatorTealLight.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(Icons.bar_chart_rounded, color: appColors.creatorTeal, size: AppTheme.iconLg),
          ),
        ],
      ),
    );
  }
}

// ── Search Insight Card ────────────────────────────────────────────────────────

/// The "hero" sentence card: "Your event appeared in X searches this week."
class _SearchInsightCard extends StatelessWidget {
  final UserCreatedEvent event;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _SearchInsightCard({required this.event, required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.creatorTeal.withValues(alpha: 0.12), appColors.creatorTealLight.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: appColors.creatorTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: appColors.creatorTeal.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded, color: appColors.creatorTeal, size: AppTheme.iconMd),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: text.bodyMedium?.copyWith(color: colors.onSurface, height: 1.4),
                    children: [
                      const TextSpan(text: '"'),
                      TextSpan(text: event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: '" appeared in '),
                      TextSpan(
                        text: '${event.analyticsSearchImpressions.toString()} searches',
                        style: TextStyle(fontWeight: FontWeight.w800, color: appColors.creatorTeal),
                      ),
                      const TextSpan(text: ' this week.'),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Search impressions',
                  style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Tile ──────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final TextTheme text;
  final ColorScheme colors;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd, horizontal: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppTheme.iconSm + 2, color: color),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            value.toString(),
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color),
          ),
          Text(label, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _AnalyticsBarChart extends StatelessWidget {
  final UserCreatedEvent event;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _AnalyticsBarChart({required this.event, required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    final maxVal = [event.analyticsSearchImpressions, event.analyticsViews, event.analyticsSaves, event.analyticsClicks]
        .fold(1, (prev, e) => e > prev ? e : prev);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Overview', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Bar(label: 'Searches', value: event.analyticsSearchImpressions, maxValue: maxVal, color: colors.primary, text: text, colors: colors),
              const SizedBox(width: AppTheme.spacingSm),
              _Bar(label: 'Views', value: event.analyticsViews, maxValue: maxVal, color: appColors.creatorTeal, text: text, colors: colors),
              const SizedBox(width: AppTheme.spacingSm),
              _Bar(label: 'Saves', value: event.analyticsSaves, maxValue: maxVal, color: appColors.proGold, text: text, colors: colors),
              const SizedBox(width: AppTheme.spacingSm),
              _Bar(label: 'Clicks', value: event.analyticsClicks, maxValue: maxVal, color: colors.tertiary, text: text, colors: colors),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final TextTheme text;
  final ColorScheme colors;
  const _Bar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? value / maxValue : 0.0;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(value.toString(), style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            height: 100 * ratio.clamp(0.05, 1.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSmall)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Engagement Rate ────────────────────────────────────────────────────────────

class _EngagementCard extends StatelessWidget {
  final UserCreatedEvent event;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _EngagementCard({required this.event, required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    final engagementRate = event.analyticsViews > 0
        ? ((event.analyticsSaves + event.analyticsClicks) / event.analyticsViews * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.creatorTeal.withValues(alpha: 0.1), appColors.creatorTealLight.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: appColors.creatorTeal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: appColors.creatorTeal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.trending_up_rounded, color: appColors.creatorTeal, size: AppTheme.iconMd),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Engagement Rate', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  'Saves + clicks divided by views',
                  style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${engagementRate.toStringAsFixed(1)}%',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: appColors.creatorTeal),
          ),
        ],
      ),
    );
  }
}

// ── Tips ───────────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _TipsCard({required this.colors, required this.appColors, required this.text});

  static const _tips = [
    'Add a compelling cover photo to increase views by up to 40%',
    'Events posted Tuesday–Thursday get 25% more saves on average',
    'Use your featured placement on your highest-traffic event each week',
    'Enable recurring to build a loyal repeat audience automatically',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: AppTheme.iconSm, color: appColors.proGold),
              const SizedBox(width: AppTheme.spacingXs),
              Text('Creator Tips', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.circle, size: 6, color: appColors.creatorTeal),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(tip, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
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
