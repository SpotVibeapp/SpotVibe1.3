import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Maps an English category key (stored as data) to its localized label.
/// Categories are persisted in English so that data stays stable regardless
/// of the user's language; this helper localizes only the display.
String categoryLabel(BuildContext context, String key) {
  final l = AppLocalizations.of(context)!;
  switch (key) {
    case 'All':
      return l.catAll;
    case 'Music':
      return l.catMusic;
    case 'Food':
      return l.catFood;
    case 'Food & Drink':
      return l.catFoodDrink;
    case 'Arts':
      return l.catArts;
    case 'Sports':
      return l.catSports;
    case 'Tech':
      return l.catTech;
    case 'Community':
      return l.catCommunity;
    case 'Family':
      return l.catFamily;
    case 'Wellness':
      return l.catWellness;
    case 'Social':
      return l.catSocial;
    case 'Markets':
      return l.catMarkets;
    case 'Dance':
      return l.catDance;
    case 'Fun & Games':
      return l.catFunGames;
    case 'Health':
      return l.catHealth;
    case 'Other':
      return l.catOther;
    case 'Nightlife':
      return l.catNightlife;
    case 'Comedy':
      return l.catComedy;
    case 'Fitness':
      return l.catFitness;
    case 'Outdoor':
      return l.catOutdoor;
    case 'Film':
      return l.catFilm;
    default:
      return key;
  }
}
