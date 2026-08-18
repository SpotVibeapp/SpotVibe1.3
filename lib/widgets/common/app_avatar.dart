import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

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
    } else if (!kIsWeb &&
        (imageUrl.startsWith('/') || imageUrl.startsWith('file:'))) {
      final path = imageUrl.startsWith('file:')
          ? Uri.parse(imageUrl).toFilePath()
          : imageUrl;
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    } else {
      child = CachedNetworkImage(
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
