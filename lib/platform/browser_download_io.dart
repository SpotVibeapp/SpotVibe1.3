import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Phones share the file through the system sheet. The web app downloads it.
Future<void> downloadBytes({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) {
  return Share.shareXFiles([
    XFile.fromData(bytes, mimeType: mimeType, name: filename),
  ]);
}
