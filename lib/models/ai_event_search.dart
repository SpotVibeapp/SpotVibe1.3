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
