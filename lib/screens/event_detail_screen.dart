import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/event_time.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/event_provider.dart';
import '../repositories/moderation_repository.dart';
import '../services/deep_link_service.dart';
import '../services/maps_service.dart';
import '../theme/category_colors.dart';
import '../theme/theme.dart';
import '../services/event_analytics_service.dart';
import '../widgets/events/claim_venue_banner.dart';
import '../widgets/events/event_page_ad.dart';
import '../widgets/common/app_avatar.dart';
import '../widgets/common/event_image_placeholder.dart';
import '../widgets/common/guided_tour.dart';
import '../widgets/common/section_title.dart';
import '../widgets/common/source_badge.dart';
import '../widgets/common/user_action_sheet.dart';
import '../widgets/events/attendees_section.dart';
import '../widgets/events/comment_section.dart';
import '../widgets/events/practical_details_section.dart';
import '../widgets/events/get_tickets_button.dart';
import '../widgets/events/quick_actions_section.dart';
import '../widgets/events/rsvp_button.dart';
import '../widgets/events/similar_events_section.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // Guided-tour target keys (stable across rebuilds).
  final GlobalKey _tourKeyShare = GlobalKey();
  final GlobalKey _tourKeyRsvp = GlobalKey();
  final GlobalKey _tourKeyCounters = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<EventAnalyticsService>().recordView(
              widget.event.id,
              viewerId: context.read<AuthProvider>().user?.id,
            );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DetailContent(
      event: widget.event,
      eventIndex: 0,
      shareKey: _tourKeyShare,
      rsvpKey: _tourKeyRsvp,
      countersKey: _tourKeyCounters,
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Event event;
  final int eventIndex;
  final GlobalKey? shareKey;
  final GlobalKey? rsvpKey;
  final GlobalKey? countersKey;
  const _DetailContent({
    required this.event,
    required this.eventIndex,
    this.shareKey,
    this.rsvpKey,
    this.countersKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final catColor = categoryAccent(event.category);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            actions: [
              IconButton(
                key: shareKey,
                icon: const Icon(Icons.share_rounded),
                tooltip: l10n.shareEventTooltip,
                onPressed: () => DeepLinkService.shareEvent(
                  context,
                  eventId: event.id,
                  eventTitle: event.title,
                  isUserEvent: false,
                ),
              ),
              if (context.read<AuthProvider>().isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: l10n.adminRemoveEvent,
                  onPressed: () => _removeEvent(context, event),
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
                  if (event.isFeaturedThisWeek) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [appColors.proGold, appColors.proGoldLight]),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        l10n.featuredThisWeek,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
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
                          label: formatEventWhen(event.dateTime),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: AppTheme.spacingSm),
                        GestureDetector(
                          onTap: () => MapsService.openDirections(event),
                          child: _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: event.fullLocation,
                          ),
                        ),
                        if (event.cost != null && event.cost! > 0) ...[
                          const SizedBox(height: AppTheme.spacingSm),
                          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: AppTheme.spacingSm),
                          _InfoRow(
                            icon: Icons.confirmation_number_rounded,
                            label: event.costLabel,
                          ),
                        ],
                        if (SourceBadge.isHonest(event.source)) ...[
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
                                child: Icon(Icons.confirmation_number_rounded, size: AppTheme.iconSm, color: colors.primary),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  l10n.tickets,
                                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              SourceBadge(source: event.source),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  GetTicketsButton(event: event),
                  if (event.sourceUrl != null && event.sourceUrl!.isNotEmpty)
                    const SizedBox(height: AppTheme.spacingSm),
                  QuickActionsSection(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  PracticalDetailsSection(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  _CounterRow(key: countersKey, event: event, eventIndex: eventIndex),
                  const SizedBox(height: AppTheme.spacingLg),
                  RsvpButton(key: rsvpKey),
                  const SizedBox(height: AppTheme.spacingLg),
                  SectionTitle(title: l10n.aboutThisEvent, accent: catColor),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(event.description, style: text.bodyMedium),
                  const SizedBox(height: AppTheme.spacingLg),
                  SectionTitle(title: l10n.organizer, accent: catColor),
                  const SizedBox(height: AppTheme.spacingSm),
                  _OrganizerRow(event: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  ClaimVenueBanner(event: event),
                  if (event.showsAds) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    const EventPageAd(),
                  ],
                  const SizedBox(height: AppTheme.spacingLg),
                  AttendeesSection(accent: catColor),
                  const SizedBox(height: AppTheme.spacingLg),
                  SimilarEventsSection(currentEvent: event),
                  const SizedBox(height: AppTheme.spacingLg),
                  CommentSection(
                    accent: catColor,
                    canModerate: context.read<AuthProvider>().isAdmin,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
        ],
          ),
          GuidedTour(
            tourId: 'event_detail',
            steps: [
              TourStep(
                targetKey: rsvpKey ?? GlobalKey(),
                title: l10n.tourEvent1Title,
                description: l10n.tourEvent1Body,
              ),
              TourStep(
                targetKey: countersKey ?? GlobalKey(),
                title: l10n.tourEvent2Title,
                description: l10n.tourEvent2Body,
              ),
              TourStep(
                targetKey: shareKey ?? GlobalKey(),
                title: l10n.tourEvent3Title,
                description: l10n.tourEvent3Body,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Admin-only: confirm and permanently remove this event from the feed.
  Future<void> _removeEvent(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminRemoveEventTitle),
        content: Text(l10n.adminRemoveEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<ModerationRepository>().deleteEvent(event.id);
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminEventRemoved)),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
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
    final catColor = categoryAccent(event.category);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(event.category, style: text.labelMedium?.copyWith(color: catColor, fontWeight: FontWeight.w600)),
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
  const _CounterRow({super.key, required this.event, required this.eventIndex});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _CounterButton(
            icon: event.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            label: l10n.bookmarkedCountLabel(event.bookmarkedCount),
            isActive: event.isBookmarked,
            onTap: () => eventProvider.toggleBookmark(eventIndex),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _CounterButton(
            icon: event.isInterested ? Icons.star_rounded : Icons.star_border_rounded,
            label: l10n.interestedCountLabel(event.interestedCount),
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.organizer, style: text.labelSmall),
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
                        ? l10n.followingName(event.organizerName)
                        : l10n.unfollowedName(event.organizerName)),
                  ),
                );
              },
              onBlock: () {
                auth.blockUser(organizerId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.userBlocked)));
              },
              onReport: () => _showReportDialog(context, auth),
            ),
            icon: Icon(Icons.more_horiz_rounded, color: colors.onSurfaceVariant),
          ),
      ],
    );
  }

  void _showReportDialog(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reportUser),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: l10n.reasonForReporting), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              auth.reportUser('organizer_1', controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
            },
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
  }
}
