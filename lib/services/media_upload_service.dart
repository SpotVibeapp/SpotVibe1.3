import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Picks photos / short videos and uploads them to Firebase Storage.
///
/// Limits (enforced here, also in storage.rules):
///   photos  ≤ 6 MB
///   videos  ≤ 30 seconds and 50 MB
class MediaUploadService {
  MediaUploadService({
    ImagePicker? picker,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final ImagePicker _picker;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  static const maxVideoSeconds = 30;
  static const maxPhotoBytes = 6 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  String? get _uid => _auth.currentUser?.uid;

  Future<String?> pickImage({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return file?.path;
  }

  /// Returns a local path, or throws if the clip is longer than 30 seconds.
  Future<String?> pickVideo({required bool fromCamera}) async {
    final file = await _picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(seconds: maxVideoSeconds),
    );
    if (file == null) return null;
    if (kIsWeb) return file.path;

    final duration = await _probeDuration(file.path);
    if (duration != null && duration.inSeconds > maxVideoSeconds) {
      throw Exception(
        'Videos must be $maxVideoSeconds seconds or shorter. '
        'Trim the clip and try again.',
      );
    }
    final size = await File(file.path).length();
    if (size > maxVideoBytes) {
      throw Exception('That video is too large (max 50 MB).');
    }
    return file.path;
  }

  Future<Duration?> _probeDuration(String path) async {
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadAvatar(String localPath) {
    final uid = _requireUid();
    return _upload(
      localPath: localPath,
      refPath: 'users/$uid/avatar.jpg',
      contentType: 'image/jpeg',
      maxBytes: maxPhotoBytes,
    );
  }

  Future<String> uploadEventImage({
    required String eventId,
    required String localPath,
  }) {
    final uid = _requireUid();
    return _upload(
      localPath: localPath,
      refPath: 'events/$uid/$eventId/cover.jpg',
      contentType: 'image/jpeg',
      maxBytes: maxPhotoBytes,
    );
  }

  Future<String> uploadEventVideo({
    required String eventId,
    required String localPath,
  }) {
    final uid = _requireUid();
    return _upload(
      localPath: localPath,
      refPath: 'events/$uid/$eventId/promo.mp4',
      contentType: 'video/mp4',
      maxBytes: maxVideoBytes,
    );
  }

  String _requireUid() {
    final uid = _uid;
    if (uid == null || uid.isEmpty || uid == 'guest') {
      throw Exception('Sign in to upload photos and videos.');
    }
    return uid;
  }

  Future<String> _upload({
    required String localPath,
    required String refPath,
    required String contentType,
    required int maxBytes,
  }) async {
    if (kIsWeb) {
      throw Exception('Uploads from the web preview are not supported yet. Use the iOS or Android app.');
    }
    final file = File(localPath);
    if (!file.existsSync()) {
      throw Exception('That file is no longer on this device.');
    }
    final size = await file.length();
    if (size > maxBytes) {
      throw Exception('That file is too large.');
    }
    try {
      final ref = _storage.ref(refPath);
      await ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Storage upload failed: $e');
      if (e.code == 'object-not-found' ||
          e.code == 'bucket-not-found' ||
          e.code == 'unknown') {
        throw Exception(
          'Firebase Storage is not enabled yet. '
          'In the Firebase console open project spotvibe-cfa08 → Storage → Get started, '
          'then run: firebase deploy --only storage',
        );
      }
      throw Exception('Upload failed. Check your connection and try again.');
    } catch (e) {
      debugPrint('Storage upload failed: $e');
      throw Exception(
        'Firebase Storage is not enabled yet. '
        'In the Firebase console open project spotvibe-cfa08 → Storage → Get started, '
        'then run: firebase deploy --only storage',
      );
    }
  }
}

bool isDirectVideoUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('firebasestorage.googleapis.com') ||
      lower.contains('firebasestorage.app') ||
      lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm');
}
