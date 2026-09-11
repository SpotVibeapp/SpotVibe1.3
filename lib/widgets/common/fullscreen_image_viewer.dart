import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A full-screen, swipeable, pinch-to-zoom photo viewer.
///
/// Open it with [FullscreenImageViewer.open] from any thumbnail's `onTap`. It
/// handles both bundled `assets/` images and remote URLs (cached), lets people
/// pinch/pan to zoom, double-tap to zoom, and swipe left/right between photos.
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  /// Pushes the viewer as an opaque full-screen route.
  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    if (imageUrls.isEmpty) return Future.value();
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => FullscreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex.clamp(0, imageUrls.length - 1),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late final List<TransformationController> _transformers;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _transformers = List.generate(
      widget.imageUrls.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final t in _transformers) {
      t.dispose();
    }
    super.dispose();
  }

  void _handleDoubleTap(int index) {
    final controller = _transformers[index];
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      controller.value = Matrix4.identity()..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photos = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onDoubleTap: () => _handleDoubleTap(index),
                child: InteractiveViewer(
                  transformationController: _transformers[index],
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: _FullImage(url: photos[index]),
                  ),
                ),
              );
            },
          ),
          // Top bar: close button + counter.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (photos.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xC9000000),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_index + 1} / ${photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  final String url;
  const _FullImage({required this.url});

  @override
  Widget build(BuildContext context) {
    Widget error() => const Center(
          child: Icon(Icons.broken_image_rounded,
              color: Colors.white38, size: 64),
        );

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => error(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      ),
      errorWidget: (_, __, ___) => error(),
    );
  }
}
