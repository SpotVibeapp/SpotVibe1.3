import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../services/maps_service.dart';
import '../../theme/theme.dart';
import 'add_to_calendar_button.dart';
import 'event_share_card.dart';
import 'story_card.dart';

class QuickActionsSection extends StatelessWidget {
  final Event event;
  const QuickActionsSection({super.key, required this.event});

  Future<void> _getDirections(BuildContext context) async {
    final ok = await MapsService.openDirections(event);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps for this venue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareEvent(BuildContext context) {
    showEventShareSheet(context, event: event);
  }

  void _reportEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Report Event'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'What\'s wrong with this event?'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Thank you!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _shareStory(BuildContext context) {
    showInstagramStorySheet(
      context,
      eventId: event.id,
      eventTitle: event.title,
      eventDate: formatStoryDate(event.dateTime),
      eventLocation: event.location,
      imageUrl: event.imageUrl,
      category: event.category,
      isUserEvent: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4-icon quick action grid
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.calendar_today_rounded,
                label: 'Calendar',
                color: colors.primary,
                backgroundColor: colors.primaryContainer,
                onTap: () => _openCalendarSheet(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.navigation_rounded,
                label: 'Directions',
                color: colors.secondary,
                backgroundColor: colors.secondaryContainer,
                onTap: () => _getDirections(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                color: colors.tertiary,
                backgroundColor: colors.tertiaryContainer,
                onTap: () => _shareEvent(context),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Story',
                color: colors.secondary,
                backgroundColor: colors.secondaryContainer,
                onTap: () => _shareStory(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // Full-width Add to Calendar button
        AddToCalendarButton(
          title: event.title,
          description: event.description,
          location: event.fullLocation,
          startTime: event.dateTime,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // Report as a subtle text action
        Center(
          child: TextButton.icon(
            onPressed: () => _reportEvent(context),
            icon: Icon(Icons.flag_outlined, size: AppTheme.iconSm, color: colors.error),
            label: Text('Report this event', style: TextStyle(color: colors.error)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingXs,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openCalendarSheet(BuildContext context) {
    // Delegate to AddToCalendarButton's logic via a temporary widget context
    // by showing the same sheet. Tap the button programmatically via a builder.
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: AddToCalendarButton(
          title: event.title,
          description: event.description,
          location: event.fullLocation,
          startTime: event.dateTime,
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppTheme.iconMd + AppTheme.spacingMd,
                height: AppTheme.iconMd + AppTheme.spacingMd,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: AppTheme.iconSm, color: color),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                label,
                style: text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
