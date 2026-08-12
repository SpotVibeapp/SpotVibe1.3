import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color subtleText;
  final Color cardHighlight;
  final Color shimmer;
  final Color eventCostBadge;
  final Color proGold;
  final Color proGoldLight;
  final Color creatorTeal;
  final Color creatorTealLight;

  const AppColorsExtension({
    required this.success,
    required this.warning,
    required this.danger,
    required this.subtleText,
    required this.cardHighlight,
    required this.shimmer,
    required this.eventCostBadge,
    required this.proGold,
    required this.proGoldLight,
    required this.creatorTeal,
    required this.creatorTealLight,
  });

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? subtleText,
    Color? cardHighlight,
    Color? shimmer,
    Color? eventCostBadge,
    Color? proGold,
    Color? proGoldLight,
    Color? creatorTeal,
    Color? creatorTealLight,
  }) =>
      AppColorsExtension(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        subtleText: subtleText ?? this.subtleText,
        cardHighlight: cardHighlight ?? this.cardHighlight,
        shimmer: shimmer ?? this.shimmer,
        eventCostBadge: eventCostBadge ?? this.eventCostBadge,
        proGold: proGold ?? this.proGold,
        proGoldLight: proGoldLight ?? this.proGoldLight,
        creatorTeal: creatorTeal ?? this.creatorTeal,
        creatorTealLight: creatorTealLight ?? this.creatorTealLight,
      );

  @override
  AppColorsExtension lerp(covariant ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      cardHighlight: Color.lerp(cardHighlight, other.cardHighlight, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
      eventCostBadge: Color.lerp(eventCostBadge, other.eventCostBadge, t)!,
      proGold: Color.lerp(proGold, other.proGold, t)!,
      proGoldLight: Color.lerp(proGoldLight, other.proGoldLight, t)!,
      creatorTeal: Color.lerp(creatorTeal, other.creatorTeal, t)!,
      creatorTealLight: Color.lerp(creatorTealLight, other.creatorTealLight, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 20.0;

  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  static const double buttonHeight = 48.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 44.0;
  static const double avatarLg = 72.0;

  static const double opacityDisabled = 0.38;
  static const double opacityHint = 0.6;
  static const double opacityOverlay = 0.54;

  static const double borderDefault = 1.0;
  static const double borderSelected = 2.0;

  static final ThemeData lightTheme = _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C5CE7),
      brightness: Brightness.light,
    ),
    appColors: const AppColorsExtension(
      success: Color(0xFF00B894),
      warning: Color(0xFFFDAA3D),
      danger: Color(0xFFE17055),
      subtleText: Color(0xFF636E72),
      cardHighlight: Color(0xFFF8F7FF),
      shimmer: Color(0xFFEEECF9),
      eventCostBadge: Color(0xFF00CEC9),
      proGold: Color(0xFFE8A838),
      proGoldLight: Color(0xFFF5C842),
      creatorTeal: Color(0xFF00B4A2),
      creatorTealLight: Color(0xFF00CEC9),
    ),
  );

  static final ThemeData darkTheme = _buildTheme(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C5CE7),
      brightness: Brightness.dark,
    ),
    appColors: const AppColorsExtension(
      success: Color(0xFF55EFC4),
      warning: Color(0xFFFECA57),
      danger: Color(0xFFFF7675),
      subtleText: Color(0xFFB2BEC3),
      cardHighlight: Color(0xFF1E1B2E),
      shimmer: Color(0xFF2D2845),
      eventCostBadge: Color(0xFF81ECEC),
      proGold: Color(0xFFE8A838),
      proGoldLight: Color(0xFFF5C842),
      creatorTeal: Color(0xFF00CEC9),
      creatorTealLight: Color(0xFF81ECEC),
    ),
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required AppColorsExtension appColors,
  }) {
    final textTheme = _buildTextTheme(colorScheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textTheme.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
        labelStyle: textTheme.labelMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: appColors.subtleText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),
      extensions: [appColors],
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      bodyLarge: base.bodyLarge?.copyWith(color: colorScheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: colorScheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      labelMedium: base.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      labelSmall: base.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
