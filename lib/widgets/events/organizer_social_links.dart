import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event_social_link.dart';
import '../../services/event_analytics_service.dart';
import '../../theme/theme.dart';

/// Public, platform-specific organizer links shown on an event page.
///
/// Links are validated and normalized before storage. Tapping a button opens
/// the official platform externally; SpotVibe never signs into, reads from, or
/// posts to a social account.
class OrganizerSocialLinks extends StatelessWidget {
  final String eventId;
  final String organizerName;
  final EventSocialLinks links;

  const OrganizerSocialLinks({
    super.key,
    required this.eventId,
    required this.organizerName,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.followOrganizer,
          style: text.titleSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: [
            for (final link in links.entries)
              _SocialLinkButton(
                eventId: eventId,
                organizerName: organizerName,
                link: link,
              ),
          ],
        ),
      ],
    );
  }
}

class _SocialLinkButton extends StatelessWidget {
  final String eventId;
  final String organizerName;
  final EventSocialLink link;

  const _SocialLinkButton({
    required this.eventId,
    required this.organizerName,
    required this.link,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!context.mounted) return;

    if (opened) {
      try {
        await context.read<EventAnalyticsService>().recordClick(eventId);
      } catch (_) {
        // Analytics must never block an organizer's public link.
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.socialLinkOpenFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _platformColor(link.platform);
    return Semantics(
      button: true,
      label: 'Open ${link.platform.label} for $organizerName',
      child: OutlinedButton.icon(
        onPressed: () => _open(context),
        icon: Icon(_platformIcon(link.platform), size: AppTheme.iconSm),
        label: Text(link.platform.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
        ),
      ),
    );
  }
}

IconData _platformIcon(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.instagram:
      return Icons.camera_alt_rounded;
    case SocialPlatform.facebook:
      return Icons.facebook_rounded;
    case SocialPlatform.snapchat:
      return Icons.chat_bubble_rounded;
    case SocialPlatform.tiktok:
      return Icons.music_note_rounded;
    case SocialPlatform.youtube:
      return Icons.play_circle_fill_rounded;
  }
}

Color _platformColor(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.instagram:
      return const Color(0xFFE1306C);
    case SocialPlatform.facebook:
      return const Color(0xFF1877F2);
    case SocialPlatform.snapchat:
      return const Color(0xFFF59E0B);
    case SocialPlatform.tiktok:
      return const Color(0xFF16B8C3);
    case SocialPlatform.youtube:
      return const Color(0xFFFF3333);
  }
}
