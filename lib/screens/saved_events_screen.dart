import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/events/event_card.dart';

class SavedEventsScreen extends StatelessWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final saved = eventProvider.events.where((e) => e.isBookmarked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Events'),
        actions: [
          if (saved.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    '${saved.length}',
                    style: text.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: eventProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : saved.isEmpty
              ? EmptyStateView(
                  variant: EmptyStateVariant.noSavedEvents,
                  icon: Icons.bookmark_border_rounded,
                  title: 'No saved events yet',
                  subtitle:
                      'Tap the bookmark icon on any event you want to revisit. They\'ll all show up here.',
                  actionLabel: 'Explore Events',
                  onAction: () => context.go('/'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
                  itemCount: saved.length,
                  itemBuilder: (context, index) {
                    final event = saved[index];
                    final globalIndex = eventProvider.indexOfEvent(event.id);
                    return EventCard(
                      event: event,
                      onTap: () =>
                          context.push('/event/${event.id}', extra: event),
                      onBookmark: () {
                        if (globalIndex >= 0) {
                          eventProvider.toggleBookmark(globalIndex);
                        }
                      },
                      onInterested: () {
                        if (globalIndex >= 0) {
                          eventProvider.toggleInterested(globalIndex);
                        }
                      },
                      distanceMiles: eventProvider.distanceFor(event),
                    );
                  },
                ),
    );
  }
}
