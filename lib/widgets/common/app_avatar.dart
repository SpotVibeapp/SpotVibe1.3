import 'package:flutter/material.dart';
import '../../platform/local_media.dart';
import '../../platform/picked_media_cache.dart';
import '../../theme/theme.dart';
import 'network_photo.dart';

class AppAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String? fallbackName;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.size = AppTheme.avatarMd,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget fallback() => Container(
          color: colors.primaryContainer,
          child: Center(
            child: Text(
              (fallbackName != null && fallbackName!.isNotEmpty)
                  ? fallbackName![0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        );

    Widget child;
    if (imageUrl.isEmpty) {
      child = fallback();
    } else if (isLocalMediaPath(imageUrl)) {
      child = localMediaImage(
        path: imageUrl,
        fit: BoxFit.cover,
        error: fallback(),
      );
    } else {
      child = NetworkPhoto(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: colors.primaryContainer,
          child: Icon(Icons.person,
              size: size * 0.5, color: colors.onPrimaryContainer),
        ),
        errorWidget: (_, __, ___) => fallback(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
