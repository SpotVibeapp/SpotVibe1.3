import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';
import '../common/fullscreen_image_viewer.dart';
import 'event_video_player.dart';

/// Renders the additional photos and videos attached to an event.
///
/// The event cover stays at the top of its detail page. When more photos are
/// available, this gallery includes that cover as the first swipeable image so
/// people can browse the complete ordered set in one place.
class EventMediaGallery extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String category;

  const EventMediaGallery({
    super.key,
    required this.imageUrls,
    required this.videoUrls,
    required this.category,
  });

  @override
  State<EventMediaGallery> createState() => _EventMediaGalleryState();
}

class _EventMediaGalleryState extends State<EventMediaGallery> {
  var _activePhoto = 0;

  @override
  void didUpdateWidget(EventMediaGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activePhoto >= widget.imageUrls.length) {
      _activePhoto = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.imageUrls;
    final videos = widget.videoUrls;
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    if (photos.length <= 1 && videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.length > 1) ...[
          Row(
            children: [
              Icon(Icons.photo_library_rounded,
                  size: AppTheme.iconMd, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                '${l10n.photos} (${photos.length})',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (index) => setState(() => _activePhoto = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => FullscreenImageViewer.open(
                        context,
                        imageUrls: photos,
                        initialIndex: index,
                      ),
                      child: _EventGalleryImage(
                        url: photos[index],
                        category: widget.category,
                      ),
                    ),
                  ),
                  // Hint that photos can be opened full-screen.
                  Positioned(
                    left: AppTheme.spacingSm,
                    bottom: AppTheme.spacingSm,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xC9000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fullscreen_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppTheme.spacingSm,
                    bottom: AppTheme.spacingSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xC9000000),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        '${_activePhoto + 1} / ${photos.length}',
                        style: text.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (photos.length <= 7) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(photos.length, (index) {
                  final active = index == _activePhoto;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
        if (photos.length > 1 && videos.isNotEmpty)
          const SizedBox(height: AppTheme.spacingLg),
        if (videos.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.video_library_rounded,
                  size: AppTheme.iconMd, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                '${l10n.videos} (${videos.length})',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          for (var index = 0; index < videos.length; index++) ...[
            if (videos.length > 1)
              Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : AppTheme.spacingMd,
                  bottom: AppTheme.spacingXs,
                ),
                child: Text(
                  '${l10n.videos} ${index + 1} / ${videos.length}',
                  style: text.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            EventVideoPlayer(
              key: ValueKey(videos[index]),
              videoUrl: videos[index],
              showTitle: false,
            ),
            if (videos.length == 1 || index == videos.length - 1)
              const SizedBox(height: AppTheme.spacingXs),
          ],
        ],
      ],
    );
  }
}

class _EventGalleryImage extends StatelessWidget {
  final String url;
  final String category;

  const _EventGalleryImage({required this.url, required this.category});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => EventImagePlaceholder(category: category),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => EventImagePlaceholder(category: category),
      placeholder: (_, __) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
