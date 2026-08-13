import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_event.dart';
import '../providers/user_events_provider.dart';
import '../theme/theme.dart';
import '../widgets/user_events/user_event_card.dart';
import '../data/pricing.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
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
    final text = Theme.of(context).textTheme;

    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    final hasProEvents = provider.events.any((e) => e.isCreatorPro);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          if (hasProEvents)
            IconButton(
              icon: const Icon(Icons.dashboard_rounded),
              tooltip: 'Creator Dashboard',
              onPressed: () => context.push('/creator-dashboard'),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create Event',
            onPressed: () => context.push('/create-event'),
          ),
        ],
      ),
      body: _buildBody(provider, colors, appColors, text),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-event'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Event'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
    );
  }

  Widget _buildBody(UserEventsProvider provider, ColorScheme colors, AppColorsExtension appColors, TextTheme text) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: AppTheme.iconLg * 1.5, color: colors.error),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Something went wrong', style: text.titleMedium),
            const SizedBox(height: AppTheme.spacingXs),
            Text(provider.error!, style: text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingMd),
            FilledButton(
              onPressed: () => context.read<UserEventsProvider>().loadMyEvents(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.events.isEmpty) {
      return _EmptyMyEventsState(onCreateTap: () => context.push('/create-event'));
    }

    final hasAnyCreatorPro = provider.events.any((e) => e.isCreatorPro);

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: provider.events.length + (hasAnyCreatorPro ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, index) {
        // Show Premium upgrade banner as the last item if user has no pro events
        if (!hasAnyCreatorPro && index == provider.events.length) {
          return _CreatorProUpgradeBanner(colors: colors, appColors: appColors, text: text);
        }
        final event = provider.events[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserEventCard(
              event: event,
              onTap: () => context.push('/user-event/${event.id}'),
              onEdit: () => context.push('/edit-event/${event.id}'),
              onDelete: () => _confirmDelete(context, event),
            ),
            if (event.isCreatorPro) ...[
              const SizedBox(height: AppTheme.spacingXs),
              _EventAnalyticsRow(event: event, appColors: appColors, text: text),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserCreatedEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "${event.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => ctx.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<UserEventsProvider>().deleteEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Event deleted.' : 'Failed to delete event.'),
            backgroundColor: success ? null : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ── Creator Pro Upgrade Banner ─────────────────────────────────────────────────

class _CreatorProUpgradeBanner extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _CreatorProUpgradeBanner({required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [appColors.creatorTeal.withValues(alpha: 0.1), appColors.creatorTealLight.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: appColors.creatorTeal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [appColors.creatorTeal, appColors.creatorTealLight]),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: AppTheme.iconMd),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Recurring events, analytics & custom branding — start a $kPremiumTrialLabel',
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: appColors.creatorTeal),
          ],
        ),
      ),
    );
  }
}

// ── Per-event analytics quick row ─────────────────────────────────────────────

class _EventAnalyticsRow extends StatelessWidget {
  final UserCreatedEvent event;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _EventAnalyticsRow({required this.event, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event-analytics/${event.id}', extra: event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingXs),
        decoration: BoxDecoration(
          color: appColors.creatorTeal.withValues(alpha: 0.07),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLarge)),
        ),
        child: Row(
          children: [
            Icon(Icons.bar_chart_rounded, size: AppTheme.iconSm, color: appColors.creatorTeal),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              '${event.analyticsViews} views · ${event.analyticsSaves} saves · ${event.analyticsClicks} clicks',
              style: text.labelSmall?.copyWith(color: appColors.creatorTeal, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('Analytics →', style: text.labelSmall?.copyWith(color: appColors.creatorTeal, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyMyEventsState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyMyEventsState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_rounded, size: AppTheme.iconLg * 1.2, color: colors.primary),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text('No Events Yet', style: text.headlineSmall),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Create your first event and share it with your community.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Event'),
            ),
          ],
        ),
      ),
    );
  }
}
