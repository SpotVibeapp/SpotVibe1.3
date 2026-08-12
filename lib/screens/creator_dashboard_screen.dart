import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_event.dart';
import '../providers/user_events_provider.dart';
import '../theme/theme.dart';

/// The Premium Creator Dashboard — shown when a Creator Pro member views
/// their events. Surfaces personalized stat sentences and per-event metrics
/// for every Creator Pro event the user owns.
class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserEventsProvider>().loadMyEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserEventsProvider>();
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    final proEvents = provider.events.where((e) => e.isCreatorPro).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Gradient SliverAppBar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [appColors.creatorTeal, appColors.creatorTealLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd, AppTheme.spacingLg, AppTheme.spacingMd, AppTheme.spacingSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.campaign_rounded, color: Colors.white, size: AppTheme.iconSm),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              'CREATOR PRO',
                              style: text.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          'Your Dashboard',
                          style: text.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: appColors.creatorTeal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Create Event',
                color: Colors.white,
                onPressed: () => context.push('/create-event'),
              ),
            ],
          ),

          // ── Body ────────────────────────────────────────────────────────────
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (proEvents.isEmpty)
            SliverFillRemaining(
              child: _EmptyDashboard(colors: colors, appColors: appColors, text: text),
            )
          else ...[
            // Aggregate summary across all pro events
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingXs,
                ),
                child: _AggregateSummaryRow(events: proEvents, colors: colors, appColors: appColors, text: text),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingLg, AppTheme.spacingMd, AppTheme.spacingSm,
                ),
                child: Text(
                  'This Week',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // One insight card per Creator Pro event
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    0,
                    AppTheme.spacingMd,
                    index == proEvents.length - 1 ? AppTheme.spacingXl : AppTheme.spacingMd,
                  ),
                  child: _EventInsightCard(
                    event: proEvents[index],
                    colors: colors,
                    appColors: appColors,
                    text: text,
                  ),
                ),
                childCount: proEvents.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Aggregate Summary Row ──────────────────────────────────────────────────────

class _AggregateSummaryRow extends StatelessWidget {
  final List<UserCreatedEvent> events;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _AggregateSummaryRow({
    required this.events,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final totalSearches = events.fold(0, (sum, e) => sum + e.analyticsSearchImpressions);
    final totalViews = events.fold(0, (sum, e) => sum + e.analyticsViews);
    final totalRsvps = events.fold(0, (sum, e) => sum + e.analyticsClicks);

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
            child: _AggregateStat(
              icon: Icons.search_rounded,
              label: 'Searches',
              value: totalSearches,
              color: colors.primary,
              text: text,
              colors: colors,
            ),
          ),
          _Divider(colors: colors),
          Expanded(
            child: _AggregateStat(
              icon: Icons.visibility_rounded,
              label: 'Views',
              value: totalViews,
              color: appColors.creatorTeal,
              text: text,
              colors: colors,
            ),
          ),
          _Divider(colors: colors),
          Expanded(
            child: _AggregateStat(
              icon: Icons.how_to_reg_rounded,
              label: 'RSVPs',
              value: totalRsvps,
              color: appColors.proGold,
              text: text,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme colors;
  const _Divider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: colors.outlineVariant.withValues(alpha: 0.4),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
    );
  }
}

class _AggregateStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final TextTheme text;
  final ColorScheme colors;
  const _AggregateStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.text,
    required this.colors,
  });

  String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: AppTheme.iconSm, color: color),
        const SizedBox(height: AppTheme.spacingXs),
        Text(_format(value), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
        Text(label, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

// ── Per-Event Insight Card ─────────────────────────────────────────────────────

/// Shows the three personalized stat sentences plus a drill-down button.
class _EventInsightCard extends StatelessWidget {
  final UserCreatedEvent event;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _EventInsightCard({
    required this.event,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Event title header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm + 4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appColors.creatorTeal.withValues(alpha: 0.12), appColors.creatorTealLight.withValues(alpha: 0.06)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.isRecurring) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat_rounded, size: 11, color: appColors.creatorTeal),
                            const SizedBox(width: 3),
                            Text(
                              event.recurringLabel,
                              style: text.labelSmall?.copyWith(color: appColors.creatorTeal, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 3),
                  decoration: BoxDecoration(
                    color: appColors.creatorTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Text(
                    event.category,
                    style: text.labelSmall?.copyWith(
                      color: appColors.creatorTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Personalized insight sentences
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InsightSentence(
                  icon: Icons.search_rounded,
                  iconColor: colors.primary,
                  richParts: [
                    const TextSpan(text: '"'),
                    TextSpan(text: event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: '" appeared in '),
                    TextSpan(
                      text: '${event.analyticsSearchImpressions} searches',
                      style: TextStyle(fontWeight: FontWeight.w800, color: colors.primary),
                    ),
                    const TextSpan(text: ' this week.'),
                  ],
                  text: text,
                  colors: colors,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _InsightSentence(
                  icon: Icons.visibility_rounded,
                  iconColor: appColors.creatorTeal,
                  richParts: [
                    TextSpan(
                      text: '${event.analyticsViews} people',
                      style: TextStyle(fontWeight: FontWeight.w800, color: appColors.creatorTeal),
                    ),
                    const TextSpan(text: ' viewed the details.'),
                  ],
                  text: text,
                  colors: colors,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _InsightSentence(
                  icon: Icons.how_to_reg_rounded,
                  iconColor: appColors.proGold,
                  richParts: [
                    TextSpan(
                      text: '${event.analyticsClicks} people',
                      style: TextStyle(fontWeight: FontWeight.w800, color: appColors.proGold),
                    ),
                    const TextSpan(text: " RSVP'd."),
                  ],
                  text: text,
                  colors: colors,
                ),
              ],
            ),
          ),

          // Footer: deep-dive button
          InkWell(
            onTap: () => context.push('/event-analytics/${event.id}', extra: event),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLarge)),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm + 2,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.25))),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: AppTheme.iconSm, color: appColors.creatorTeal),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    'Full Analytics',
                    style: text.labelMedium?.copyWith(
                      color: appColors.creatorTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: AppTheme.iconSm + 4, color: appColors.creatorTeal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insight Sentence Row ───────────────────────────────────────────────────────

class _InsightSentence extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<TextSpan> richParts;
  final TextTheme text;
  final ColorScheme colors;
  const _InsightSentence({
    required this.icon,
    required this.iconColor,
    required this.richParts,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: AppTheme.iconSm, color: iconColor),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: text.bodyMedium?.copyWith(color: colors.onSurface, height: 1.4),
              children: richParts,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty Dashboard State ──────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _EmptyDashboard({required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [appColors.creatorTeal, appColors.creatorTealLight]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: AppTheme.iconLg),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text('No Creator Pro Events Yet', style: text.headlineSmall),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Create your first Creator Pro event to start tracking searches, views, and RSVPs.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            FilledButton.icon(
              onPressed: () => context.push('/create-event'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a Pro Event'),
              style: FilledButton.styleFrom(
                backgroundColor: appColors.creatorTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
