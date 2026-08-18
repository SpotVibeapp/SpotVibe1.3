import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/event.dart';
import '../../services/deep_link_service.dart';
import '../../services/share_analytics_service.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';

/// Opens the share options bottom sheet for [event].
/// [analytics] is optional; pass a shared instance to record share actions.
void showEventShareSheet(
  BuildContext context, {
  required Event event,
  ShareAnalyticsService? analytics,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareSheet(event: event, analytics: analytics),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final Event event;
  final ShareAnalyticsService? analytics;

  const _ShareSheet({required this.event, this.analytics});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isCapturingCard = false;
  bool _isBuildingLink = false;

  Event get _event => widget.event;

  // ── helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) =>
      DateFormat('EEE, MMM d · h:mm a').format(dt);

  Future<String> _buildShareLink() async {
    return DeepLinkService.eventLink(_event.id);
  }

  String _buildShareMessage(String link) {
    final date = _formatDate(_event.dateTime);
    final venue = _event.location.isNotEmpty ? _event.location : _event.city;
    return 'Check out ${_event.title}!\n\n'
        '📅 $date\n'
        '📍 $venue\n\n'
        '$link';
  }

  // ── capture card ──────────────────────────────────────────────────────────

  Future<Uint8List?> _captureCard() async {
    try {
      // Let the card render before capturing
      await Future.delayed(const Duration(milliseconds: 80));
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ── share as image card ───────────────────────────────────────────────────

  Future<void> _shareCard() async {
    if (_isCapturingCard) return;
    setState(() => _isCapturingCard = true);

    final bytes = await _captureCard();
    if (!mounted) return;

    if (bytes == null) {
      setState(() => _isCapturingCard = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture share card.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/spotvibe_share_${_event.id}.png');
      await file.writeAsBytes(bytes);

      // Attach a plain-text subject so apps that accept both show the title
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${_event.title} — SpotVibe',
        text: 'Check out ${_event.title} on SpotVibe!',
      );
      widget.analytics?.recordShare(
        eventId: _event.id,
        category: _event.category,
        method: ShareMethod.card,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing failed. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingCard = false);
    }
  }

  // ── share with link (rich text + deep link) ───────────────────────────────

  Future<void> _shareWithLink() async {
    if (_isBuildingLink) return;
    setState(() => _isBuildingLink = true);

    try {
      final link = await _buildShareLink();
      if (!mounted) return;
      final message = _buildShareMessage(link);
      await Share.share(message, subject: '${_event.title} — SpotVibe');
      widget.analytics?.recordShare(
        eventId: _event.id,
        category: _event.category,
        method: ShareMethod.link,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate share link.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuildingLink = false);
    }
  }

  // ── copy link to clipboard ────────────────────────────────────────────────

  Future<void> _copyLink() async {
    final link = DeepLinkService.eventLink(_event.id);
    await Clipboard.setData(ClipboardData(text: link));
    widget.analytics?.recordShare(
      eventId: _event.id,
      category: _event.category,
      method: ShareMethod.clipboard,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            AppTheme.spacingMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── drag handle ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingSm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                Icon(Icons.ios_share_rounded,
                    size: AppTheme.iconMd, color: colors.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text('Share Event', style: text.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── share card preview ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: AspectRatio(
              aspectRatio: 1.91, // Open Graph / Twitter card ratio
              child: RepaintBoundary(
                key: _cardKey,
                child: _ShareCardGraphic(event: _event),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Column(
              children: [
                if (kIsWeb)
                  // Web: image capture not available; show info tile
                  _WebShareTile(colors: colors, text: text)
                else
                  // Share as image card
                  ElevatedButton.icon(
                    onPressed: _isCapturingCard ? null : _shareCard,
                    icon: _isCapturingCard
                        ? const SizedBox(
                            width: AppTheme.iconSm,
                            height: AppTheme.iconSm,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.image_rounded,
                            size: AppTheme.iconSm),
                    label: Text(
                        _isCapturingCard ? 'Preparing...' : 'Share as Card'),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, AppTheme.buttonHeight),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingSm),

                // Share with link (rich text)
                OutlinedButton.icon(
                  onPressed: _isBuildingLink ? null : _shareWithLink,
                  icon: _isBuildingLink
                      ? SizedBox(
                          width: AppTheme.iconSm,
                          height: AppTheme.iconSm,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.primary),
                        )
                      : const Icon(Icons.link_rounded, size: AppTheme.iconSm),
                  label: Text(
                      _isBuildingLink ? 'Building link...' : 'Share with Link'),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, AppTheme.buttonHeight),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Copy link tile
                _CopyLinkTile(
                  eventId: _event.id,
                  colors: colors,
                  text: text,
                  onCopy: _copyLink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share card graphic (1.91:1 — Open Graph / Twitter standard)
// ─────────────────────────────────────────────────────────────────────────────

class _ShareCardGraphic extends StatelessWidget {
  final Event event;

  const _ShareCardGraphic({required this.event});

  String _formatDate(DateTime dt) =>
      DateFormat('EEE, MMM d · h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final venue =
        event.location.isNotEmpty ? event.location : event.fullLocation;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── background image ─────────────────────────────────────────────
          if (event.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: event.imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorWidget: (_, __, ___) =>
                  EventImagePlaceholder(category: event.category),
            )
          else
            EventImagePlaceholder(category: event.category),

          // ── dark gradient — left-to-right overlay for text legibility ────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color(0x00000000),
                  Color(0x99000000),
                  Color(0xEE000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── content ──────────────────────────────────────────────────────
          Positioned(
            left: AppTheme.spacingMd,
            top: AppTheme.spacingMd,
            bottom: AppTheme.spacingMd,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SpotVibe brand pill (gradient to match the logo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandViolet.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'SpotVibe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),

                // Category chip in the event's accent color
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXs + 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: categoryAccent(event.category).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    event.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),

                // Event title
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXs),

                // Date row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 11),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatDate(event.dateTime),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Venue row
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXs),

                // Cost badge — green for free, brand gradient for paid
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXs + 2, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: event.isFree
                            ? null
                            : AppTheme.brandGradient,
                        color: event.isFree
                            ? const Color(0xFF00B894)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.costLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── bottom-right watermark ────────────────────────────────────────
          const Positioned(
            right: AppTheme.spacingSm,
            bottom: AppTheme.spacingSm,
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                'spotvibe.app',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CopyLinkTile extends StatelessWidget {
  final String eventId;
  final ColorScheme colors;
  final TextTheme text;
  final VoidCallback onCopy;

  const _CopyLinkTile({
    required this.eventId,
    required this.colors,
    required this.text,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final link = DeepLinkService.eventLink(eventId);
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.link_rounded,
                size: AppTheme.iconSm, color: colors.primary),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                link,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Icon(Icons.copy_rounded,
                size: AppTheme.iconSm, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

class _WebShareTile extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme text;

  const _WebShareTile({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_iphone_rounded,
              size: AppTheme.iconSm, color: colors.onSurfaceVariant),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'Open the SpotVibe mobile app to share the event card as an image.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
