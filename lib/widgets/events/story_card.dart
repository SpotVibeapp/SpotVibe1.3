import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/event_time.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';

/// Shows the Instagram Story share bottom sheet for an event.
/// [imageUrl] and [category] are used for the background image/placeholder.
void showInstagramStorySheet(
  BuildContext context, {
  required String eventId,
  required String eventTitle,
  required String eventDate,
  required String eventLocation,
  required String imageUrl,
  required String category,
  required bool isUserEvent,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StorySheet(
      eventId: eventId,
      eventTitle: eventTitle,
      eventDate: eventDate,
      eventLocation: eventLocation,
      imageUrl: imageUrl,
      category: category,
      isUserEvent: isUserEvent,
    ),
  );
}

class _StorySheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String eventDate;
  final String eventLocation;
  final String imageUrl;
  final String category;
  final bool isUserEvent;

  const _StorySheet({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.imageUrl,
    required this.category,
    required this.isUserEvent,
  });

  @override
  State<_StorySheet> createState() => _StorySheetState();
}

class _StorySheetState extends State<_StorySheet> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isCapturing = false;

  // ── Capture the rendered story card as PNG bytes ────────────────────────
  Future<Uint8List?> _captureCard() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // pixelRatio 3 → ~1080×1920 equivalent
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ── Share via native OS share sheet ────────────────────────────────────
  Future<void> _share() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    final bytes = await _captureCard();
    if (!mounted) return;

    if (bytes == null) {
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture story card.')),
      );
      return;
    }

    try {
      // Save to a temp file and share via native sheet
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/spotvibe_story_${widget.eventId}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${widget.eventTitle} — SpotVibe',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ── Open Instagram directly (user can import from camera roll) ─────────
  Future<void> _openInstagram() async {
    final uri = Uri.parse('instagram://app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: Instagram web profile page (mobile browser redirects to app)
      await launchUrl(
        Uri.parse('https://www.instagram.com'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

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
          // ── drag handle ──────────────────────────────────────────────
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_rounded),
                const SizedBox(width: AppTheme.spacingSm),
                Text('Share to Instagram Story', style: text.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── story card preview ───────────────────────────────────────
          Center(
            child: SizedBox(
              width: 180,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: _StoryCardContent(
                    eventTitle: widget.eventTitle,
                    eventDate: widget.eventDate,
                    eventLocation: widget.eventLocation,
                    imageUrl: widget.imageUrl,
                    category: widget.category,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── action buttons ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Column(
              children: [
                // Web guard: story card can only be saved on mobile
                if (kIsWeb)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded,
                            size: AppTheme.iconSm,
                            color: colors.onSurfaceVariant),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            'Open the SpotVibe mobile app to save and share story cards.',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Save image → native share sheet (pick Instagram from list)
                  ElevatedButton.icon(
                    onPressed: _isCapturing ? null : _share,
                    icon: _isCapturing
                        ? const SizedBox(
                            width: AppTheme.iconSm,
                            height: AppTheme.iconSm,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded,
                            size: AppTheme.iconSm),
                    label: Text(
                        _isCapturing ? 'Saving...' : 'Save & Share Story Card'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  // Open Instagram directly so user can post from camera roll
                  OutlinedButton.icon(
                    onPressed: _openInstagram,
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: AppTheme.iconSm),
                    label: const Text('Open Instagram'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── The actual story card graphic ───────────────────────────────────────────
class _StoryCardContent extends StatelessWidget {
  final String eventTitle;
  final String eventDate;
  final String eventLocation;
  final String imageUrl;
  final String category;

  const _StoryCardContent({
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── background image ─────────────────────────────────────────
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorWidget: (_, __, ___) =>
                  EventImagePlaceholder(category: category),
            )
          else
            EventImagePlaceholder(category: category),

          // ── dark gradient overlay ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x99000000),
                  Color(0xDD000000),
                ],
                stops: [0.3, 0.65, 1.0],
              ),
            ),
          ),

          // ── top: SpotVibe brand watermark + category chip ──────────────
          Positioned(
            top: AppTheme.spacingMd,
            left: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: categoryAccent(category).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── bottom: event info ───────────────────────────────────────
          Positioned(
            bottom: AppTheme.spacingMd,
            left: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 10),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        eventDate,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (eventLocation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 10),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          eventLocation,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.spacingSm),
                const Text(
                  'spotvibe.app',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience helper to build a formatted date string from a [DateTime].
String formatStoryDate(DateTime dt) => formatEventWhen(dt);
