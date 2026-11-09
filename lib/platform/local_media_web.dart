import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'picked_media_cache.dart';

/// Uploads picked bytes with `putData`. Browsers cannot pass a [File] to
/// Cloud Storage, but the object path and content type stay the same as the
/// phone app so both clients share one bucket.
Future<void> putLocalMedia({
  required Reference ref,
  required String path,
  required SettableMetadata metadata,
}) async {
  final bytes = PickedMediaCache.get(path);
  if (bytes == null) {
    throw Exception('That file is no longer available. Pick it again.');
  }
  await ref.putData(bytes, metadata);
}

Future<int?> localMediaByteLength(String path) async =>
    PickedMediaCache.get(path)?.length;

Future<bool> localMediaExists(String path) async =>
    PickedMediaCache.contains(path) || path.startsWith('blob:');

VideoPlayerController? localVideoController(String path) {
  if (path.startsWith('blob:') ||
      path.startsWith('http://') ||
      path.startsWith('https://')) {
    return VideoPlayerController.networkUrl(Uri.parse(path));
  }
  return null;
}

Widget localMediaImage({
  required String path,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? error,
}) {
  final fallback = error ?? const SizedBox.shrink();
  final cached = PickedMediaCache.get(path);
  if (cached != null) {
    return Image.memory(
      cached,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  if (path.startsWith('blob:') ||
      path.startsWith('http://') ||
      path.startsWith('https://')) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return fallback;
}
