import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_event.dart';
import '../providers/auth_provider.dart';
import '../services/deep_link_service.dart';
import '../theme/theme.dart';
import '../widgets/events/add_to_calendar_button.dart';
import '../widgets/events/story_card.dart';
import '../widgets/common/app_avatar.dart';
import '../widgets/common/event_image_placeholder.dart';
import '../widgets/events/attendees_section.dart';
import '../widgets/events/comment_section.dart';
import '../widgets/events/rsvp_button.dart';

class UserEventDetailScreen extends StatelessWidget {
  final UserCreatedEvent event;
  const UserEventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return _UserEventDetailContent(event: event);
  }
}

class _UserEventDetailContent extends StatelessWidget {
  final UserCreatedEvent event;
  const _UserEventDetailContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCreator = auth.user?.id == event.creatorId;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt_rounded),
                tooltip: 'Share to Instagram Story',
                onPressed: () => showInstagramStorySheet(
                  context,
                  eventId: event.id,
                  eventTitle: event.title,
                  eventDate: formatStoryDate(event.dateTime),
                  eventLocation: event.fullLocation,
                  imageUrl: event.imageUrl,
                  category: event.category,
                  isUserEvent: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share event',
                onPressed: () => DeepLinkService.shareEvent(
                  context,
                  eventId: event.id,
                  eventTitle: event.title,
                  isUserEvent: true,
                ),
              ),
              if (isCreator) ...[
                if (event.isCreatorPro)
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded),
                    tooltip: 'Analytics',
                    onPressed: () => context.push('/event-analytics/${event.id}', extra: event),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit event',
                  onPressed: () => context.push('/edit-event/${event.id}'),
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => EventImagePlaceholder(category: event.category),
                    )
                  : EventImagePlaceholder(category: event.category),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(event.title, style: text.headlineSmall)),
                      if (event.isPremiumListing)
                        _FeaturedBadge(appColors: appColors),
                    ],
                  ),
                  if (event.isRecurring || event.isCreatorPro) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Wrap(
                      spacing: AppTheme.spacingXs,
                      children: [
                        if (event.isRecurring)
                          _RecurringBadge(label: event.recurringLabel, appColors: appColors, text: text),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingMd),

                  // Info rows
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('EEEE, MMMM d, y · h:mm a').format(event.dateTime),
                    color: colors.primary,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: [event.location, event.address, event.city, event.state]
                        .where((s) => s.isNotEmpty)
                        .join(', '),
                    color: colors.onSurfaceVariant,
                  ),
                  if (event.mapLink != null && event.mapLink!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(event.mapLink!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.map_rounded, size: AppTheme.iconSm, color: colors.primary),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              'View on Map',
                              style: text.bodySmall?.copyWith(
                                color: colors.primary,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (event.chatLink != null && event.chatLink!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(event.chatLink!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.forum_rounded, size: AppTheme.iconSm, color: colors.tertiary),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              'Join Community Chat',
                              style: text.bodySmall?.copyWith(
                                color: colors.tertiary,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingSm),
                  _InfoRow(
                    icon: Icons.attach_money_rounded,
                    label: event.costLabel,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _InfoRow(
                    icon: Icons.category_rounded,
                    label: event.category,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  AddToCalendarButton(
                    title: event.title,
                    description: event.description,
                    location: event.fullLocation,
                    startTime: event.dateTime,
                  ),
                  // Contact button (Creator Pro only)
                  if (event.isCreatorPro && event.hasContactInfo) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _ContactSection(event: event, appColors: appColors, colors: colors, text: text),
                  ],
                  const Divider(height: AppTheme.spacingXl),

                  // Organizer
                  Row(
                    children: [
                      AppAvatar(
                        imageUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(event.organizerName)}&background=6C5CE7&color=fff',
                        size: AppTheme.avatarSm,
                        fallbackName: event.organizerName,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Organizer', style: text.labelSmall),
                            Text(event.organizerName, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (isCreator) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: AppTheme.spacingXs),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, size: 12, color: colors.primary),
                              const SizedBox(width: 4),
                              Text('Admin', style: text.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: AppTheme.spacingXl),

                  // Description
                  Text('About this event', style: text.titleSmall),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(event.description, style: text.bodyMedium),

                  // Video (optional)
                  if (event.videoUrl != null && event.videoUrl!.isNotEmpty) ...[
                    const Divider(height: AppTheme.spacingXl),
                    _VideoSection(videoUrl: event.videoUrl!),
                  ],

                  const Divider(height: AppTheme.spacingXl),
                  const RsvpButton(),
                  const SizedBox(height: AppTheme.spacingLg),
                  const AttendeesSection(),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppTheme.iconSm, color: color),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(label, style: text.bodyMedium)),
      ],
    );
  }
}

class _RecurringBadge extends StatelessWidget {
  final String label;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _RecurringBadge({required this.label, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 3),
      decoration: BoxDecoration(
        color: appColors.creatorTeal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: appColors.creatorTeal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat_rounded, size: 11, color: appColors.creatorTeal),
          const SizedBox(width: 3),
          Text(
            '$label Event',
            style: text.labelSmall?.copyWith(
              color: appColors.creatorTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final UserCreatedEvent event;
  final AppColorsExtension appColors;
  final ColorScheme colors;
  final TextTheme text;
  const _ContactSection({
    required this.event,
    required this.appColors,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: appColors.creatorTeal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: appColors.creatorTeal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Organizer', style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: appColors.creatorTeal)),
          const SizedBox(height: AppTheme.spacingSm),
          if (event.contactPhone?.isNotEmpty ?? false)
            _ContactTile(icon: Icons.phone_rounded, label: event.contactPhone!, color: appColors.creatorTeal, text: text, colors: colors),
          if (event.contactWebsite?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppTheme.spacingXs),
            _ContactTile(icon: Icons.language_rounded, label: event.contactWebsite!, color: appColors.creatorTeal, text: text, colors: colors, isUrl: true),
          ],
          if (event.contactSocial?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppTheme.spacingXs),
            _ContactTile(icon: Icons.alternate_email_rounded, label: event.contactSocial!, color: appColors.creatorTeal, text: text, colors: colors),
          ],
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final TextTheme text;
  final ColorScheme colors;
  final bool isUrl;
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.text,
    required this.colors,
    this.isUrl = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUrl
          ? () async {
              final uri = Uri.tryParse(label);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Row(
        children: [
          Icon(icon, size: AppTheme.iconSm, color: color),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              label,
              style: text.bodySmall?.copyWith(
                color: isUrl ? color : colors.onSurface,
                decoration: isUrl ? TextDecoration.underline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  final AppColorsExtension appColors;
  const _FeaturedBadge({required this.appColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [appColors.proGold, appColors.proGoldLight]),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: const Text(
        'FEATURED',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

// ── Chat Section ─────────────────────────────────────────────────────────────

class _VideoSection extends StatelessWidget {
  final String videoUrl;
  const _VideoSection({required this.videoUrl});

  bool get _isYouTube {
    final host = Uri.tryParse(videoUrl)?.host ?? '';
    return host.contains('youtube.com') || host.contains('youtu.be');
  }

  bool get _isVimeo {
    final host = Uri.tryParse(videoUrl)?.host ?? '';
    return host.contains('vimeo.com');
  }

  String get _sourceName {
    if (_isYouTube) return 'YouTube';
    if (_isVimeo) return 'Vimeo';
    return 'Video';
  }

  IconData get _sourceIcon {
    if (_isYouTube) return Icons.smart_display_rounded;
    if (_isVimeo) return Icons.video_library_rounded;
    return Icons.videocam_rounded;
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Video', style: text.titleSmall),
        const SizedBox(height: AppTheme.spacingSm),
        GestureDetector(
          onTap: _open,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer,
                  colors.secondaryContainer,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Play button
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.play_arrow_rounded, color: colors.onPrimary, size: AppTheme.iconLg),
                ),
                // Source label bottom-left
                Positioned(
                  bottom: AppTheme.spacingSm,
                  left: AppTheme.spacingSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_sourceIcon, size: AppTheme.iconSm, color: colors.primary),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          _sourceName,
                          style: text.labelSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tap to open label bottom-right
                Positioned(
                  bottom: AppTheme.spacingSm,
                  right: AppTheme.spacingSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      'Tap to watch',
                      style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


