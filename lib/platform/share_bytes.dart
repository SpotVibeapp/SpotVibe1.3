import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares PNG bytes without writing them to the phone's filesystem first.
///
/// `share_plus` accepts [XFile.fromData] on Android, iOS, and the web. On the
/// web it uses the Web Share API when the browser allows it, and downloads
/// the file otherwise.
Future<void> sharePngBytes(
  Uint8List bytes, {
  required String filename,
  String? subject,
  String? text,
}) {
  return Share.shareXFiles(
    [
      XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: filename.endsWith('.png') ? filename : '$filename.png',
      ),
    ],
    subject: subject,
    text: text,
  );
}
