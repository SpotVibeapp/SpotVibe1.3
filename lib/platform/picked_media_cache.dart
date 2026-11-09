import 'package:flutter/foundation.dart';

/// In-memory bytes for files the user just picked.
///
/// Browsers have no app sandbox path that [File] can read. The picker returns
/// a blob URL; we keep the bytes under that same string so previews
/// ([Image.memory]) and Storage uploads (`putData`) can use them. Phone builds
/// still upload with `putFile` and only consult this cache when bytes were
/// stored explicitly.
class PickedMediaCache {
  PickedMediaCache._();

  static final Map<String, Uint8List> _bytes = {};

  static void put(String path, Uint8List bytes) {
    if (path.isEmpty) return;
    _bytes[path] = bytes;
  }

  static Uint8List? get(String path) => _bytes[path];

  static bool contains(String path) => _bytes.containsKey(path);

  static void remove(String path) => _bytes.remove(path);

  @visibleForTesting
  static void clear() => _bytes.clear();
}

/// True when [path] is a device file or a browser pick, not a remote URL.
bool isLocalMediaPath(String path) {
  if (path.isEmpty) return false;
  if (PickedMediaCache.contains(path)) return true;
  if (path.startsWith('blob:') || path.startsWith('file://')) return true;
  if (path.startsWith('http://') || path.startsWith('https://')) return false;
  if (path.startsWith('assets/')) return false;
  // Absolute filesystem paths from image_picker on Android/iOS.
  if (!kIsWeb && path.startsWith('/')) return true;
  return false;
}
