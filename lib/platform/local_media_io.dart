import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'picked_media_cache.dart';

/// Uploads a picked file with the mobile Storage SDK (`putFile`).
///
/// Cached bytes are only used when the path is not a real file (tests, or a
/// pick that was remembered in memory). Phone videos stay streamed from disk
/// so a 50 MB clip is not copied into the Dart heap first.
Future<void> putLocalMedia({
  required Reference ref,
  required String path,
  required SettableMetadata metadata,
}) async {
  final cached = PickedMediaCache.get(path);
  final file = File(path);
  if (cached != null && !file.existsSync()) {
    await ref.putData(cached, metadata);
    return;
  }
  if (!file.existsSync()) {
    throw Exception('That file is no longer on this device.');
  }
  await ref.putFile(file, metadata);
}

Future<int?> localMediaByteLength(String path) async {
  final cached = PickedMediaCache.get(path);
  if (cached != null) return cached.length;
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.length();
}

Future<bool> localMediaExists(String path) async {
  if (PickedMediaCache.contains(path)) return true;
  return File(path).existsSync();
}

VideoPlayerController? localVideoController(String path) {
  if (path.startsWith('blob:') ||
      path.startsWith('http://') ||
      path.startsWith('https://')) {
    return VideoPlayerController.networkUrl(Uri.parse(path));
  }
  final filePath = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
  final file = File(filePath);
  if (!file.existsSync()) return null;
  return VideoPlayerController.file(file);
}

Widget localMediaImage({
  required String path,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? error,
}) {
  final cached = PickedMediaCache.get(path);
  if (cached != null) {
    return Image.memory(
      cached,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => error ?? const SizedBox.shrink(),
    );
  }
  final filePath = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
  return Image.file(
    File(filePath),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, __, ___) => error ?? const SizedBox.shrink(),
  );
}
