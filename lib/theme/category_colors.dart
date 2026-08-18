import 'package:flutter/material.dart';

import 'theme.dart';

/// Per-category accent color used across cards, chips, and imagery.
///
/// Categories are stored as stable English keys (see `category_labels.dart`);
/// this maps each to a lively, consistent accent and falls back to the brand
/// violet for anything unknown. Shared by the event card, the category chip
/// row, and the event image scrim so the whole app feels coordinated.
Color categoryAccent(String category) {
  switch (category.toLowerCase()) {
    case 'music':
      return const Color(0xFF6C5CE7); // violet
    case 'food':
    case 'food & drink':
      return const Color(0xFFE17055); // coral
    case 'arts':
      return const Color(0xFFE84393); // magenta
    case 'sports':
    case 'social':
      return const Color(0xFF0984E3); // blue
    case 'tech':
      return const Color(0xFF0FA3C8); // cyan
    case 'community':
    case 'family':
      return const Color(0xFF00CEC9); // teal-cyan
    case 'wellness':
    case 'fitness':
    case 'health':
      return const Color(0xFF00B894); // green-teal
    case 'markets':
      return const Color(0xFFF39C12); // amber
    case 'dance':
      return const Color(0xFFFD79A8); // pink
    case 'fun & games':
      return const Color(0xFF5F27CD); // deep violet
    case 'film':
      return const Color(0xFFB03A5B); // rose
    case 'outdoor':
      return const Color(0xFF27AE60); // green
    case 'comedy':
      return const Color(0xFFE8A838); // gold
    case 'nightlife':
      return const Color(0xFF8E44AD); // purple
    default:
      return AppTheme.brandViolet;
  }
}
