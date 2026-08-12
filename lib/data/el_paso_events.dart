import '../models/event.dart';

/// Downtown El Paso — used as the default feed bias when GPS is unavailable.
const double kElPasoLat = 31.7619;
const double kElPasoLng = -106.4850;
const String kElPasoCity = 'El Paso';
const String kElPasoState = 'TX';
const String kElPasoZip = '79901';

/// Seed version written to `meta/event_seed`. Bump to re-upsert curated docs.
const int kElPasoSeedVersion = 1;

String _avatar(String name, String hex) =>
    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}'
    '&size=200&background=$hex&color=fff';

/// Curated El Paso / borderland events at real venues.
/// Dates are relative to [midnight] so they stay in the upcoming window.
List<Event> buildElPasoSeedEvents(DateTime midnight) {
  Event ep({
    required String id,
    required String title,
    required String description,
    required int days,
    required int hours,
    required String location,
    required String address,
    required String zip,
    required String category,
    required String organizer,
    required String avatarHex,
    required String imageUrl,
    required double lat,
    required double lng,
    double? cost,
    EventSource source = EventSource.local,
    String? sourceUrl,
    int bookmarked = 0,
    int interested = 0,
  }) {
    return Event(
      id: id,
      title: title,
      description: description,
      dateTime: midnight.add(Duration(days: days, hours: hours)),
      location: location,
      address: address,
      city: kElPasoCity,
      state: kElPasoState,
      zipCode: zip,
      cost: cost,
      imageUrl: imageUrl,
      category: category,
      organizerName: organizer,
      organizerAvatarUrl: _avatar(organizer, avatarHex),
      bookmarkedCount: bookmarked,
      interestedCount: interested,
      latitude: lat,
      longitude: lng,
      source: source,
      sourceUrl: sourceUrl,
    );
  }

  return [
    ep(
      id: 'evt_ep_001',
      title: 'El Paso Chihuahuas Home Game',
      description:
          'Catch the Chihuahuas at Southwest University Park in the heart of downtown. '
          'Gates open an hour before first pitch. Family-friendly, with local food stands '
          'and a view of the Franklin Mountains over the outfield.',
      days: 2,
      hours: 18,
      location: 'Southwest University Park',
      address: '1 Ballpark Plaza',
      zip: '79901',
      category: 'Sports',
      organizer: 'El Paso Chihuahuas',
      avatarHex: 'C41E3A',
      imageUrl:
          'https://images.unsplash.com/photo-1566577739112-5180d4bf9390?q=80&w=800&auto=format&fit=crop',
      lat: 31.7601,
      lng: -106.4933,
      cost: 18,
      source: EventSource.ticketmaster,
      sourceUrl: 'https://www.milb.com/el-paso',
      bookmarked: 214,
      interested: 580,
    ),
    ep(
      id: 'evt_ep_002',
      title: 'Live at El Paso County Coliseum',
      description:
          'A night of live music at the County Coliseum. Doors at 6:30 PM, show at 8. '
          'Parking on site. All ages unless otherwise posted at the box office.',
      days: 6,
      hours: 20,
      location: 'El Paso County Coliseum',
      address: '4100 E Paisano Dr',
      zip: '79905',
      category: 'Music',
      organizer: 'El Paso Live',
      avatarHex: '6C5CE7',
      imageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=800&auto=format&fit=crop',
      lat: 31.7654,
      lng: -106.4425,
      cost: 45,
      source: EventSource.ticketmaster,
      bookmarked: 389,
      interested: 1024,
    ),
    ep(
      id: 'evt_ep_003',
      title: 'Plaza Theatre Classic Film Night',
      description:
          'A restored 1930s movie palace on Pioneer Plaza screens a classic with organ prelude. '
          'Arrive early to see the interior. Concessions in the lobby.',
      days: 4,
      hours: 19,
      location: 'Plaza Theatre',
      address: '125 Pioneer Plaza',
      zip: '79901',
      category: 'Arts',
      organizer: 'Plaza Theatre Performing Arts Center',
      avatarHex: 'E17055',
      imageUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=800&auto=format&fit=crop',
      lat: 31.7588,
      lng: -106.4875,
      cost: 12,
      source: EventSource.local,
      bookmarked: 96,
      interested: 248,
    ),
    ep(
      id: 'evt_ep_004',
      title: 'Downtown Farmers Market at San Jacinto Plaza',
      description:
          'Saturday market in the plaza: chile, pecans, pan dulce, produce, and local makers. '
          'Live acoustic music mid-morning. Bring bags and cash for some vendors.',
      days: 1,
      hours: 9,
      location: 'San Jacinto Plaza',
      address: '114 W Mills Ave',
      zip: '79901',
      category: 'Markets',
      organizer: 'Downtown El Paso',
      avatarHex: '00B894',
      imageUrl:
          'https://images.unsplash.com/photo-1488459716781-31db52582fe9?q=80&w=800&auto=format&fit=crop',
      lat: 31.7591,
      lng: -106.4883,
      source: EventSource.facebook,
      bookmarked: 167,
      interested: 412,
    ),
    ep(
      id: 'evt_ep_005',
      title: 'Sunset at Scenic Drive Overlook',
      description:
          'Casual meetup at the Scenic Drive overlook for sunset over downtown, Juárez, and the valley. '
          'Street parking is limited — carpool if you can. Bring water; no facilities at the pull-off.',
      days: 1,
      hours: 19,
      location: 'Scenic Drive Overlook',
      address: 'Scenic Dr',
      zip: '79902',
      category: 'Social',
      organizer: 'El Paso Outdoor Club',
      avatarHex: 'E1306C',
      imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?q=80&w=800&auto=format&fit=crop',
      lat: 31.7965,
      lng: -106.4780,
      source: EventSource.instagram,
      bookmarked: 203,
      interested: 541,
    ),
    ep(
      id: 'evt_ep_006',
      title: 'UTEP Miners Football — Sun Bowl',
      description:
          'Miners home game at the Sun Bowl on the UTEP campus. Student and general tickets at the gate '
          'and online. Tailgating lots open three hours before kickoff.',
      days: 8,
      hours: 18,
      location: 'Sun Bowl Stadium',
      address: '2701 Sun Bowl Dr',
      zip: '79968',
      category: 'Sports',
      organizer: 'UTEP Athletics',
      avatarHex: 'FF6600',
      imageUrl:
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=800&auto=format&fit=crop',
      lat: 31.7733,
      lng: -106.5078,
      cost: 25,
      source: EventSource.ticketmaster,
      bookmarked: 276,
      interested: 733,
    ),
    ep(
      id: 'evt_ep_007',
      title: 'Franklin Mountains Sunrise Hike',
      description:
          'Guided moderate hike at Tom Mays Unit of Franklin Mountains State Park. '
          'State park day-use fee required. Closed-toe shoes, 2 liters of water, and sun protection.',
      days: 3,
      hours: 6,
      location: 'Franklin Mountains State Park — Tom Mays',
      address: '1331 McKelligon Canyon Rd',
      zip: '79930',
      category: 'Wellness',
      organizer: 'Franklin Mountains State Park',
      avatarHex: '00CEC9',
      imageUrl:
          'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=800&auto=format&fit=crop',
      lat: 31.8967,
      lng: -106.5220,
      cost: 5,
      source: EventSource.google,
      bookmarked: 142,
      interested: 318,
    ),
    ep(
      id: 'evt_ep_008',
      title: 'Hueco Tanks Bouldering Day',
      description:
          'Day trip to Hueco Tanks State Park & Historic Site — world-class bouldering and pictographs. '
          'North Mountain is self-guided on weekdays; other areas need a tour. Reserve park entry in advance.',
      days: 9,
      hours: 8,
      location: 'Hueco Tanks State Park & Historic Site',
      address: '6900 Hueco Tanks Rd No. 1',
      zip: '79938',
      category: 'Sports',
      organizer: 'Hueco Tanks Friends',
      avatarHex: 'E17055',
      imageUrl:
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800&auto=format&fit=crop',
      lat: 31.9168,
      lng: -106.0430,
      cost: 7,
      source: EventSource.local,
      bookmarked: 188,
      interested: 421,
    ),
    ep(
      id: 'evt_ep_009',
      title: 'El Paso Museum of Art — New Exhibition Opening',
      description:
          'Opening reception for a new exhibition at EPMA next to San Jacinto Plaza. '
          'Museum admission is free. Gallery talk at 6:30 PM.',
      days: 5,
      hours: 17,
      location: 'El Paso Museum of Art',
      address: '1 Arts Festival Plaza',
      zip: '79901',
      category: 'Arts',
      organizer: 'El Paso Museum of Art',
      avatarHex: 'A29BFE',
      imageUrl:
          'https://images.unsplash.com/photo-1531913223931-b0d3198229ee?q=80&w=800&auto=format&fit=crop',
      lat: 31.7585,
      lng: -106.4889,
      source: EventSource.instagram,
      bookmarked: 87,
      interested: 231,
    ),
    ep(
      id: 'evt_ep_010',
      title: 'Abraham Chavez Theatre — Symphony Night',
      description:
          'The El Paso Symphony Orchestra at Abraham Chavez Theatre in the convention center complex. '
          'Formal attire optional. Box office opens 90 minutes before curtain.',
      days: 11,
      hours: 19,
      location: 'Abraham Chavez Theatre',
      address: '1 Civic Center Plaza',
      zip: '79901',
      category: 'Music',
      organizer: 'El Paso Symphony Orchestra',
      avatarHex: '6C5CE7',
      imageUrl:
          'https://images.unsplash.com/photo-1507838153414-b4b713384a76?q=80&w=800&auto=format&fit=crop',
      lat: 31.7580,
      lng: -106.4915,
      cost: 35,
      source: EventSource.ticketmaster,
      bookmarked: 154,
      interested: 390,
    ),
    ep(
      id: 'evt_ep_011',
      title: 'Food Truck Friday — Union Plaza',
      description:
          'Rotating food trucks, a DJ, and patio seating in Union Plaza downtown. '
          'Free to walk in. Bring cash for some trucks. Family-friendly until 9 PM.',
      days: 4,
      hours: 17,
      location: 'Union Plaza District',
      address: '400 W San Antonio Ave',
      zip: '79901',
      category: 'Food',
      organizer: 'Union Plaza Merchants',
      avatarHex: 'FF7675',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800&auto=format&fit=crop',
      lat: 31.7570,
      lng: -106.4920,
      source: EventSource.facebook,
      bookmarked: 221,
      interested: 604,
    ),
    ep(
      id: 'evt_ep_012',
      title: 'Segundo Barrio Mural Walking Tour',
      description:
          'Guided walk through Segundo Barrio murals and historic streets south of downtown. '
          'Wear comfortable shoes. Tour ends near the international bridge overlook.',
      days: 3,
      hours: 10,
      location: 'Segundo Barrio',
      address: '800 S Oregon St',
      zip: '79901',
      category: 'Arts',
      organizer: 'Chamizal Community Arts',
      avatarHex: 'E1306C',
      imageUrl:
          'https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?q=80&w=800&auto=format&fit=crop',
      lat: 31.7522,
      lng: -106.4828,
      cost: 10,
      source: EventSource.local,
      bookmarked: 73,
      interested: 198,
    ),
    ep(
      id: 'evt_ep_013',
      title: 'Ascarate Park Family Day',
      description:
          'Free family afternoon at Ascarate Park: playgrounds, lake loop, and a pop-up soccer clinic. '
          'Western Playland is next door if you want rides after. Shade is limited — bring hats.',
      days: 7,
      hours: 11,
      location: 'Ascarate Park',
      address: '6900 Delta Dr',
      zip: '79905',
      category: 'Community',
      organizer: 'El Paso County Parks',
      avatarHex: '00B894',
      imageUrl:
          'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?q=80&w=800&auto=format&fit=crop',
      lat: 31.7580,
      lng: -106.4060,
      source: EventSource.google,
      bookmarked: 118,
      interested: 305,
    ),
    ep(
      id: 'evt_ep_014',
      title: 'Concordia Cemetery Lantern Tour',
      description:
          'After-dark history walk through Concordia Cemetery — gunfighters, Buffalo Soldiers, and Chinese railroad workers. '
          'Closed-toe shoes required. Not recommended for young children.',
      days: 5,
      hours: 20,
      location: 'Concordia Cemetery',
      address: '3700 E Yandell Dr',
      zip: '79903',
      category: 'Social',
      organizer: 'Concordia Heritage Association',
      avatarHex: '2D3436',
      imageUrl:
          'https://images.unsplash.com/photo-1509557965875-b88c97052f0e?q=80&w=800&auto=format&fit=crop',
      lat: 31.7786,
      lng: -106.4500,
      cost: 15,
      source: EventSource.local,
      bookmarked: 91,
      interested: 244,
    ),
    ep(
      id: 'evt_ep_015',
      title: 'Salsa Night at Don Haskins Center',
      description:
          'Beginner salsa lesson at 7, social dancing after, in a side hall at the Don Haskins Center. '
          'No partner needed. Water provided; bring a towel and comfortable shoes.',
      days: 2,
      hours: 19,
      location: 'Don Haskins Center',
      address: '151 Glory Rd',
      zip: '79968',
      category: 'Dance',
      organizer: 'Borderland Dance Collective',
      avatarHex: 'FD79A8',
      imageUrl:
          'https://images.unsplash.com/photo-1504609813442-a8924e83f76e?q=80&w=800&auto=format&fit=crop',
      lat: 31.7774,
      lng: -106.5065,
      cost: 12,
      source: EventSource.facebook,
      bookmarked: 134,
      interested: 356,
    ),
    ep(
      id: 'evt_ep_016',
      title: 'Open Mic — Downtown Listening Room',
      description:
          'Sign-up open mic for singers, poets, and comics. Five minutes a slot. '
          'Coffee and local beer. First-come list at the door.',
      days: 2,
      hours: 20,
      location: 'The Hoppy Monk (listening night)',
      address: '4141 N Mesa St',
      zip: '79902',
      category: 'Music',
      organizer: 'El Paso Songwriters',
      avatarHex: 'E17055',
      imageUrl:
          'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
      lat: 31.7885,
      lng: -106.5030,
      cost: 5,
      source: EventSource.local,
      bookmarked: 64,
      interested: 171,
    ),
    ep(
      id: 'evt_ep_017',
      title: 'Keystone Heritage Park Bird Walk',
      description:
          'Easy morning walk around the wetlands at Keystone Heritage Park. Binoculars helpful. '
          'Great for beginners and kids. Park at the visitor lot off Doniphan.',
      days: 6,
      hours: 8,
      location: 'Keystone Heritage Park',
      address: '4200 Doniphan Dr',
      zip: '79922',
      category: 'Community',
      organizer: 'El Paso/Trans-Pecos Audubon',
      avatarHex: '00CEC9',
      imageUrl:
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=800&auto=format&fit=crop',
      lat: 31.8010,
      lng: -106.5450,
      source: EventSource.google,
      bookmarked: 52,
      interested: 139,
    ),
    ep(
      id: 'evt_ep_018',
      title: 'Ysleta Mission Festival Prep Day',
      description:
          'Volunteer morning at Ysleta Mission in the Mission Valley: decorating, setup, and community lunch. '
          'All ages. Park on the mission grounds. Water and tacos provided.',
      days: 10,
      hours: 9,
      location: 'Ysleta Mission',
      address: '131 S Zaragoza Rd',
      zip: '79907',
      category: 'Community',
      organizer: 'Ysleta del Sur Pueblo & Mission',
      avatarHex: 'FDCB6E',
      imageUrl:
          'https://images.unsplash.com/photo-1529543544282-ea669407fca3?q=80&w=800&auto=format&fit=crop',
      lat: 31.6920,
      lng: -106.3270,
      source: EventSource.local,
      bookmarked: 79,
      interested: 206,
    ),
  ];
}
