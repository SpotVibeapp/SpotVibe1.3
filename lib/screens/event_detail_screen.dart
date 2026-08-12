import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/event_provider.dart';
import '../services/deep_link_service.dart';
import '../theme/theme.dart';
import '../widgets/events/claim_venue_banner.dart';
import '../widgets/common/app_avatar.dart';
import '../widgets/common/event_image_placeholder.dart';
import '../widgets/common/source_badge.dart';
import '../widgets/common/user_action_sheet.dart';
import '../widgets/events/attendees_section.dart';
import '../widgets/events/comment_section.dart';
import '../widgets/events/practical_details_section.dart';
import '../widgets/events/quick_actions_section.dart';
import '../widgets/events/rsvp_button.dart';
import '../widgets/events/similar_events_section.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return _DetailContent(event: event, eventIndex: 0);
  }
}

class _DetailContent extends StatelessWidget {
  final Event event;
  final int eventIndex;
  const _DetailContent({required this.event, required this.eventIndex});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share event',
                onPressed: () => DeepLinkService.shareEvent(
                  context,
                  eventId: event.id,
                  eventTitle: event.title,
                  isUserEvent: false,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: appColors.shimmer),
                errorWidget: (_, __, ___) => EventImagePlaceholder(category: event.category),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryAndCost(event: event, appColors: appColors),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(event.title, style: text.headlineSmall),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat('EEEE, MMMM d, yyyy').format(event.dateTime),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: AppTheme.spacingSm),
                        _InfoRow(
                          icon: Icons.access_time_rounded,
                          label: DateFormat('h:mm a').format(event.dateTime),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: AppTheme.spacingSm),
                        _InfoRow(icon: Icons.location_on_rounded, label: event.fullLocation),
                        if (event.cost != null && event.cost! > 0) ...[
                          const SizedBox(height: AppTheme.spacingSm),
                          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: AppTheme.spacingSm),
                          _InfoRow(
                            icon: Icons.confirmation_number_rounded,
                            label: event.costLabel,
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingSm),
                        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingSm),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Icon(Icons.link_rounded, size: AppTheme.iconSm, color: colors.primary),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                'Found on',
                                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            SourceBadge(source: event.source),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Quick actions: Calendar, Directions, Share, Story + Report
                  QuickActionsSection(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Practical details: Weather, Parking, Duration, Age, Accessibility
                  PracticalDetailsSection(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  _CounterRow(event: event, eventIndex: eventIndex),
                  const SizedBox(height: AppTheme.spacingLg),
                  const RsvpButton(),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text('About this Event', style: text.titleMedium),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(event.description, style: text.bodyMedium),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text('Organizer', style: text.titleMedium),
                  const SizedBox(height: AppTheme.spacingSm),
                  _OrganizerRow(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  ClaimVenueBanner(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  const AttendeesSection(),
                  const SizedBox(height: AppTheme.spacingLg),
                  SimilarEventsSection(currentEvent: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  const CommentSection(),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryAndCost extends StatelessWidget {
  final Event event;
  final AppColorsExtension appColors;
  const _CategoryAndCost({required this.event, required this.appColors});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(event.category, style: text.labelMedium?.copyWith(color: colors.onPrimaryContainer, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: event.isFree ? appColors.eventCostBadge : colors.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            event.costLabel,
            style: text.labelMedium?.copyWith(
              color: event.isFree ? colors.surface : colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, size: AppTheme.iconSm, color: colors.primary),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(label, style: text.bodyMedium)),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  final Event event;
  final int eventIndex;
  const _CounterRow({required this.event, required this.eventIndex});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    return Row(
      children: [
        Expanded(
          child: _CounterButton(
            icon: event.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: '${event.bookmarkedCount} Bookmarked',
            isActive: event.isBookmarked,
            onTap: () => eventProvider.toggleBookmark(eventIndex),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _CounterButton(
            icon: event.isInterested ? Icons.star_rounded : Icons.star_border_rounded,
            label: '${event.interestedCount} Interested',
            isActive: event.isInterested,
            onTap: () => eventProvider.toggleInterested(eventIndex),
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _CounterButton({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm, horizontal: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isActive ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isActive ? colors.primary : colors.outlineVariant.withValues(alpha: 0.3),
            width: isActive ? AppTheme.borderSelected : AppTheme.borderDefault,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppTheme.iconMd, color: isActive ? colors.primary : colors.onSurfaceVariant),
            const SizedBox(width: AppTheme.spacingSm),
            Flexible(child: Text(label, style: text.labelMedium?.copyWith(color: isActive ? colors.primary : colors.onSurfaceVariant, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _OrganizerRow extends StatelessWidget {
  final Event event;
  const _OrganizerRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final auth = context.read<AuthProvider>();
    final follow = context.read<FollowProvider>();
    const organizerId = 'organizer_1';
    return Row(
      children: [
        AppAvatar(imageUrl: event.organizerAvatarUrl, size: AppTheme.avatarMd, fallbackName: event.organizerName),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.organizerName, style: text.titleSmall),
              Text('Organizer', style: text.labelSmall),
            ],
          ),
        ),
        if (auth.isLoggedIn)
          IconButton(
            onPressed: () => UserActionSheet.show(
              context,
              userName: event.organizerName,
              isFollowing: follow.isFollowing(auth.user!.id, organizerId),
              onToggleFollow: () {
                final nowFollowing = follow.toggleFollow(auth.user!.id, organizerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(nowFollowing
                        ? 'Following ${event.organizerName}'
                        : 'Unfollowed ${event.organizerName}'),
                  ),
                );
              },
              onBlock: () {
                auth.blockUser(organizerId);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked')));
              },
              onReport: () => _showReportDialog(context, auth),
            ),
            icon: Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
          ),
      ],
    );
  }

  void _showReportDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Reason for reporting...'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              auth.reportUser('organizer_1', controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}


