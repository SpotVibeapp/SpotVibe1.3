import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Media waiting to be saved with an event. A local path is rendered from the
/// device; a remote URL is an already-uploaded item from an existing event.
class EventMediaDraftItem {
  final String source;
  final bool isLocal;
  final String label;
  final VoidCallback onRemove;

  const EventMediaDraftItem({
    required this.source,
    required this.isLocal,
    required this.label,
    required this.onRemove,
  });
}

enum EventMediaKind { photo, video }

/// Compact editor for the additional media attached to an event. The cover is
/// managed separately, so [items] contains only extra photos or all videos.
class EventMediaEditor extends StatelessWidget {
  final EventMediaKind kind;
  final String title;
  final String subtitle;
  final String emptyLabel;
  final String libraryLabel;
  final String cameraLabel;
  final List<EventMediaDraftItem> items;
  final VoidCallback? onLibrary;
  final VoidCallback? onCamera;

  const EventMediaEditor({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.emptyLabel,
    required this.libraryLabel,
    required this.cameraLabel,
    required this.items,
    required this.onLibrary,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isPhoto = kind == EventMediaKind.photo;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPhoto ? Icons.photo_library_rounded : Icons.video_library_rounded,
                color: colors.primary,
                size: AppTheme.iconMd,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(subtitle, style: text.labelSmall),
          const SizedBox(height: AppTheme.spacingMd),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: items
                  .map(
                    (item) => _DraftMediaTile(
                      item: item,
                      kind: kind,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLibrary,
                  icon: Icon(
                    isPhoto
                        ? Icons.add_photo_alternate_rounded
                        : Icons.video_library_rounded,
                    size: AppTheme.iconSm,
                  ),
                  label: Text(libraryLabel),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: Icon(
                    isPhoto ? Icons.photo_camera_rounded : Icons.videocam_rounded,
                    size: AppTheme.iconSm,
                  ),
                  label: Text(cameraLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftMediaTile extends StatelessWidget {
  final EventMediaDraftItem item;
  final EventMediaKind kind;

  const _DraftMediaTile({required this.item, required this.kind});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPhoto = kind == EventMediaKind.photo;

    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: isPhoto
                ? _DraftPhoto(source: item.source, isLocal: item.isLocal)
                : Container(
                    color: colors.primaryContainer,
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: colors.primary,
                      size: 34,
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                color: const Color(0xAA000000),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Material(
              color: colors.error,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: item.onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 15, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftPhoto extends StatelessWidget {
  final String source;
  final bool isLocal;

  const _DraftPhoto({required this.source, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (isLocal && !kIsWeb) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
