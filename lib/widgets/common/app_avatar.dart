import 'package:cached_network_image/cached_network_image.dart';
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: colors.primaryContainer,
            child: Icon(Icons.person, size: size * 0.5, color: colors.onPrimaryContainer),
          ),
          errorWidget: (_, __, ___) => Container(
            color: colors.primaryContainer,
            child: Center(
              child: Text(
                (fallbackName ?? '?')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
