import '../models/ai_event_search.dart';

/// Curated nearby-city options for the optional road-trip search.
///
/// The assistant never claims a precise driving duration. These are only
/// searched after a person actively enables the up-to-four-hour road-trip
/// option, and every displayed event is still fetched from a real source.
const _elPasoRoadTrips = <AiSearchLocation>[
  AiSearchLocation(city: 'Las Cruces', state: 'NM'),
  AiSearchLocation(city: 'Alamogordo', state: 'NM'),
  AiSearchLocation(city: 'Ruidoso', state: 'NM'),
  AiSearchLocation(city: 'Albuquerque', state: 'NM'),
];

/// Returns product-curated road-trip destinations for [city]/[state].
///
/// The initial list focuses on SpotVibe's El Paso launch region. A person can
/// always name a different city directly in their assistant request.
List<AiSearchLocation> roadTripDestinationsFor({
  required String city,
  required String state,
}) {
  final normalizedCity = city.trim().toLowerCase();
  final normalizedState = state.trim().toUpperCase();
  if ((normalizedCity == 'el paso' ||
          normalizedCity.startsWith('el paso,') ||
          normalizedCity.startsWith('el paso tx')) &&
      (normalizedState.isEmpty || normalizedState == 'TX')) {
    return List.unmodifiable(_elPasoRoadTrips);
  }
  return const [];
}
