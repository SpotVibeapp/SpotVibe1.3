/// A single city that the event-search assistant may query.
class AiSearchLocation {
  final String city;
  final String state;

  const AiSearchLocation({required this.city, this.state = ''});

  String get displayName => state.isEmpty ? city : '$city, $state';

  String get normalizedKey =>
      '${city.trim().toLowerCase()}|${state.trim().toUpperCase()}';

  factory AiSearchLocation.fromMap(Map<String, dynamic> data) {
    final city = (data['city'] as String? ?? '').trim();
    final state = (data['state'] as String? ?? '').trim().toUpperCase();
    return AiSearchLocation(city: city, state: state);
  }
}

// Terms that describe broad discovery categories rather than a performer,
// venue, or title. They are intentionally not sent as Ticketmaster's `keyword`
// because that endpoint matches event names literally and can hide valid real
// listings already constrained by city/category/date.
const _broadDiscoveryWords = <String>{
  'a',
  'an',
  'and',
  'art',
  'arts',
  'at',
  'comedy',
  'concert',
  'concerts',
  'dance',
  'do',
  'drink',
  'event',
  'events',
  'family',
  'film',
  'find',
  'food',
  'for',
  'friendly',
  'happening',
  'happenings',
  'health',
  'in',
  'live',
  'looking',
  'me',
  'movie',
  'movies',
  'music',
  'near',
  'outdoor',
  'outdoors',
  'show',
  'shows',
  'sport',
  'sports',
  'tech',
  'the',
  'things',
  'this',
  'to',
  'today',
  'tomorrow',
  'week',
  'weekend',
  'wellness',
  'what',
};

/// Safe, structured search intent returned by the authenticated AI function.
///
/// This deliberately contains filters only — never event names, dates, venues,
/// availability claims, or recommendations. The app fetches every displayed
/// event separately from SpotVibe and Ticketmaster.
class AiEventSearchPlan {
  static const supportedDatePresets = <String>{
    'all',
    'today',
    'tomorrow',
    'this_weekend',
    'this_week',
  };
  static const supportedCategories = <String>{
    'Music',
    'Food',
    'Arts',
    'Sports',
    'Tech',
    'Community',
    'Family',
    'Health',
    'Fun & Games',
    'Other',
    'Social',
    'Comedy',
    'Outdoors',
    'Film',
    'Wellness',
    'Dance',
  };

  final String searchText;
  final String? category;
  final String datePreset;
  final AiSearchLocation? requestedLocation;

  /// Returns a provider keyword only when the AI plan contains a distinctive
  /// term (for example an artist, venue, or event title). Generic requests
  /// such as "concerts in El Paso" are better served by the real city,
  /// category, and date filters than by Ticketmaster's literal name-only
  /// keyword matching.
  String? get specificSearchText {
    final raw = searchText.trim();
    if (raw.isEmpty) return null;

    final locationWords = <String>{
      if (requestedLocation != null) ...[
        ...requestedLocation!.city
            .toLowerCase()
            .split(RegExp(r'[^a-z0-9]+')),
        requestedLocation!.state.toLowerCase(),
      ],
    }..removeWhere((word) => word.isEmpty);
    final meaningful = raw
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .where((word) => !_broadDiscoveryWords.contains(word))
        .where((word) => !locationWords.contains(word))
        .toList();

    return meaningful.isEmpty ? null : meaningful.join(' ');
  }

  const AiEventSearchPlan({
    required this.searchText,
    required this.category,
    required this.datePreset,
    required this.requestedLocation,
  });

  factory AiEventSearchPlan.fromMap(Map<String, dynamic> data) {
    String cleanText(Object? value, int maximum) {
      if (value is! String) return '';
      final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      return cleaned.length <= maximum
          ? cleaned
          : cleaned.substring(0, maximum);
    }

    final city = cleanText(data['requestedCity'], 80);
    final rawState = data['requestedState'] is String
        ? (data['requestedState'] as String).trim().toUpperCase()
        : '';
    final state = RegExp(r'^[A-Z]{2}$').hasMatch(rawState) ? rawState : '';
    final rawPreset = cleanText(data['datePreset'], 32);
    final rawCategory = cleanText(data['category'], 60);

    return AiEventSearchPlan(
      searchText: cleanText(data['searchText'], 120),
      category: supportedCategories.contains(rawCategory) ? rawCategory : null,
      datePreset:
          supportedDatePresets.contains(rawPreset) ? rawPreset : 'all',
      requestedLocation:
          city.isEmpty ? null : AiSearchLocation(city: city, state: state),
    );
  }
}
