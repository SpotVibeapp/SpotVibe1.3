import '../models/event.dart';

// ── City centre coordinates for known cities ───────────────────────────────────
// Used both to set lat/lng on hardcoded events and to seed jitter in the
// deterministic event generator so every generated event has a unique,
// realistic location within ~1 km of the city centre.
const Map<String, List<double>> _kCityCoords = {
  'New York':      [40.7128, -74.0060],
  'Brooklyn':      [40.6782, -73.9442],
  'Queens':        [40.7282, -73.7949],
  'Manhattan':     [40.7831, -73.9712],
  'Austin':        [30.2672, -97.7431],
  'Chicago':       [41.8781, -87.6298],
  'Los Angeles':   [34.0522, -118.2437],
  'Portland':      [45.5051, -122.6750],
  'San Francisco': [37.7749, -122.4194],
  'Seattle':       [47.6062, -122.3321],
  'Denver':        [39.7392, -104.9903],
  'New Orleans':   [29.9511, -90.0715],
  'Houston':       [29.7604, -95.3698],
  'San Diego':     [32.7157, -117.1611],
  'Nashville':     [36.1627, -86.7816],
  'Philadelphia':  [39.9526, -75.1652],
  'Atlanta':       [33.7490, -84.3880],
  'Boston':        [42.3601, -71.0589],
  'Phoenix':       [33.4484, -112.0740],
  'Miami':         [25.7617, -80.1918],
  'Dallas':        [32.7767, -96.7970],
  'Minneapolis':   [44.9778, -93.2650],
  'Las Vegas':     [36.1699, -115.1398],
  'Washington':    [38.9072, -77.0369],
  'Asheville':     [35.5951, -82.5515],
  // Generic fallbacks for the 50-state generator
  'Birmingham':    [33.5186, -86.8104],
  'Anchorage':     [61.2181, -149.9003],
  'Tucson':        [32.2226, -110.9747],
  'Little Rock':   [34.7465, -92.2896],
  'Sacramento':    [38.5816, -121.4944],
  'Colorado Springs': [38.8339, -104.8214],
  'Bridgeport':    [41.1865, -73.1952],
  'Wilmington':    [39.7447, -75.5484],
  'Jacksonville':  [30.3322, -81.6557],
  'Savannah':      [32.0809, -81.0912],
  'Honolulu':      [21.3069, -157.8583],
  'Boise':         [43.6150, -116.2023],
  'Indianapolis':  [39.7684, -86.1581],
  'Des Moines':    [41.5868, -93.6250],
  'Wichita':       [37.6872, -97.3301],
  'Louisville':    [38.2527, -85.7585],
  'Baton Rouge':   [30.4515, -91.1871],
  'Portland ME':   [43.6591, -70.2568],
  'Baltimore':     [39.2904, -76.6122],
  'Detroit':       [42.3314, -83.0458],
  'Kansas City':   [39.0997, -94.5786],
  'Omaha':         [41.2565, -95.9345],
  'Henderson':     [36.0395, -114.9817],
  'Manchester':    [42.9956, -71.4548],
  'Newark':        [40.7357, -74.1724],
  'Albuquerque':   [35.0844, -106.6504],
  'Charlotte':     [35.2271, -80.8431],
  'Columbus':      [39.9612, -82.9988],
  'Oklahoma City': [35.4676, -97.5164],
  'Eugene':        [44.0521, -123.0868],
  'Pittsburgh':    [40.4406, -79.9959],
  'Providence':    [41.8240, -71.4128],
  'Columbia':      [34.0007, -81.0348],
  'Sioux Falls':   [43.5446, -96.7311],
  'Memphis':       [35.1495, -90.0490],
  'San Antonio':   [29.4241, -98.4936],
  'Salt Lake City': [40.7608, -111.8910],
  'Burlington':    [44.4759, -73.2121],
  'Virginia Beach':[36.8529, -75.9780],
  'Spokane':       [47.6588, -117.4260],
  'Milwaukee':     [43.0389, -87.9065],
  'Cheyenne':      [41.1400, -104.8202],
};

// Helper: get coordinates for a city name (case-insensitive prefix match).
List<double>? _coordsForCity(String city) {
  final key = _kCityCoords.keys.firstWhere(
    (k) => k.toLowerCase() == city.toLowerCase(),
    orElse: () => '',
  );
  return key.isEmpty ? null : _kCityCoords[key];
}

// ── Deterministic event templates ─────────────────────────────────────────────
// Titles, descriptions, categories, costs, image URLs, sources and organiser
// names that are combined with any city/state to generate realistic local events.
const _kTemplates = [
  _EventTemplate(
    titlePrefix: 'Live Music Night',
    description:
        'An electrifying evening of live performances from local and touring artists. '
        'Drinks, dancing, and good vibes all night. Doors open one hour before showtime.',
    category: 'Music',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Music Hall',
    daysOffset: 2,
    hoursOffset: 20,
    bookmarkedCount: 142,
    interestedCount: 389,
  ),
  _EventTemplate(
    titlePrefix: 'Community Farmers Market',
    description:
        'Fresh seasonal produce, honey, artisan breads, and handcrafted goods from local growers. '
        'Bring your own bags. Live acoustic music from 9 AM to noon.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1488459716781-31db52582fe9?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Downtown Plaza',
    daysOffset: 1,
    hoursOffset: 9,
    bookmarkedCount: 88,
    interestedCount: 230,
  ),
  _EventTemplate(
    titlePrefix: 'Outdoor Yoga & Wellness Session',
    description:
        'A guided sunrise yoga flow suitable for all levels. Bring a mat and water. '
        'We wrap up with a short meditation and free smoothie samples.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Riverside Park',
    daysOffset: 3,
    hoursOffset: 7,
    bookmarkedCount: 56,
    interestedCount: 148,
  ),
  _EventTemplate(
    titlePrefix: 'Food Truck Festival',
    description:
        'Over 15 food trucks serving global flavors — tacos, ramen, BBQ, vegan bowls, and more. '
        'Family friendly, free entry. Live DJ set from 4 PM.',
    category: 'Food',
    imageUrl:
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Fairgrounds',
    daysOffset: 4,
    hoursOffset: 12,
    bookmarkedCount: 210,
    interestedCount: 560,
  ),
  _EventTemplate(
    titlePrefix: 'Neighborhood Cleanup Drive',
    description:
        'Help keep our community beautiful! Gloves and bags provided. Refreshments after. '
        'Great volunteer opportunity — bring friends and family.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Community Park',
    daysOffset: 5,
    hoursOffset: 8,
    bookmarkedCount: 34,
    interestedCount: 89,
  ),
  _EventTemplate(
    titlePrefix: 'Open Mic Night',
    description:
        'Share your talent or just enjoy performances from local musicians, poets, and comedians. '
        'Sign up at the door or come to watch. Drinks available all night.',
    category: 'Music',
    imageUrl:
        'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'The Venue Lounge',
    daysOffset: 1,
    hoursOffset: 19,
    bookmarkedCount: 63,
    interestedCount: 178,
    cost: 5.00,
  ),
  _EventTemplate(
    titlePrefix: 'Art Gallery Opening',
    description:
        'Opening night reception for a new exhibition featuring works by emerging local artists. '
        'Free wine and appetizers. Meet the artists in person.',
    category: 'Arts',
    imageUrl:
        'https://images.unsplash.com/photo-1531913223931-b0d3198229ee?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Arts Center',
    daysOffset: 6,
    hoursOffset: 18,
    bookmarkedCount: 78,
    interestedCount: 211,
  ),
  _EventTemplate(
    titlePrefix: 'Tech Startup Meetup',
    description:
        'Monthly gathering for founders, developers, and designers. Lightning talks, open networking, '
        'and a pitch competition. Free drinks for first arrivals.',
    category: 'Technology',
    imageUrl:
        'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Co-Working Hub',
    daysOffset: 8,
    hoursOffset: 18,
    bookmarkedCount: 104,
    interestedCount: 295,
    cost: 10.00,
  ),
  _EventTemplate(
    titlePrefix: 'Salsa & Latin Dance Night',
    description:
        'Beginner lesson at 7 PM followed by open social dancing until midnight. '
        'All skill levels welcome — partners rotated throughout. Wear comfortable shoes.',
    category: 'Dance',
    imageUrl:
        'https://images.unsplash.com/photo-1504609813442-a8924e83f76e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Ballroom',
    daysOffset: 3,
    hoursOffset: 19,
    bookmarkedCount: 91,
    interestedCount: 247,
    cost: 12.00,
  ),
  _EventTemplate(
    titlePrefix: 'Charity 5K Fun Run',
    description:
        'A timed 5K through scenic downtown streets for all fitness levels. Walkers welcome. '
        'T-shirt and medal included. All proceeds benefit the local food bank.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'City Park',
    daysOffset: 7,
    hoursOffset: 7,
    bookmarkedCount: 77,
    interestedCount: 203,
    cost: 20.00,
  ),
  _EventTemplate(
    titlePrefix: 'Book Club Meeting',
    description:
        'This month we\'re reading a bestselling debut novel. New members always welcome — '
        'no need to have finished the book, just bring your curiosity. Coffee and tea provided.',
    category: 'Social',
    imageUrl:
        'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Public Library',
    daysOffset: 10,
    hoursOffset: 14,
    bookmarkedCount: 29,
    interestedCount: 72,
  ),
  _EventTemplate(
    titlePrefix: 'Watercolor Painting Workshop',
    description:
        'Beginner-friendly 2-hour class led by a local artist. All materials provided. '
        'Learn wet-on-wet, washes, and blooms. Take your artwork home.',
    category: 'Arts',
    imageUrl:
        'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Art Studio',
    daysOffset: 9,
    hoursOffset: 11,
    bookmarkedCount: 45,
    interestedCount: 118,
    cost: 22.00,
  ),
  _EventTemplate(
    titlePrefix: 'Game Night Extravaganza',
    description:
        'Bring your competitive spirit! Board games, card games, trivia, and video game stations. '
        'Prizes for tournament winners. Snacks and drinks provided. All ages welcome.',
    category: 'Fun & Games',
    imageUrl:
        'https://images.unsplash.com/photo-1556438064-2d7646166914?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Recreation Center',
    daysOffset: 5,
    hoursOffset: 18,
    bookmarkedCount: 93,
    interestedCount: 261,
    cost: 8.00,
  ),
  // ── Additional templates ───────────────────────────────────────────────────
  _EventTemplate(
    titlePrefix: 'Rooftop Jazz Evening',
    description:
        'A sophisticated evening of live jazz on a rooftop terrace with panoramic city views. '
        'Craft cocktails, small plates, and smooth sounds. Reservations recommended.',
    category: 'Music',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1511192336575-5a79af67a629?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Rooftop Terrace',
    daysOffset: 4,
    hoursOffset: 19,
    bookmarkedCount: 118,
    interestedCount: 312,
  ),
  _EventTemplate(
    titlePrefix: 'Street Art & Mural Tour',
    description:
        'Guided walking tour of the city\'s best murals and street art with a local artist as your guide. '
        'Learn the stories behind the pieces and the artists who created them. Ends at a gallery.',
    category: 'Arts',
    imageUrl:
        'https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Arts District',
    daysOffset: 2,
    hoursOffset: 11,
    bookmarkedCount: 66,
    interestedCount: 174,
    cost: 15.00,
  ),
  _EventTemplate(
    titlePrefix: 'Sunday Brunch Social',
    description:
        'A laid-back Sunday brunch with live acoustic music, bottomless mimosas, and a full brunch buffet. '
        'Great for meeting new people. Reservations open — walk-ins welcome if space allows.',
    category: 'Food',
    cost: 28.00,
    imageUrl:
        'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Bistro & Bar',
    daysOffset: 2,
    hoursOffset: 11,
    bookmarkedCount: 134,
    interestedCount: 367,
  ),
  _EventTemplate(
    titlePrefix: 'Spin & Strength Fitness Class',
    description:
        'High-energy 45-minute indoor cycling session followed by a 15-minute strength circuit. '
        'All fitness levels welcome. Bikes and equipment provided. Bring a towel and water.',
    category: 'Wellness',
    cost: 18.00,
    imageUrl:
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Fitness Studio',
    daysOffset: 1,
    hoursOffset: 6,
    bookmarkedCount: 47,
    interestedCount: 122,
  ),
  _EventTemplate(
    titlePrefix: 'Trivia Night — Pop Culture Edition',
    description:
        'Test your knowledge across movies, music, TV, and internet culture. Teams of up to 6. '
        'Prizes for 1st, 2nd, and 3rd place. Host brings the laughs — free to play.',
    category: 'Fun & Games',
    imageUrl:
        'https://images.unsplash.com/photo-1511882150382-421056c89033?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Sports Bar & Grill',
    daysOffset: 3,
    hoursOffset: 20,
    bookmarkedCount: 82,
    interestedCount: 219,
  ),
  _EventTemplate(
    titlePrefix: 'Vintage & Thrift Pop-Up',
    description:
        'Shop curated vintage clothing, accessories, vinyl records, and retro home decor from '
        '20+ vendors. Sustainable fashion at affordable prices. DJ spinning vintage hits.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Event Space',
    daysOffset: 6,
    hoursOffset: 10,
    bookmarkedCount: 97,
    interestedCount: 258,
    cost: 3.00,
  ),
  _EventTemplate(
    titlePrefix: 'Dog-Friendly Meetup in the Park',
    description:
        'Bring your pup for a social morning at the park! Dogs play while owners mingle. '
        'Dog treats provided, coffee truck on site. All breeds and sizes welcome.',
    category: 'Social',
    imageUrl:
        'https://images.unsplash.com/photo-1450778869180-41d0601e046e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Off-Leash Dog Park',
    daysOffset: 2,
    hoursOffset: 9,
    bookmarkedCount: 73,
    interestedCount: 192,
  ),
  _EventTemplate(
    titlePrefix: 'Hip-Hop Dance Workshop',
    description:
        'Learn foundational hip-hop moves with an experienced choreographer. No experience needed. '
        'Classes run 90 minutes with a warm-up, technique drills, and a freestyle session at the end.',
    category: 'Dance',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1547153760-18fc86324498?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Dance Academy',
    daysOffset: 4,
    hoursOffset: 17,
    bookmarkedCount: 58,
    interestedCount: 147,
  ),
  _EventTemplate(
    titlePrefix: 'Coding Bootcamp — Web Dev Intro',
    description:
        'A free 3-hour intro to HTML, CSS, and JavaScript for complete beginners. Bring your laptop. '
        'Taught by senior engineers. Certificate of completion provided. Light lunch included.',
    category: 'Technology',
    imageUrl:
        'https://images.unsplash.com/photo-1531482615713-2afd69097998?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Innovation Lab',
    daysOffset: 9,
    hoursOffset: 10,
    bookmarkedCount: 88,
    interestedCount: 234,
  ),
  _EventTemplate(
    titlePrefix: 'Pickleball Tournament',
    description:
        'Round-robin pickleball tournament for all skill levels. Register solo or bring a partner. '
        'Equipment provided. Prizes for top finishers. Post-match social at the clubhouse.',
    category: 'Sports',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1554284126-aa88f22d8b74?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Sports Complex',
    daysOffset: 8,
    hoursOffset: 9,
    bookmarkedCount: 61,
    interestedCount: 159,
  ),
  _EventTemplate(
    titlePrefix: 'Volunteer Meal Prep Day',
    description:
        'Help prepare and package meals for seniors and families in need. No experience required — '
        'just a willingness to help. Aprons and gloves provided. A deeply rewarding morning.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1593113598332-cd288d649433?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Community Kitchen',
    daysOffset: 6,
    hoursOffset: 9,
    bookmarkedCount: 39,
    interestedCount: 98,
  ),
  _EventTemplate(
    titlePrefix: 'Speed Networking Mixer',
    description:
        'Fast-paced professional networking event with structured rounds. Meet 15+ professionals '
        'in one evening. Name tags, conversation starters, and drinks provided. Business casual.',
    category: 'Social',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Hotel Ballroom',
    daysOffset: 12,
    hoursOffset: 18,
    bookmarkedCount: 109,
    interestedCount: 291,
  ),
  _EventTemplate(
    titlePrefix: 'Pottery & Clay Workshop',
    description:
        'Learn the basics of hand-building with clay — pinch pots, coil building, and slab construction. '
        'All materials included. Take your creation home after it\'s glazed and fired.',
    category: 'Arts',
    cost: 30.00,
    imageUrl:
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Ceramic Studio',
    daysOffset: 11,
    hoursOffset: 13,
    bookmarkedCount: 52,
    interestedCount: 138,
  ),
  _EventTemplate(
    titlePrefix: 'Sunrise Hike & Breakfast',
    description:
        'An invigorating early morning hike to a scenic overlook, followed by a communal breakfast '
        'at the trailhead. Moderate difficulty, 4 miles round trip. Hiking boots recommended.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Nature Trail',
    daysOffset: 4,
    hoursOffset: 6,
    bookmarkedCount: 83,
    interestedCount: 217,
  ),
  _EventTemplate(
    titlePrefix: 'Escape Room Challenge Night',
    description:
        'Groups of 4–6 compete to solve puzzles and escape themed rooms. Multiple rooms available. '
        'Book as a team or get matched with strangers. Post-game social and prizes for fastest teams.',
    category: 'Fun & Games',
    cost: 25.00,
    imageUrl:
        'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Escape Lounge',
    daysOffset: 7,
    hoursOffset: 19,
    bookmarkedCount: 76,
    interestedCount: 201,
  ),
  _EventTemplate(
    titlePrefix: 'Craft Beer Tasting Tour',
    description:
        'Sample 12 local craft beers from 4 breweries on a guided walking tour. A certified cicerone '
        'leads the tasting notes. Includes a souvenir tasting glass. Ages 21+ only.',
    category: 'Food',
    cost: 35.00,
    imageUrl:
        'https://images.unsplash.com/photo-1535958636474-b021ee887b13?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Brewery District',
    daysOffset: 5,
    hoursOffset: 15,
    bookmarkedCount: 128,
    interestedCount: 344,
  ),
  _EventTemplate(
    titlePrefix: 'Soccer Pickup Game',
    description:
        'Casual 7-a-side pickup soccer match at the local sports fields. All skill levels welcome. '
        'Show up and get sorted into teams on arrival. Bring cleats or flat-soled shoes.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1517927033932-b3d18e61fb3a?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Athletic Fields',
    daysOffset: 1,
    hoursOffset: 16,
    bookmarkedCount: 44,
    interestedCount: 116,
  ),
  _EventTemplate(
    titlePrefix: 'DIY Home Repair Workshop',
    description:
        'Learn basic home repair skills: patching drywall, fixing leaky faucets, changing outlets, '
        'and more. Tools provided. Small class size (12 max) for hands-on learning.',
    category: 'Community',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Hardware & Community Center',
    daysOffset: 13,
    hoursOffset: 10,
    bookmarkedCount: 37,
    interestedCount: 94,
  ),
  _EventTemplate(
    titlePrefix: 'Karaoke Championship',
    description:
        'Think you\'ve got the best pipes in town? Sign up and compete for the golden microphone trophy. '
        'Judges score on performance and crowd reaction. Open bar specials all night.',
    category: 'Fun & Games',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Karaoke Bar',
    daysOffset: 3,
    hoursOffset: 21,
    bookmarkedCount: 99,
    interestedCount: 263,
  ),
  _EventTemplate(
    titlePrefix: 'Fashion & Style Swap',
    description:
        'Bring 5 items you no longer wear and swap them for something new-to-you. '
        'All styles and sizes welcome. Leftover items donated to local shelters. Free admission.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Community Hall',
    daysOffset: 7,
    hoursOffset: 11,
    bookmarkedCount: 69,
    interestedCount: 182,
  ),
  _EventTemplate(
    titlePrefix: 'Acoustic Singer-Songwriter Night',
    description:
        'An intimate evening showcasing four local singer-songwriters performing original music. '
        'Cozy venue, great acoustics, full bar. Doors open 30 minutes before the first act.',
    category: 'Music',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Coffee House',
    daysOffset: 6,
    hoursOffset: 20,
    bookmarkedCount: 54,
    interestedCount: 143,
  ),
  _EventTemplate(
    titlePrefix: 'Meditation & Mindfulness Class',
    description:
        'A beginner-friendly guided meditation class covering breathing exercises, body scans, and '
        'visualization techniques. Mats and cushions provided. End with a calming tea ceremony.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1545389336-cf090694435e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Wellness Center',
    daysOffset: 5,
    hoursOffset: 10,
    bookmarkedCount: 41,
    interestedCount: 109,
    cost: 12.00,
  ),
  // ── Batch 3 — expanded nationwide coverage ────────────────────────────────
  _EventTemplate(
    titlePrefix: 'Local Comedy Showcase',
    description:
        'Five up-and-coming comedians take the stage for a 90-minute showcase of stand-up, '
        'crowd work, and improv. Two-drink minimum. 21+ event. Doors open 30 min early.',
    category: 'Fun & Games',
    cost: 18.00,
    imageUrl:
        'https://images.unsplash.com/photo-1527224538127-2104bb71c51b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Comedy Club',
    daysOffset: 5,
    hoursOffset: 20,
    bookmarkedCount: 115,
    interestedCount: 304,
  ),
  _EventTemplate(
    titlePrefix: 'Outdoor Movie Night',
    description:
        'Bring a blanket and lawn chairs for a free outdoor screening under the stars. '
        'Popcorn and concessions available. Gates open at sunset; movie starts at dusk.',
    category: 'Social',
    imageUrl:
        'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Amphitheater',
    daysOffset: 3,
    hoursOffset: 20,
    bookmarkedCount: 162,
    interestedCount: 431,
  ),
  _EventTemplate(
    titlePrefix: 'Plant-Based Cooking Class',
    description:
        'Learn to cook delicious, protein-rich plant-based meals with a certified nutritionist. '
        'All ingredients provided. Walk away with three new recipes and a full belly.',
    category: 'Food',
    cost: 32.00,
    imageUrl:
        'https://images.unsplash.com/photo-1543362906-acfc16c67564?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Culinary Studio',
    daysOffset: 10,
    hoursOffset: 13,
    bookmarkedCount: 74,
    interestedCount: 196,
  ),
  _EventTemplate(
    titlePrefix: 'Basketball 3-on-3 Tournament',
    description:
        'Register your team of 3 for a single-elimination bracket played on outdoor courts. '
        'Cash prizes for top finishers. Free agent sign-ups welcome — we\'ll build you a team.',
    category: 'Sports',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Rec Center Courts',
    daysOffset: 6,
    hoursOffset: 10,
    bookmarkedCount: 88,
    interestedCount: 232,
  ),
  _EventTemplate(
    titlePrefix: 'Photography Walk',
    description:
        'Join fellow photography enthusiasts for a guided golden-hour walk. Capture street scenes, '
        'architecture, and portraits. Any camera welcome — phone cameras encouraged. Free.',
    category: 'Arts',
    imageUrl:
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Historic District',
    daysOffset: 7,
    hoursOffset: 17,
    bookmarkedCount: 59,
    interestedCount: 153,
  ),
  _EventTemplate(
    titlePrefix: 'Neighborhood Block Party',
    description:
        'Annual community block party with BBQ, lawn games, face painting for kids, and live music. '
        'Free to attend. Bring a dish to share and meet your neighbors.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1567521464027-f127ff144326?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Neighborhood Streets',
    daysOffset: 9,
    hoursOffset: 12,
    bookmarkedCount: 147,
    interestedCount: 392,
  ),
  _EventTemplate(
    titlePrefix: 'Flea Market & Antique Fair',
    description:
        'Hundreds of vendors selling antiques, collectibles, handmade goods, and vintage treasures. '
        'Free entry. Food vendors on site. Rain or shine event.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1573408301828-49dc5a01e17c?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Expo Center',
    daysOffset: 8,
    hoursOffset: 8,
    bookmarkedCount: 103,
    interestedCount: 274,
  ),
  _EventTemplate(
    titlePrefix: 'Electronic Music Dance Night',
    description:
        'Two resident DJs and one headliner spinning house, techno, and electronic beats all night. '
        'Laser lights, immersive visuals. Limited tickets — advance purchase recommended.',
    category: 'Dance',
    cost: 22.00,
    imageUrl:
        'https://images.unsplash.com/photo-1571266028243-e4733b0f0bb0?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Nightclub',
    daysOffset: 2,
    hoursOffset: 22,
    bookmarkedCount: 189,
    interestedCount: 503,
  ),
  _EventTemplate(
    titlePrefix: 'Resume & Career Workshop',
    description:
        'Free workshop led by HR professionals covering resume writing, LinkedIn optimization, '
        'and interview prep. Bring your resume for live feedback. Refreshments provided.',
    category: 'Technology',
    imageUrl:
        'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Public Library',
    daysOffset: 11,
    hoursOffset: 14,
    bookmarkedCount: 66,
    interestedCount: 175,
  ),
  _EventTemplate(
    titlePrefix: 'Paddle & Kayak Social',
    description:
        'Guided kayak tour along a scenic waterway for beginners and intermediate paddlers. '
        'Kayaks and life jackets provided. Post-paddle picnic on the shore.',
    category: 'Sports',
    cost: 30.00,
    imageUrl:
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Waterfront Launch',
    daysOffset: 4,
    hoursOffset: 9,
    bookmarkedCount: 55,
    interestedCount: 143,
  ),
  _EventTemplate(
    titlePrefix: 'Wine & Cheese Pairing Evening',
    description:
        'A sommelier guides you through six wines paired with artisan cheeses and charcuterie. '
        'Learn tasting techniques and take home a pairing guide. 21+ event.',
    category: 'Food',
    cost: 45.00,
    imageUrl:
        'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Wine Bar',
    daysOffset: 13,
    hoursOffset: 19,
    bookmarkedCount: 92,
    interestedCount: 245,
  ),
  _EventTemplate(
    titlePrefix: 'Youth Sports Camp',
    description:
        'Week-long daytime camp for kids ages 7–14 covering soccer, basketball, and volleyball. '
        'Certified coaches, daily drills, and a Friday tournament. Register per day or full week.',
    category: 'Sports',
    cost: 25.00,
    imageUrl:
        'https://images.unsplash.com/photo-1477281765962-ef34e8bb0967?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Youth Athletic Center',
    daysOffset: 14,
    hoursOffset: 9,
    bookmarkedCount: 48,
    interestedCount: 127,
  ),
  _EventTemplate(
    titlePrefix: 'Improv Comedy Workshop',
    description:
        'Learn the fundamentals of improv comedy in a fun, supportive environment. '
        'Exercises include "Yes And", character building, and scene work. No experience required.',
    category: 'Social',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1463620695885-8a91d87c53d0?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Theater',
    daysOffset: 12,
    hoursOffset: 18,
    bookmarkedCount: 61,
    interestedCount: 162,
  ),
  _EventTemplate(
    titlePrefix: 'Swing Dance Mixer',
    description:
        'Swing into the weekend with a free beginner lesson at 7 PM followed by a social dance. '
        'Live band plays authentic swing music. No partner needed. All ages welcome.',
    category: 'Dance',
    cost: 8.00,
    imageUrl:
        'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Dance Hall',
    daysOffset: 6,
    hoursOffset: 19,
    bookmarkedCount: 79,
    interestedCount: 209,
  ),
  _EventTemplate(
    titlePrefix: 'Local Farmers & Artisan Showcase',
    description:
        'Meet the growers and makers behind your food and crafts. Seasonal produce, small-batch '
        'preserves, handmade soaps, candles, and ceramics. Live folk music throughout the morning.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1526951521990-620dc14c214b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Town Square',
    daysOffset: 3,
    hoursOffset: 8,
    bookmarkedCount: 112,
    interestedCount: 298,
  ),
  // ── Batch 4 — comedy, film, nightlife, outdoor, fitness, family, education ──
  _EventTemplate(
    titlePrefix: 'Stand-Up Comedy Night',
    description:
        'A full evening of stand-up comedy with five local and touring headliners. '
        'Two-drink minimum. Guaranteed laughs or your money back — not really, but almost.',
    category: 'Fun & Games',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Comedy Club',
    daysOffset: 2,
    hoursOffset: 20,
    bookmarkedCount: 134,
    interestedCount: 356,
  ),
  _EventTemplate(
    titlePrefix: 'Indie Film Screening',
    description:
        'A curated screening of three award-winning independent short films followed by a '
        'Q&A with the directors. Popcorn included. Doors open 20 minutes before showtime.',
    category: 'Arts',
    cost: 12.00,
    imageUrl:
        'https://images.unsplash.com/photo-1478720568477-152d9b164e26?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Indie Cinema',
    daysOffset: 5,
    hoursOffset: 19,
    bookmarkedCount: 77,
    interestedCount: 205,
  ),
  _EventTemplate(
    titlePrefix: 'Night Market & Street Food Festival',
    description:
        'Explore 30+ street food stalls, artisan vendors, and live entertainment under string lights. '
        'Free entry. Cash and cards accepted. Runs until midnight.',
    category: 'Food',
    imageUrl:
        'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Night Market Grounds',
    daysOffset: 4,
    hoursOffset: 18,
    bookmarkedCount: 243,
    interestedCount: 647,
  ),
  _EventTemplate(
    titlePrefix: 'Family Nature Walk',
    description:
        'A guided 2-mile nature walk for families with children. Learn about local plants, birds, '
        'and insects along the trail. Bring water and sunscreen. Free for all ages.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Nature Reserve',
    daysOffset: 2,
    hoursOffset: 9,
    bookmarkedCount: 58,
    interestedCount: 152,
  ),
  _EventTemplate(
    titlePrefix: 'CrossFit Open Community Workout',
    description:
        'Join our community for the open WOD — all fitness levels welcome. Coaches scale every '
        'movement. Free to drop in. Protein shakes available after. Bring a friend.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'CrossFit Box',
    daysOffset: 1,
    hoursOffset: 8,
    bookmarkedCount: 69,
    interestedCount: 183,
  ),
  _EventTemplate(
    titlePrefix: 'Sunset Rooftop Social',
    description:
        'Watch the city skyline turn golden at a rooftop cocktail social. DJ spinning lounge sets, '
        'signature cocktails, and small bites. Dress code: smart casual. 21+.',
    category: 'Social',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Rooftop Bar',
    daysOffset: 3,
    hoursOffset: 18,
    bookmarkedCount: 196,
    interestedCount: 521,
  ),
  _EventTemplate(
    titlePrefix: 'Children\'s Science Fair',
    description:
        'An interactive science fair for kids aged 5–12 with hands-on experiments, robotics demos, '
        'and a rocket launch. Free admission. Parents and guardians welcome.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Science Museum',
    daysOffset: 6,
    hoursOffset: 10,
    bookmarkedCount: 82,
    interestedCount: 218,
  ),
  _EventTemplate(
    titlePrefix: 'Latin Food & Culture Festival',
    description:
        'Celebrate Latino heritage with authentic cuisine, folk dancing, live music, and artisan '
        'crafts. Free entry. Bring the whole family. Over 25 food vendors represented.',
    category: 'Food',
    imageUrl:
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Cultural Center',
    daysOffset: 7,
    hoursOffset: 11,
    bookmarkedCount: 178,
    interestedCount: 473,
  ),
  _EventTemplate(
    titlePrefix: 'Pilates & Core Workshop',
    description:
        'A 75-minute intermediate pilates class focusing on core strength, posture correction, '
        'and breath work. Mats provided. Advance booking required. Limited spots.',
    category: 'Wellness',
    cost: 22.00,
    imageUrl:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Pilates Studio',
    daysOffset: 2,
    hoursOffset: 7,
    bookmarkedCount: 53,
    interestedCount: 139,
  ),
  _EventTemplate(
    titlePrefix: 'Jazz & Blues Brunch',
    description:
        'Sunday brunch with live jazz and blues from a rotating house quartet. Full brunch menu '
        'with bottomless coffee. Walk-ins welcome. Reservations strongly recommended.',
    category: 'Music',
    cost: 30.00,
    imageUrl:
        'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Jazz Lounge',
    daysOffset: 2,
    hoursOffset: 10,
    bookmarkedCount: 141,
    interestedCount: 374,
  ),
  _EventTemplate(
    titlePrefix: 'Charity Gala & Silent Auction',
    description:
        'A black-tie optional charity gala raising funds for local youth education programs. '
        'Dinner, dancing, live auction, and a keynote speaker. Dress to impress.',
    category: 'Community',
    cost: 75.00,
    imageUrl:
        'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Grand Ballroom',
    daysOffset: 14,
    hoursOffset: 18,
    bookmarkedCount: 95,
    interestedCount: 252,
  ),
  _EventTemplate(
    titlePrefix: 'Weekend Cycling Club Ride',
    description:
        'A 20-mile group road cycling ride through scenic countryside routes. Moderate pace — '
        'suitable for intermediate riders. Coffee stop at the halfway point. Helmet required.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1571188654248-7a89213915f7?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Cycling Club HQ',
    daysOffset: 3,
    hoursOffset: 7,
    bookmarkedCount: 64,
    interestedCount: 169,
  ),
  _EventTemplate(
    titlePrefix: 'Language Exchange Meetup',
    description:
        'Practice conversational Spanish, French, Mandarin, or Portuguese with native speakers. '
        'Structured 20-minute rotation rounds. Coffee shop setting, casual and welcoming.',
    category: 'Social',
    imageUrl:
        'https://images.unsplash.com/photo-1536825919236-c16a58d2e6ad?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Coffee House',
    daysOffset: 5,
    hoursOffset: 18,
    bookmarkedCount: 48,
    interestedCount: 127,
  ),
  _EventTemplate(
    titlePrefix: 'Digital Art & NFT Panel',
    description:
        'Industry experts discuss the intersection of digital art, blockchain, and the future of '
        'creative ownership. Panel Q&A, live minting demo, and networking reception after.',
    category: 'Technology',
    cost: 25.00,
    imageUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Innovation Hub',
    daysOffset: 10,
    hoursOffset: 17,
    bookmarkedCount: 87,
    interestedCount: 231,
  ),
  _EventTemplate(
    titlePrefix: 'Urban Garden Workshop',
    description:
        'Learn container gardening, composting, and balcony herb gardens from a master gardener. '
        'Take home a starter kit with seeds and compost. Perfect for city dwellers.',
    category: 'Community',
    cost: 18.00,
    imageUrl:
        'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Community Garden',
    daysOffset: 8,
    hoursOffset: 10,
    bookmarkedCount: 43,
    interestedCount: 113,
  ),
  _EventTemplate(
    titlePrefix: 'Bachata Dance Social',
    description:
        'A sensual bachata social with a beginner lesson at 7 PM. Resident DJ spins authentic '
        'Dominican bachata and modern fusion. No partner required. All levels welcome.',
    category: 'Dance',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1545959570-a94084071b5d?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Latin Dance Studio',
    daysOffset: 4,
    hoursOffset: 19,
    bookmarkedCount: 107,
    interestedCount: 284,
  ),
  _EventTemplate(
    titlePrefix: 'Startup Pitch Night',
    description:
        'Six pre-seed founders pitch their startups to a live audience and investor panel. '
        'Public voting for audience favorite. Free to attend. Networking after the pitches.',
    category: 'Technology',
    imageUrl:
        'https://images.unsplash.com/photo-1559136555-9303baea8ebd?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Startup Hub',
    daysOffset: 7,
    hoursOffset: 18,
    bookmarkedCount: 119,
    interestedCount: 316,
  ),
  _EventTemplate(
    titlePrefix: 'Sunset Beach Volleyball',
    description:
        'Casual 4-on-4 beach volleyball with rotating teams at sunset. All skill levels welcome. '
        'Bring sunscreen and water. Organizer brings the net and ball. Totally free.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Beach Courts',
    daysOffset: 1,
    hoursOffset: 17,
    bookmarkedCount: 72,
    interestedCount: 191,
  ),
  _EventTemplate(
    titlePrefix: 'Baking & Pastry Masterclass',
    description:
        'A hands-on class with a professional pastry chef covering croissants, éclairs, and tarts. '
        'All ingredients provided. Take home your creations. Aprons supplied.',
    category: 'Food',
    cost: 55.00,
    imageUrl:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Culinary Academy',
    daysOffset: 11,
    hoursOffset: 12,
    bookmarkedCount: 88,
    interestedCount: 234,
  ),
  _EventTemplate(
    titlePrefix: 'Guided Meditation in the Park',
    description:
        'Start your Sunday with a 45-minute guided outdoor meditation session. A certified '
        'mindfulness teacher leads the practice. Bring a mat or blanket. Free for all.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1602192509154-0b900ee1f851?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'City Park Lawn',
    daysOffset: 2,
    hoursOffset: 8,
    bookmarkedCount: 61,
    interestedCount: 162,
  ),
  _EventTemplate(
    titlePrefix: 'Film Score Live Concert',
    description:
        'The city symphony performs iconic film scores from Zimmer, Williams, and Morricone. '
        'Clips from the films play on screen above the orchestra. Formal attire optional.',
    category: 'Music',
    cost: 40.00,
    imageUrl:
        'https://images.unsplash.com/photo-1507838153414-b4b713384a76?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Symphony Hall',
    daysOffset: 12,
    hoursOffset: 19,
    bookmarkedCount: 153,
    interestedCount: 407,
  ),
  _EventTemplate(
    titlePrefix: 'Creative Writing Workshop',
    description:
        'A 2-hour workshop for aspiring writers covering character development, dialogue, '
        'and scene structure. Write a short scene in class, share, and get peer feedback.',
    category: 'Arts',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1455390582262-044cdead277a?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Bookshop & Café',
    daysOffset: 9,
    hoursOffset: 14,
    bookmarkedCount: 46,
    interestedCount: 122,
  ),
  _EventTemplate(
    titlePrefix: 'Tennis Round Robin',
    description:
        'Join a friendly round-robin tennis tournament at the city courts. All levels welcome. '
        'Bring your own racket. Organizer provides balls. Post-match refreshments.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'City Tennis Courts',
    daysOffset: 5,
    hoursOffset: 9,
    bookmarkedCount: 55,
    interestedCount: 145,
  ),
  _EventTemplate(
    titlePrefix: 'Community Mural Painting Day',
    description:
        'Help paint a large outdoor mural celebrating local history and culture. No art experience '
        'needed. Paints and brushes provided. A professional muralist leads the project.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Community Wall',
    daysOffset: 8,
    hoursOffset: 10,
    bookmarkedCount: 89,
    interestedCount: 236,
  ),
  _EventTemplate(
    titlePrefix: 'Neon & Glow Dance Party',
    description:
        'An 80s-inspired neon glow rave with themed costumes, blacklight décor, and a DJ playing '
        'retro and modern electronic bangers. Free glow sticks at entry. 18+.',
    category: 'Dance',
    cost: 18.00,
    imageUrl:
        'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Event Warehouse',
    daysOffset: 5,
    hoursOffset: 21,
    bookmarkedCount: 214,
    interestedCount: 569,
  ),
  _EventTemplate(
    titlePrefix: 'Morning Tai Chi in the Park',
    description:
        'A gentle 60-minute tai chi session guided by a certified instructor. Perfect for stress '
        'relief and flexibility. Suitable for all ages and fitness levels. Bring comfortable shoes.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Botanical Gardens',
    daysOffset: 1,
    hoursOffset: 7,
    bookmarkedCount: 37,
    interestedCount: 98,
  ),
  _EventTemplate(
    titlePrefix: 'Holiday Craft Fair',
    description:
        'Shop unique handmade gifts, jewelry, candles, ornaments, and artwork from 40+ local '
        'artisans. Admission free. Hot cider and cookies on arrival. Gift wrapping available.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1513519245088-0e12902e35a5?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Civic Center',
    daysOffset: 10,
    hoursOffset: 10,
    bookmarkedCount: 167,
    interestedCount: 443,
  ),
  _EventTemplate(
    titlePrefix: 'Drone Racing Showcase',
    description:
        'Watch FPV drone pilots navigate technical race courses at high speed. Open to all spectators. '
        'Try a simulator station on site. Racer Q&A after the final heat. Free entry.',
    category: 'Technology',
    imageUrl:
        'https://images.unsplash.com/photo-1579829366248-204fe8413f31?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Sports Arena',
    daysOffset: 6,
    hoursOffset: 13,
    bookmarkedCount: 101,
    interestedCount: 268,
  ),
  _EventTemplate(
    titlePrefix: 'Poetry Slam Night',
    description:
        'A competitive spoken word event where poets have 3 minutes to move the audience. '
        'Sign up to perform or come to cheer. Judges drawn from the crowd. All topics welcome.',
    category: 'Arts',
    cost: 8.00,
    imageUrl:
        'https://images.unsplash.com/photo-1567427018141-0584cfcbf1b8?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Spoken Word Café',
    daysOffset: 7,
    hoursOffset: 19,
    bookmarkedCount: 63,
    interestedCount: 166,
  ),
  _EventTemplate(
    titlePrefix: 'Sustainable Living Fair',
    description:
        'Exhibitors showcasing zero-waste products, solar energy, urban farming, and ethical fashion. '
        'Free workshops every hour. Kids\' upcycling station. Free entry all day.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Convention Center',
    daysOffset: 9,
    hoursOffset: 9,
    bookmarkedCount: 94,
    interestedCount: 249,
  ),
  _EventTemplate(
    titlePrefix: 'Ghost Tour of Historic District',
    description:
        'A 90-minute lantern-lit walking tour through the oldest parts of town. Your guide shares '
        'true local ghost stories and urban legends. Adults and older teens only.',
    category: 'Social',
    cost: 18.00,
    imageUrl:
        'https://images.unsplash.com/photo-1509557965875-b88c97052f0e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Old Town Square',
    daysOffset: 4,
    hoursOffset: 20,
    bookmarkedCount: 82,
    interestedCount: 217,
  ),
  _EventTemplate(
    titlePrefix: 'Rock Climbing Open Gym Night',
    description:
        'Open gym night at the climbing center — all walls open, no classes, just climb. '
        'Day pass included in ticket. Rentals available. Coaches on the floor for tips.',
    category: 'Sports',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Climbing Center',
    daysOffset: 3,
    hoursOffset: 18,
    bookmarkedCount: 79,
    interestedCount: 209,
  ),
  _EventTemplate(
    titlePrefix: 'Sushi Making Class',
    description:
        'Learn to roll maki, shape nigiri, and make spicy tuna from scratch with a sushi chef. '
        'All ingredients provided. Enjoy your creations with sake pairings afterward.',
    category: 'Food',
    cost: 60.00,
    imageUrl:
        'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Japanese Restaurant',
    daysOffset: 12,
    hoursOffset: 17,
    bookmarkedCount: 97,
    interestedCount: 257,
  ),
  _EventTemplate(
    titlePrefix: 'Bachata & Salsa Latin Night',
    description:
        'Bachata at 8 PM, salsa at 10 PM — two genres, one incredible night. Live DJ, '
        'two instructors on the floor all evening. Beginner-friendly. Couples and singles welcome.',
    category: 'Dance',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1535525153412-5a42439a210d?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Latin Social Club',
    daysOffset: 4,
    hoursOffset: 20,
    bookmarkedCount: 172,
    interestedCount: 457,
  ),
  _EventTemplate(
    titlePrefix: 'Architecture & Heritage Walk',
    description:
        'A guided 90-minute walking tour highlighting the city\'s architectural history from '
        'Victorian homes to mid-century modern. Narrated by a local historian.',
    category: 'Social',
    cost: 12.00,
    imageUrl:
        'https://images.unsplash.com/photo-1486325212027-8081e485255e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Visitor Center',
    daysOffset: 5,
    hoursOffset: 11,
    bookmarkedCount: 54,
    interestedCount: 143,
  ),
  _EventTemplate(
    titlePrefix: 'Chess Club Tournament',
    description:
        'Monthly club tournament — Swiss format, 5 rounds, G/30 time control. '
        'Beginners welcome for casual play on side boards. Trophy for the winner.',
    category: 'Fun & Games',
    cost: 5.00,
    imageUrl:
        'https://images.unsplash.com/photo-1580541832626-2a7131ee809f?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Library Meeting Room',
    daysOffset: 8,
    hoursOffset: 13,
    bookmarkedCount: 38,
    interestedCount: 101,
  ),
  _EventTemplate(
    titlePrefix: 'Drum Circle & Sound Bath',
    description:
        'An immersive communal drum circle and sound healing session led by a certified '
        'sound therapist. Instruments provided. Leave feeling grounded and recharged.',
    category: 'Wellness',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Healing Arts Center',
    daysOffset: 7,
    hoursOffset: 16,
    bookmarkedCount: 59,
    interestedCount: 156,
  ),
  _EventTemplate(
    titlePrefix: 'Retro Gaming Arcade Night',
    description:
        'Play free-play classics from the 80s and 90s: Pac-Man, Street Fighter, Mario Kart, and more. '
        '40+ machines on free play all evening. Pizza and drinks for sale. All ages.',
    category: 'Fun & Games',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Retro Arcade Bar',
    daysOffset: 3,
    hoursOffset: 18,
    bookmarkedCount: 148,
    interestedCount: 393,
  ),
  _EventTemplate(
    titlePrefix: 'Vegan Food Pop-Up Market',
    description:
        'A curated pop-up market featuring 15+ vegan food vendors — burgers, ice cream, cheese, '
        'baked goods, and global street food. Cooking demos every 30 minutes.',
    category: 'Food',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Urban Market Hall',
    daysOffset: 5,
    hoursOffset: 11,
    bookmarkedCount: 132,
    interestedCount: 351,
  ),
  _EventTemplate(
    titlePrefix: 'Graphic Novel & Comic Art Workshop',
    description:
        'A beginner-friendly workshop on sequential art storytelling — paneling, character design, '
        'and inking. A published comic artist leads the class. Materials provided.',
    category: 'Arts',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1618519764620-7403abdbdfe9?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Comic Arts Studio',
    daysOffset: 11,
    hoursOffset: 13,
    bookmarkedCount: 67,
    interestedCount: 178,
  ),
  _EventTemplate(
    titlePrefix: 'Pool Party & DJ Set',
    description:
        'Poolside DJ set from 2 PM to 8 PM with international vibes. Food truck on site. '
        'Sunscreen stations. RSVP required for entry. Limited wristbands. 18+.',
    category: 'Social',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Rooftop Pool',
    daysOffset: 6,
    hoursOffset: 14,
    bookmarkedCount: 227,
    interestedCount: 603,
  ),
  _EventTemplate(
    titlePrefix: 'Half Marathon Training Group',
    description:
        'Join our weekly training run for the upcoming half marathon. Coached 8-mile long run '
        'with pace groups from 8 to 13 min/mile. Free water and gels at mile 5.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Running Track',
    daysOffset: 2,
    hoursOffset: 6,
    bookmarkedCount: 74,
    interestedCount: 196,
  ),
  _EventTemplate(
    titlePrefix: 'Cocktail Mixology Class',
    description:
        'Learn to craft six classic and contemporary cocktails with a professional bartender. '
        'Each guest makes their own drinks and takes home a recipe card. 21+ event.',
    category: 'Food',
    cost: 45.00,
    imageUrl:
        'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Cocktail Bar',
    daysOffset: 8,
    hoursOffset: 18,
    bookmarkedCount: 109,
    interestedCount: 289,
  ),
  _EventTemplate(
    titlePrefix: 'Guitar for Beginners Workshop',
    description:
        'A 3-hour beginner guitar workshop covering chords, strumming patterns, and your first song. '
        'Acoustic guitars provided. Small group of 8 ensures personal instruction.',
    category: 'Music',
    cost: 30.00,
    imageUrl:
        'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Music School',
    daysOffset: 9,
    hoursOffset: 14,
    bookmarkedCount: 58,
    interestedCount: 153,
  ),
  _EventTemplate(
    titlePrefix: 'Mini Golf Tournament',
    description:
        'A fun 18-hole mini golf tournament with prizes for lowest score, closest-to-pin, '
        'and hole-in-one. Great for all ages. Snack bar and drinks available.',
    category: 'Fun & Games',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Adventure Golf Park',
    daysOffset: 4,
    hoursOffset: 12,
    bookmarkedCount: 91,
    interestedCount: 241,
  ),
  _EventTemplate(
    titlePrefix: 'Volunteer Beach Cleanup',
    description:
        'Join hundreds of volunteers for a citywide beach and shoreline cleanup. '
        'Gloves and bags provided. Refreshments after. Certificate of appreciation for all participants.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1618477202872-89cec6f8f859?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Waterfront',
    daysOffset: 6,
    hoursOffset: 8,
    bookmarkedCount: 128,
    interestedCount: 340,
  ),
  _EventTemplate(
    titlePrefix: 'Contemporary Dance Showcase',
    description:
        'Three local contemporary dance companies perform original 20-minute pieces. '
        'Post-show reception with the dancers. Accessible seating available on request.',
    category: 'Dance',
    cost: 25.00,
    imageUrl:
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Performing Arts Center',
    daysOffset: 13,
    hoursOffset: 19,
    bookmarkedCount: 86,
    interestedCount: 228,
  ),
  _EventTemplate(
    titlePrefix: 'Plant Swap & Succulent Fair',
    description:
        'Bring cuttings, seeds, or potted plants to swap with fellow plant enthusiasts. '
        'No plant? No problem — buy from vendors starting at \$2. Expert advice available.',
    category: 'Markets',
    imageUrl:
        'https://images.unsplash.com/photo-1463320726281-696a3cc57ac2?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Garden Center',
    daysOffset: 5,
    hoursOffset: 9,
    bookmarkedCount: 76,
    interestedCount: 201,
  ),
  _EventTemplate(
    titlePrefix: 'Improv Theater Show',
    description:
        'Long-form improv comedy where the cast creates an entirely improvised play from '
        'a single audience suggestion. Always different, always hilarious.',
    category: 'Fun & Games',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1503095396549-807759245b35?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Improv Theater',
    daysOffset: 6,
    hoursOffset: 19,
    bookmarkedCount: 98,
    interestedCount: 260,
  ),
  _EventTemplate(
    titlePrefix: 'Sunrise Trail Run',
    description:
        'A scenic 6-mile guided trail run at sunrise through forested park trails. '
        'Moderate difficulty. Trail shoes recommended. Coffee and bananas at the finish.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'State Park Trailhead',
    daysOffset: 3,
    hoursOffset: 6,
    bookmarkedCount: 84,
    interestedCount: 222,
  ),
  _EventTemplate(
    titlePrefix: 'Songwriters\' Circle',
    description:
        'An intimate in-the-round performance where five songwriters share original songs and '
        'the stories behind them. Acoustic instruments only. Audience participation welcome.',
    category: 'Music',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1549213783-8284d0336c4f?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Listening Room',
    daysOffset: 7,
    hoursOffset: 19,
    bookmarkedCount: 66,
    interestedCount: 175,
  ),
  _EventTemplate(
    titlePrefix: 'Mindful Journaling Workshop',
    description:
        'A guided journaling workshop using prompts for self-reflection, goal setting, and '
        'gratitude practice. Notebooks provided. Quiet, supportive environment.',
    category: 'Wellness',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1455390582262-044cdead277a?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Wellness Café',
    daysOffset: 9,
    hoursOffset: 11,
    bookmarkedCount: 44,
    interestedCount: 117,
  ),
  _EventTemplate(
    titlePrefix: 'Astronomy Night: Stargazing',
    description:
        'Head to a dark sky site with a local astronomy club for a guided stargazing evening. '
        'Telescopes provided. Learn to identify constellations, planets, and deep-sky objects.',
    category: 'Community',
    imageUrl:
        'https://images.unsplash.com/photo-1516912481808-3406841bd33c?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Dark Sky Observatory',
    daysOffset: 11,
    hoursOffset: 21,
    bookmarkedCount: 117,
    interestedCount: 310,
  ),
  _EventTemplate(
    titlePrefix: 'Tattoo & Body Art Expo',
    description:
        'Meet 60+ tattoo artists and body painters from across the country. Live tattooing, '
        'contests, vendors, and seminars. Book a spot with your favorite artist on site.',
    category: 'Arts',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1611501275019-9b5cda994e8d?q=80&w=800&auto=format&fit=crop',
    source: EventSource.ticketmaster,
    locationSuffix: 'Convention Center',
    daysOffset: 10,
    hoursOffset: 11,
    bookmarkedCount: 193,
    interestedCount: 512,
  ),
  _EventTemplate(
    titlePrefix: 'Skateboarding Jam & Showcase',
    description:
        'Local skaters take over the skate park for a daytime jam session with judged tricks, '
        'best-run prizes, and a spectator-friendly layout. Free to watch. Skaters skate free.',
    category: 'Sports',
    imageUrl:
        'https://images.unsplash.com/photo-1547447134-cd3f5c716030?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'Skate Park',
    daysOffset: 4,
    hoursOffset: 13,
    bookmarkedCount: 105,
    interestedCount: 279,
  ),
  _EventTemplate(
    titlePrefix: 'Digital Marketing Bootcamp',
    description:
        'A full-day workshop covering SEO, social media strategy, paid ads, and content marketing. '
        'Led by agency professionals. Certificate provided. Lunch included.',
    category: 'Technology',
    cost: 49.00,
    imageUrl:
        'https://images.unsplash.com/photo-1432888498266-38ffec3eaf0a?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Business Center',
    daysOffset: 13,
    hoursOffset: 9,
    bookmarkedCount: 83,
    interestedCount: 221,
  ),
  _EventTemplate(
    titlePrefix: 'Community Potluck Dinner',
    description:
        'Bring a dish from your culture or family recipe to share at a long community table. '
        'A welcoming evening of food, stories, and new friendships. All dietary needs welcome.',
    category: 'Food',
    imageUrl:
        'https://images.unsplash.com/photo-1530062845289-9109b2c9c868?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Community Hall',
    daysOffset: 7,
    hoursOffset: 17,
    bookmarkedCount: 88,
    interestedCount: 233,
  ),
  _EventTemplate(
    titlePrefix: 'Abstract Acrylic Painting Night',
    description:
        'Grab a canvas and splash bold colors in a guided abstract painting session. '
        'Wine, brushes, and all supplies included. No experience required. Pure creative freedom.',
    category: 'Arts',
    cost: 35.00,
    imageUrl:
        'https://images.unsplash.com/photo-1541367777708-7905fe3296c0?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Paint & Sip Studio',
    daysOffset: 2,
    hoursOffset: 19,
    bookmarkedCount: 122,
    interestedCount: 324,
  ),
  _EventTemplate(
    titlePrefix: 'Hiking & Photography Adventure',
    description:
        'A half-day guided hike with a focus on landscape and nature photography. '
        'A professional photographer accompanies the group and gives real-time feedback. '
        'Any camera welcome. Moderate 5-mile trail.',
    category: 'Wellness',
    imageUrl:
        'https://images.unsplash.com/photo-1501854140801-50d01698950b?q=80&w=800&auto=format&fit=crop',
    source: EventSource.instagram,
    locationSuffix: 'National Forest Trailhead',
    daysOffset: 5,
    hoursOffset: 7,
    bookmarkedCount: 76,
    interestedCount: 201,
  ),
  _EventTemplate(
    titlePrefix: 'Hot Sauce & Spicy Food Festival',
    description:
        'Taste hundreds of hot sauces from mild to extreme, featuring local and national artisan '
        'makers. Wing-eating contest, cooking demos, and merch. Milk available at every table.',
    category: 'Food',
    cost: 10.00,
    imageUrl:
        'https://images.unsplash.com/photo-1563245372-f21724e3856d?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Festival Grounds',
    daysOffset: 8,
    hoursOffset: 12,
    bookmarkedCount: 189,
    interestedCount: 503,
  ),
  _EventTemplate(
    titlePrefix: 'Networking Breakfast for Creatives',
    description:
        'A morning networking event specifically for designers, photographers, illustrators, '
        'musicians, and filmmakers. Structured introductions, portfolio sharing, and a keynote.',
    category: 'Social',
    cost: 15.00,
    imageUrl:
        'https://images.unsplash.com/photo-1528605248644-14dd04022da1?q=80&w=800&auto=format&fit=crop',
    source: EventSource.twitter,
    locationSuffix: 'Creative Agency',
    daysOffset: 3,
    hoursOffset: 8,
    bookmarkedCount: 67,
    interestedCount: 178,
  ),
  _EventTemplate(
    titlePrefix: 'Martial Arts & Self-Defense Class',
    description:
        'A practical self-defense class combining elements of Krav Maga and Brazilian jiu-jitsu. '
        'No experience required. Suitable for all genders and ages 15+. Wear comfortable clothes.',
    category: 'Sports',
    cost: 20.00,
    imageUrl:
        'https://images.unsplash.com/photo-1555597673-b21d5c935865?q=80&w=800&auto=format&fit=crop',
    source: EventSource.google,
    locationSuffix: 'Martial Arts Dojo',
    daysOffset: 6,
    hoursOffset: 17,
    bookmarkedCount: 93,
    interestedCount: 247,
  ),
  _EventTemplate(
    titlePrefix: 'Mushroom Foraging Walk',
    description:
        'A guided 3-hour foraging walk with a mycologist to identify edible and medicinal mushrooms. '
        'Learn safe harvesting techniques. Ends with a cooking demo using the day\'s forage.',
    category: 'Community',
    cost: 25.00,
    imageUrl:
        'https://images.unsplash.com/photo-1504192010706-dd7f569ee2be?q=80&w=800&auto=format&fit=crop',
    source: EventSource.local,
    locationSuffix: 'Forest Park',
    daysOffset: 5,
    hoursOffset: 9,
    bookmarkedCount: 58,
    interestedCount: 153,
  ),
  _EventTemplate(
    titlePrefix: 'Evening Salsa Street Festival',
    description:
        'Salsa music fills the streets with live bands, dance performances, food carts, and '
        'an outdoor dance floor open to everyone. Free entry. No experience needed to join in.',
    category: 'Dance',
    imageUrl:
        'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
    source: EventSource.facebook,
    locationSuffix: 'Main Street',
    daysOffset: 7,
    hoursOffset: 18,
    bookmarkedCount: 234,
    interestedCount: 622,
  ),
];

class _EventTemplate {
  final String titlePrefix;
  final String description;
  final String category;
  final double? cost;
  final String imageUrl;
  final EventSource source;
  final String locationSuffix;
  final int daysOffset;
  final int hoursOffset;
  final int bookmarkedCount;
  final int interestedCount;

  const _EventTemplate({
    required this.titlePrefix,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.source,
    required this.locationSuffix,
    required this.daysOffset,
    required this.hoursOffset,
    this.cost,
    this.bookmarkedCount = 0,
    this.interestedCount = 0,
  });
}

// ── Organiser name fragments for generated events ──────────────────────────────
const _kOrgPrefixes = [
  'Downtown', 'Riverside', 'Community', 'Metro', 'Uptown',
  'City', 'Eastside', 'Westside', 'Central', 'Neighborhood',
];

const _kOrgSuffixes = [
  'Events', 'Collective', 'Society', 'Foundation', 'Hub',
  'Co.', 'Network', 'Community', 'Group', 'Club',
];

// ── Venue/street name fragments ────────────────────────────────────────────────
const _kStreetNames = [
  'Main St', 'Oak Ave', 'Park Blvd', 'Elm St', 'Maple Dr',
  'Cedar Rd', 'Sunset Blvd', 'River Rd', 'Lake Dr', 'Hill St',
  'Valley Rd', 'Spring St', 'Peach St', 'Market St', 'Church St',
];

// ── Avatar background colours ──────────────────────────────────────────────────
const _kAvatarColors = [
  '6C5CE7', 'E1306C', '00B894', 'FDCB6E', 'E17055',
  '74B9FF', 'A29BFE', '00CEC9', 'FD79A8', 'FAB1A0',
];

/// Generates a deterministic list of 107 realistic events for [city] / [state] /
/// [zip]. Uses a simple hash of the city name as a seed so the same city always
/// returns the same events, but different cities return different events.
List<Event> _generateEventsForLocation(
  String city,
  String state,
  String zip,
  DateTime now,
) {
  // Derive a repeatable seed from the city name.
  int seed = 0;
  for (final ch in city.toLowerCase().codeUnits) {
    seed = (seed * 31 + ch) & 0x7FFFFFFF;
  }

  int _rand(int seed, int mod) => ((seed * 1664525 + 1013904223) & 0x7FFFFFFF) % mod;

  // Snap to midnight so hoursOffset is treated as a clock hour (e.g. 19 = 7 PM),
  // not "X hours from right now", which would leak the current wall-clock time.
  final midnight = DateTime(now.year, now.month, now.day);

  final events = <Event>[];
  int s = seed;

  for (int i = 0; i < _kTemplates.length; i++) {
    final t = _kTemplates[i];
    s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;

    final streetNum = 100 + _rand(s, 900);
    s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;
    final streetName = _kStreetNames[_rand(s, _kStreetNames.length)];
    s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;
    final orgPrefix = _kOrgPrefixes[_rand(s, _kOrgPrefixes.length)];
    s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;
    final orgSuffix = _kOrgSuffixes[_rand(s, _kOrgSuffixes.length)];
    s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;
    final avatarColor = _kAvatarColors[_rand(s, _kAvatarColors.length)];

    final organiser = '$city $orgPrefix $orgSuffix';
    final address = '$streetNum $streetName';

    // Jitter coordinates within ~0.009 degrees (~1 km) of the city centre.
    final coords = _coordsForCity(city);
    double lat = 0, lng = 0;
    if (coords != null) {
      s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;
      final latJitter = ((_rand(s, 200) - 100) / 10000.0); // ±0.01°
      s = (s * 1664525 + 1013904223) & 0x7FFFFFFF;
      final lngJitter = ((_rand(s, 200) - 100) / 10000.0);
      lat = coords[0] + latJitter;
      lng = coords[1] + lngJitter;
    }

    events.add(Event(
      id: 'gen_${city.toLowerCase().replaceAll(' ', '_')}_$i',
      title: '${t.titlePrefix} — $city',
      description: t.description,
      dateTime: midnight.add(Duration(days: t.daysOffset, hours: t.hoursOffset)),
      location: '$city ${t.locationSuffix}',
      address: address,
      city: city,
      state: state,
      zipCode: zip,
      cost: t.cost,
      imageUrl: t.imageUrl,
      category: t.category,
      organizerName: organiser,
      organizerAvatarUrl:
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(organiser)}&size=200&background=$avatarColor&color=fff',
      bookmarkedCount: t.bookmarkedCount,
      interestedCount: t.interestedCount,
      source: t.source,
      latitude: lat,
      longitude: lng,
    ));
  }

  return events;
}

class EventRepository {
  /// Looks up a single event by [id]. Returns `null` if the event is not found.
  /// Used by the deep link route handler when `state.extra` is absent (cold start).
  Future<Event?> getEventById(String id) async {
    final all = await getUpcomingEvents();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Event>> getUpcomingEvents() async {
    await Future.delayed(const Duration(milliseconds: 700));
    final now = DateTime.now();
    // Snap to midnight so adding hours produces a fixed clock time (e.g. 19 = 7:00 PM),
    // not "current time + N hours" which would change every time the app is opened.
    final midnight = DateTime(now.year, now.month, now.day);
    return [
      // ── FACEBOOK EVENTS ────────────────────────────────────────────────────
      Event(
        id: 'evt_fb_001',
        title: 'Sunset Yoga in the Park',
        description:
            'Join us for a relaxing outdoor yoga session as the sun sets over Riverside Park. All levels welcome — bring your own mat or borrow one of ours. We\'ll flow through gentle poses while enjoying the evening breeze. Water and light snacks provided afterward.',
        dateTime: midnight.add(const Duration(days: 2, hours: 18)),
        location: 'Riverside Park',
        address: '475 Riverside Dr',
        city: 'New York',
        state: 'NY',
        zipCode: '10115',
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800&auto=format&fit=crop',
        category: 'Wellness',
        organizerName: 'Zen Community NYC',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Zen+Community&size=200&background=6C5CE7&color=fff',
        bookmarkedCount: 47,
        interestedCount: 128,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 40.7851, longitude: -73.9683,
      ),
      Event(
        id: 'evt_fb_002',
        title: 'Neighborhood Block Party & BBQ',
        description:
            'Our annual summer block party is back! Bring a dish to share, enjoy live music from local bands, kids\' games, a raffle, and the best BBQ in the neighborhood. Vegetarian options available. Free for all residents.',
        dateTime: midnight.add(const Duration(days: 5, hours: 12)),
        location: 'Elm Street Cul-de-Sac',
        address: '200 Elm Street',
        city: 'Austin',
        state: 'TX',
        zipCode: '78701',
        imageUrl: 'https://images.unsplash.com/photo-1529543544282-ea669407fca3?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'Elm Street Neighbors',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Elm+Street&size=200&background=00B894&color=fff',
        bookmarkedCount: 83,
        interestedCount: 241,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 30.2641, longitude: -97.7413,
      ),
      Event(
        id: 'evt_fb_003',
        title: 'Local Makers Market',
        description:
            'Discover handcrafted goods from 30+ local artisans. From handmade jewelry to organic candles, find unique treasures while supporting small businesses in our community. Live folk music all day.',
        dateTime: midnight.add(const Duration(days: 5, hours: 10)),
        location: 'Community Hall',
        address: '210 Main St',
        city: 'Brooklyn',
        state: 'NY',
        zipCode: '11201',
        cost: 5.00,
        imageUrl: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?q=80&w=800&auto=format&fit=crop',
        category: 'Markets',
        organizerName: 'Brooklyn Makers',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Brooklyn+Makers&size=200&background=00B894&color=fff',
        bookmarkedCount: 89,
        interestedCount: 245,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 40.6892, longitude: -73.9498,
      ),
      Event(
        id: 'evt_fb_004',
        title: 'Community Garden Work Day',
        description:
            'Help us tend to the community garden! We\'ll be planting spring vegetables, weeding, and building a new compost station. All tools provided. Great for families and kids who want to learn about growing food.',
        dateTime: midnight.add(const Duration(days: 3, hours: 9)),
        location: 'Jefferson Community Garden',
        address: '400 Jefferson Ave',
        city: 'Chicago',
        state: 'IL',
        zipCode: '60611',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'Green Thumb Chicago',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Green+Thumb&size=200&background=00CEC9&color=fff',
        bookmarkedCount: 31,
        interestedCount: 76,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 41.8799, longitude: -87.6290,
      ),

      // ── INSTAGRAM EVENTS ───────────────────────────────────────────────────
      Event(
        id: 'evt_ig_001',
        title: 'Golden Hour Photography Walk',
        description:
            'Join fellow photographers for a guided walk through the arts district during golden hour. Perfect for all skill levels — from iPhone photographers to DSLR enthusiasts. We\'ll share tips, explore hidden spots, and end at a rooftop café.',
        dateTime: midnight.add(const Duration(days: 1, hours: 18)),
        location: 'Arts District',
        address: '100 Arts District Blvd',
        city: 'Los Angeles',
        state: 'CA',
        zipCode: '90021',
        imageUrl: 'https://images.unsplash.com/photo-1502982720700-bfff97f2ecac?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: '@lastreetshots',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=LA+Shots&size=200&background=E1306C&color=fff',
        bookmarkedCount: 156,
        interestedCount: 389,
        source: EventSource.instagram,
        sourceUrl: 'https://instagram.com',
        latitude: 34.0474, longitude: -118.2365,
      ),
      Event(
        id: 'evt_ig_002',
        title: 'Rooftop Sunset Soirée',
        description:
            'An intimate rooftop gathering with curated cocktails, ambient music, and stunning city views. Limited to 60 guests for an exclusive atmosphere. Dress code: smart casual. Ticket includes 2 drinks.',
        dateTime: midnight.add(const Duration(days: 4, hours: 19)),
        location: 'The Penthouse at 5th',
        address: '505 5th Ave',
        city: 'New York',
        state: 'NY',
        zipCode: '10017',
        cost: 35.00,
        imageUrl: 'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?q=80&w=800&auto=format&fit=crop',
        category: 'Social',
        organizerName: '@nycevents_co',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=NYC+Events&size=200&background=FD79A8&color=fff',
        bookmarkedCount: 203,
        interestedCount: 512,
        source: EventSource.instagram,
        sourceUrl: 'https://instagram.com',
        latitude: 40.7589, longitude: -73.9851,
      ),
      Event(
        id: 'evt_ig_003',
        title: 'Pop-Up Plant Market',
        description:
            'Rare and exotic houseplants, succulents, and tropical beauties from local growers. Plus workshops on plant care, macramé hangers, and terrariums. Pet-friendly and family-welcoming!',
        dateTime: midnight.add(const Duration(days: 6, hours: 10)),
        location: 'The Plant Collective',
        address: '220 Green Way',
        city: 'Portland',
        state: 'OR',
        zipCode: '97201',
        cost: 3.00,
        imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?q=80&w=800&auto=format&fit=crop',
        category: 'Markets',
        organizerName: '@pdx.botanicals',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=PDX+Botanicals&size=200&background=55EFC4&color=fff',
        bookmarkedCount: 74,
        interestedCount: 198,
        source: EventSource.instagram,
        sourceUrl: 'https://instagram.com',
        latitude: 45.5234, longitude: -122.6762,
      ),

      // ── TWITTER / X EVENTS ─────────────────────────────────────────────────
      Event(
        id: 'evt_tw_001',
        title: '#BuildInPublic Hackathon',
        description:
            'A 12-hour hackathon for indie developers and makers. Build anything — apps, tools, websites — and demo live at the end. All skill levels welcome. Prizes, pizza, and networking included. Co-working space provided.',
        dateTime: midnight.add(const Duration(days: 3, hours: 9)),
        location: 'Founders Space',
        address: '300 Innovation Dr',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94105',
        cost: 10.00,
        imageUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=800&auto=format&fit=crop',
        category: 'Technology',
        organizerName: '@buildinpublic_sf',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=BIP+SF&size=200&background=14171A&color=fff',
        bookmarkedCount: 112,
        interestedCount: 340,
        source: EventSource.twitter,
        sourceUrl: 'https://x.com',
        latitude: 37.7844, longitude: -122.3965,
      ),
      Event(
        id: 'evt_tw_002',
        title: 'Tech Twitter Meetup — AI Edition',
        description:
            'The monthly Tech Twitter meetup is back with an AI focus. Talks on LLMs, AI art, and the future of work, followed by open networking. Free drinks for the first 50 through the door. RSVP via the link in bio.',
        dateTime: midnight.add(const Duration(days: 8, hours: 18)),
        location: 'WeWork SOMA',
        address: '1 Front St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94111',
        imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=800&auto=format&fit=crop',
        category: 'Technology',
        organizerName: '@tech_twitter_sf',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Tech+Twitter&size=200&background=1DA1F2&color=fff',
        bookmarkedCount: 88,
        interestedCount: 267,
        source: EventSource.twitter,
        sourceUrl: 'https://x.com',
        latitude: 37.7929, longitude: -122.3986,
      ),
      Event(
        id: 'evt_tw_003',
        title: 'Writers\' Room Open Mic',
        description:
            'Organized by the #WritingCommunity on X — an open mic for prose, poetry, essays, and short stories. 5 minutes per reader. Supportive audience guaranteed. Sign up at the door. Coffee and pastries provided.',
        dateTime: midnight.add(const Duration(days: 2, hours: 19)),
        location: 'The Literary Parlor',
        address: '12 Book Lane',
        city: 'Seattle',
        state: 'WA',
        zipCode: '98101',
        imageUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: '@writingcommunity',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Writers+Room&size=200&background=657786&color=fff',
        bookmarkedCount: 55,
        interestedCount: 134,
        source: EventSource.twitter,
        sourceUrl: 'https://x.com',
        latitude: 47.6097, longitude: -122.3285,
      ),

      // ── GOOGLE EVENTS ──────────────────────────────────────────────────────
      Event(
        id: 'evt_gg_001',
        title: 'Street Food Festival',
        description:
            'Taste flavors from around the world! Over 20 food trucks and stalls serving everything from Thai to Mexican. Live music and family-friendly activities all day. No ticket needed — just show up and enjoy.',
        dateTime: midnight.add(const Duration(days: 4, hours: 11)),
        location: 'Prospect Park West',
        address: '15th St & Prospect Park W',
        city: 'Brooklyn',
        state: 'NY',
        zipCode: '11215',
        imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop',
        category: 'Food',
        organizerName: 'BK Food Scene',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=BK+Food&size=200&background=FF7675&color=fff',
        bookmarkedCount: 142,
        interestedCount: 410,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 40.6601, longitude: -73.9689,
      ),
      Event(
        id: 'evt_gg_002',
        title: 'Farmers\' Market — Organic & Local',
        description:
            'Every Saturday morning, local farmers and producers gather to sell seasonal produce, honey, jam, bread, and more. Bring your own bags, cash welcome. Live music from 9–11 AM.',
        dateTime: midnight.add(const Duration(days: 1, hours: 8)),
        location: 'City Plaza',
        address: '1 Main Plaza',
        city: 'Denver',
        state: 'CO',
        zipCode: '80202',
        imageUrl: 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?q=80&w=800&auto=format&fit=crop',
        category: 'Markets',
        organizerName: 'Denver Fresh Market',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Denver+Market&size=200&background=FDCB6E&color=fff',
        bookmarkedCount: 98,
        interestedCount: 276,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 39.7481, longitude: -104.9995,
      ),
      Event(
        id: 'evt_gg_003',
        title: 'Free Outdoor Concert — Jazz in the Square',
        description:
            'A free afternoon of live jazz in the town square. Local jazz quartet plays classic standards and originals. Bring a blanket, lawn chairs, and a picnic. All ages welcome.',
        dateTime: midnight.add(const Duration(days: 3, hours: 14)),
        location: 'Washington Square',
        address: 'Washington Square Park',
        city: 'New Orleans',
        state: 'LA',
        zipCode: '70116',
        imageUrl: 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?q=80&w=800&auto=format&fit=crop',
        category: 'Music',
        organizerName: 'NOLA Music Foundation',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=NOLA+Music&size=200&background=FDAA3D&color=fff',
        bookmarkedCount: 167,
        interestedCount: 488,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 29.9577, longitude: -90.0638,
      ),
      Event(
        id: 'evt_gg_004',
        title: 'Indie Film Screening',
        description:
            'Watch three award-winning short films from local filmmakers followed by a live Q&A session. Popcorn and drinks included in admission. Doors open 30 minutes before showtime.',
        dateTime: midnight.add(const Duration(days: 7, hours: 19)),
        location: 'Cinema Village',
        address: '22 E 12th St',
        city: 'Manhattan',
        state: 'NY',
        zipCode: '10003',
        cost: 12.00,
        imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: 'NYC Film Collective',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=NYC+Film&size=200&background=FDAA3D&color=fff',
        bookmarkedCount: 55,
        interestedCount: 167,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 40.7319, longitude: -73.9949,
      ),
      Event(
        id: 'evt_gg_005',
        title: 'Family Fun Day at the Science Museum',
        description:
            'Free family admission day at the city science museum. Hands-on exhibits, live science shows, a planetarium screening, and a kids\' robotics workshop. Arrive early — capacity is limited.',
        dateTime: midnight.add(const Duration(days: 6, hours: 10)),
        location: 'City Science Museum',
        address: '1025 Natural Science Pkwy',
        city: 'Houston',
        state: 'TX',
        zipCode: '77002',
        imageUrl: 'https://images.unsplash.com/photo-1564859228273-274232fdb516?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'Houston Science Center',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Houston+Science&size=200&background=74B9FF&color=fff',
        bookmarkedCount: 119,
        interestedCount: 335,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 29.7218, longitude: -95.3897,
      ),

      // ── TICKETMASTER EVENTS ────────────────────────────────────────────────
      Event(
        id: 'evt_tm_001',
        title: 'Open Mic Night',
        description:
            'Share your talent or enjoy performances from local musicians, poets, and comedians. Sign up at the door or just come to watch. Drinks and snacks available from the bar all night.',
        dateTime: midnight.add(const Duration(days: 1, hours: 20)),
        location: 'The Velvet Lounge',
        address: '88 Bedford Ave',
        city: 'Brooklyn',
        state: 'NY',
        zipCode: '11211',
        imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=800&auto=format&fit=crop',
        category: 'Music',
        organizerName: 'Velvet Sessions',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Velvet+Sessions&size=200&background=E17055&color=fff',
        bookmarkedCount: 63,
        interestedCount: 192,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 40.7142, longitude: -73.9596,
      ),
      Event(
        id: 'evt_tm_002',
        title: 'Beginner Salsa Workshop',
        description:
            'No experience needed! Learn basic salsa steps in a fun, judgment-free environment. Partners rotated throughout the class. Wear comfortable shoes — sneakers are perfect. Includes one free drink at the end.',
        dateTime: midnight.add(const Duration(days: 6, hours: 19)),
        location: 'Dance Studios NYC',
        address: '939 8th Ave',
        city: 'Manhattan',
        state: 'NY',
        zipCode: '10019',
        cost: 15.00,
        imageUrl: 'https://images.unsplash.com/photo-1504609813442-a8924e83f76e?q=80&w=800&auto=format&fit=crop',
        category: 'Dance',
        organizerName: 'Salsa Social',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Salsa+Social&size=200&background=FD79A8&color=fff',
        bookmarkedCount: 72,
        interestedCount: 198,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 40.7651, longitude: -73.9885,
      ),
      Event(
        id: 'evt_tm_003',
        title: 'The Midnight Collective — Live',
        description:
            'Indie rock band The Midnight Collective brings their electrifying live show to a small venue for an intimate night. Supporting act TBA. Doors at 7 PM, show at 8:30 PM. Ages 18+.',
        dateTime: midnight.add(const Duration(days: 9, hours: 20)),
        location: 'The Roxy',
        address: '9009 Sunset Blvd',
        city: 'Los Angeles',
        state: 'CA',
        zipCode: '90069',
        cost: 25.00,
        imageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=800&auto=format&fit=crop',
        category: 'Music',
        organizerName: 'The Roxy LA',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=The+Roxy&size=200&background=6C5CE7&color=fff',
        bookmarkedCount: 234,
        interestedCount: 671,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 34.0901, longitude: -118.3817,
      ),
      Event(
        id: 'evt_tm_004',
        title: 'Comedy Night: Rising Stars',
        description:
            'Six up-and-coming stand-up comedians take the stage for a hilarious evening of original material. Two drink minimum. Hosted by local comedian Ray Morales. Early bird tickets available.',
        dateTime: midnight.add(const Duration(days: 5, hours: 20)),
        location: 'Laughs Comedy Club',
        address: '1322 Michigan Ave',
        city: 'Chicago',
        state: 'IL',
        zipCode: '60605',
        cost: 18.00,
        imageUrl: 'https://images.unsplash.com/photo-1527224538127-2104bb71c51b?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: 'Laughs Comedy Club',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Laughs+Club&size=200&background=FFEAA7&color=333',
        bookmarkedCount: 101,
        interestedCount: 289,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 41.8703, longitude: -87.6239,
      ),
      Event(
        id: 'evt_tm_005',
        title: 'Board Game Night',
        description:
            'Bring your favorite games or try something new from our library of 60+ titles. Perfect for meeting new people in a fun, relaxed atmosphere. Snacks and drinks available. Ticket includes access to all games.',
        dateTime: midnight.add(const Duration(days: 2, hours: 19)),
        location: 'Hex & Co. Café',
        address: '1462 2nd Ave',
        city: 'Manhattan',
        state: 'NY',
        zipCode: '10075',
        cost: 8.00,
        imageUrl: 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?q=80&w=800&auto=format&fit=crop',
        category: 'Social',
        organizerName: 'Game Nights NYC',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Game+Nights&size=200&background=A29BFE&color=fff',
        bookmarkedCount: 38,
        interestedCount: 95,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 40.7765, longitude: -73.9552,
      ),
      Event(
        id: 'evt_tm_006',
        title: 'Morning 5K Fun Run',
        description:
            'A casual, timed 5K through Balboa Park for all fitness levels. Walkers, joggers, and runners all welcome. T-shirt and medal included. Post-race refreshments provided. Registration closes day before.',
        dateTime: midnight.add(const Duration(days: 4, hours: 7)),
        location: 'Balboa Park',
        address: '1549 El Prado',
        city: 'San Diego',
        state: 'CA',
        zipCode: '92101',
        cost: 20.00,
        imageUrl: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=800&auto=format&fit=crop',
        category: 'Wellness',
        organizerName: 'SD Run Club',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=SD+Run&size=200&background=00CEC9&color=fff',
        bookmarkedCount: 87,
        interestedCount: 224,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 32.7336, longitude: -117.1443,
      ),

      // ── LOCAL EVENTS ───────────────────────────────────────────────────────
      Event(
        id: 'evt_lc_001',
        title: 'Neighborhood Cleanup Drive',
        description:
            'Let\'s make our neighborhood shine! Gloves and bags provided. Refreshments after. Meet at the corner of 5th and Oak. Great volunteer opportunity — bring friends and family.',
        dateTime: midnight.add(const Duration(days: 3, hours: 9)),
        location: 'Oak Street Park',
        address: '5th & Oak St',
        city: 'Queens',
        state: 'NY',
        zipCode: '11375',
        imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'Green Streets',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Green+Streets&size=200&background=00CEC9&color=fff',
        bookmarkedCount: 31,
        interestedCount: 76,
        source: EventSource.local,
        latitude: 40.7200, longitude: -73.8143,
      ),
      Event(
        id: 'evt_lc_002',
        title: 'Watercolor Painting Workshop',
        description:
            'A beginner-friendly 2-hour watercolor class led by local artist Mara Lund. All materials provided. Learn basic techniques including wet-on-wet, washes, and blooms. Take your artwork home.',
        dateTime: midnight.add(const Duration(days: 10, hours: 11)),
        location: 'The Art Loft',
        address: '88 Creative Lane',
        city: 'Nashville',
        state: 'TN',
        zipCode: '37201',
        cost: 22.00,
        imageUrl: 'https://images.unsplash.com/photo-1502904550040-7534597429ae?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: 'The Art Loft',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Art+Loft&size=200&background=FD79A8&color=fff',
        bookmarkedCount: 44,
        interestedCount: 112,
        source: EventSource.local,
        latitude: 36.1651, longitude: -86.7789,
      ),
      Event(
        id: 'evt_lc_003',
        title: 'Church Bake Sale & Fundraiser',
        description:
            'Annual bake sale to raise funds for the local food pantry. Homemade pies, cakes, cookies, and breads. All proceeds go directly to community members in need. Cash only.',
        dateTime: midnight.add(const Duration(days: 2, hours: 10)),
        location: 'St. Andrew\'s Parish Hall',
        address: '340 Church Rd',
        city: 'Philadelphia',
        state: 'PA',
        zipCode: '19103',
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'St. Andrew\'s Church',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=St+Andrews&size=200&background=81ECEC&color=333',
        bookmarkedCount: 22,
        interestedCount: 58,
        source: EventSource.local,
        latitude: 39.9487, longitude: -75.1680,
      ),
      Event(
        id: 'evt_lc_004',
        title: 'Youth Basketball Tournament',
        description:
            'Annual 3-on-3 basketball tournament for ages 12–18. Teams of 3, round-robin format. Trophies for top 3 teams. Registration open until the day before. Free spectator entry. Concessions on site.',
        dateTime: midnight.add(const Duration(days: 7, hours: 10)),
        location: 'Eastside Rec Center',
        address: '200 Recreation Ave',
        city: 'Atlanta',
        state: 'GA',
        zipCode: '30303',
        imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=800&auto=format&fit=crop',
        category: 'Sports',
        organizerName: 'Atlanta Parks & Rec',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=ATL+Rec&size=200&background=FDAA3D&color=fff',
        bookmarkedCount: 61,
        interestedCount: 143,
        source: EventSource.local,
        latitude: 33.7560, longitude: -84.3960,
      ),
      Event(
        id: 'evt_lc_005',
        title: 'Monthly Book Club Meeting',
        description:
            'This month we\'re discussing "Tomorrow, and Tomorrow, and Tomorrow" by Gabrielle Zevin. New members welcome — no need to have read the book, just bring your curiosity. Coffee and tea provided.',
        dateTime: midnight.add(const Duration(days: 11, hours: 18)),
        location: 'Page One Bookshop',
        address: '55 Reading Row',
        city: 'Boston',
        state: 'MA',
        zipCode: '02108',
        imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?q=80&w=800&auto=format&fit=crop',
        category: 'Social',
        organizerName: 'Page One Book Club',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Book+Club&size=200&background=6C5CE7&color=fff',
        bookmarkedCount: 28,
        interestedCount: 64,
        source: EventSource.local,
        latitude: 42.3557, longitude: -71.0622,
      ),
      Event(
        id: 'evt_lc_006',
        title: 'Garage Sale — Entire Neighborhood',
        description:
            'Multi-family garage sale across 14 homes on Maple Drive. Furniture, clothes, electronics, books, toys, and more. Map provided at the corner of Maple & 3rd. Rain or shine.',
        dateTime: midnight.add(const Duration(days: 1, hours: 8)),
        location: 'Maple Drive',
        address: 'Maple Dr & 3rd Ave',
        city: 'Phoenix',
        state: 'AZ',
        zipCode: '85001',
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=800&auto=format&fit=crop',
        category: 'Markets',
        organizerName: 'Maple Drive Residents',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Maple+Drive&size=200&background=FAB1A0&color=333',
        bookmarkedCount: 15,
        interestedCount: 41,
        source: EventSource.local,
        latitude: 33.4408, longitude: -112.0826,
      ),

      // ── ADDITIONAL FACEBOOK EVENTS ─────────────────────────────────────────
      Event(
        id: 'evt_fb_005',
        title: 'Miami Beach Volleyball Tournament',
        description:
            'Casual 4-on-4 beach volleyball tournament open to all skill levels. Teams of 4, bring sunscreen. Round-robin format with prizes for the top two teams. Food and drinks on the beach.',
        dateTime: midnight.add(const Duration(days: 3, hours: 10)),
        location: 'South Beach Volleyball Courts',
        address: '1100 Ocean Dr',
        city: 'Miami',
        state: 'FL',
        zipCode: '33139',
        imageUrl: 'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?q=80&w=800&auto=format&fit=crop',
        category: 'Sports',
        organizerName: 'Miami Beach Sports',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Miami+Sports&size=200&background=FDCB6E&color=fff',
        bookmarkedCount: 94,
        interestedCount: 267,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 25.7741, longitude: -80.1901,
      ),
      Event(
        id: 'evt_fb_006',
        title: 'Dallas Night Market',
        description:
            'A vibrant night market with 40+ vendors selling street food, crafts, and vintage finds. Live DJs, neon lights, and a chill outdoor vibe. Free admission. Cash and card accepted.',
        dateTime: midnight.add(const Duration(days: 5, hours: 18)),
        location: 'Deep Ellum',
        address: '2700 Main St',
        city: 'Dallas',
        state: 'TX',
        zipCode: '75226',
        imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop',
        category: 'Markets',
        organizerName: 'Deep Ellum Events',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Deep+Ellum&size=200&background=E17055&color=fff',
        bookmarkedCount: 188,
        interestedCount: 503,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 32.7834, longitude: -96.7945,
      ),
      Event(
        id: 'evt_fb_007',
        title: 'Minneapolis Ice Skating Social',
        description:
            'Community ice skating night at the outdoor rink. Skate rentals available on site. Hot cocoa and cider provided. Family-friendly — all ages and skill levels. Music on the ice all evening.',
        dateTime: midnight.add(const Duration(days: 2, hours: 17)),
        location: 'The Depot Rink',
        address: '225 3rd Ave S',
        city: 'Minneapolis',
        state: 'MN',
        zipCode: '55401',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?q=80&w=800&auto=format&fit=crop',
        category: 'Sports',
        organizerName: 'Minneapolis Parks',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=MPLS+Parks&size=200&background=74B9FF&color=fff',
        bookmarkedCount: 72,
        interestedCount: 195,
        source: EventSource.facebook,
        sourceUrl: 'https://facebook.com/events',
        latitude: 44.9739, longitude: -93.2689,
      ),

      // ── ADDITIONAL INSTAGRAM EVENTS ────────────────────────────────────────
      Event(
        id: 'evt_ig_004',
        title: 'Las Vegas Drag Brunch',
        description:
            'The most fabulous brunch in the city. World-class drag performances, outrageous costumes, '
            'and a delicious brunch menu. Audience participation encouraged. Ages 21+.',
        dateTime: midnight.add(const Duration(days: 1, hours: 11)),
        location: 'The Neon Palm',
        address: '3700 Las Vegas Blvd S',
        city: 'Las Vegas',
        state: 'NV',
        zipCode: '89109',
        cost: 45.00,
        imageUrl: 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?q=80&w=800&auto=format&fit=crop',
        category: 'Food',
        organizerName: '@vegasdragbrunch',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Vegas+Drag&size=200&background=E1306C&color=fff',
        bookmarkedCount: 221,
        interestedCount: 589,
        source: EventSource.instagram,
        sourceUrl: 'https://instagram.com',
        latitude: 36.1147, longitude: -115.1728,
      ),
      Event(
        id: 'evt_ig_005',
        title: 'DC Cherry Blossom Picnic',
        description:
            'Join hundreds of locals for a community picnic under the cherry blossoms near the Tidal Basin. '
            'BYO food and blankets. Free entry. Live acoustic guitar from noon to 3 PM.',
        dateTime: midnight.add(const Duration(days: 4, hours: 12)),
        location: 'Tidal Basin',
        address: '900 Ohio Dr SW',
        city: 'Washington',
        state: 'DC',
        zipCode: '20024',
        imageUrl: 'https://images.unsplash.com/photo-1522383225653-ed111181a951?q=80&w=800&auto=format&fit=crop',
        category: 'Social',
        organizerName: '@dccommunity',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=DC+Community&size=200&background=A29BFE&color=fff',
        bookmarkedCount: 176,
        interestedCount: 461,
        source: EventSource.instagram,
        sourceUrl: 'https://instagram.com',
        latitude: 38.8839, longitude: -77.0365,
      ),
      Event(
        id: 'evt_ig_006',
        title: 'Pottery Pop-Up Studio',
        description:
            'Drop-in pottery sessions in a relaxed studio setting. Spin on the wheel or hand-build — '
            'instructor available for guidance. All materials included. Walk-ins welcome.',
        dateTime: midnight.add(const Duration(days: 8, hours: 13)),
        location: 'Clay & Co Studio',
        address: '44 Craft Row',
        city: 'Asheville',
        state: 'NC',
        zipCode: '28801',
        cost: 30.00,
        imageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: '@clay.and.co',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Clay+Co&size=200&background=81ECEC&color=333',
        bookmarkedCount: 49,
        interestedCount: 128,
        source: EventSource.instagram,
        sourceUrl: 'https://instagram.com',
        latitude: 35.5986, longitude: -82.5549,
      ),

      // ── ADDITIONAL GOOGLE EVENTS ───────────────────────────────────────────
      Event(
        id: 'evt_gg_006',
        title: 'Phoenix Desert Sunrise Run',
        description:
            'Beat the heat with an early morning group run through Camelback Mountain trails. '
            'Various distance options from 3–10 miles. Guided pacers for every level. Breakfast at the trailhead after.',
        dateTime: midnight.add(const Duration(days: 1, hours: 5)),
        location: 'Camelback Mountain Trailhead',
        address: '4925 E McDonald Dr',
        city: 'Phoenix',
        state: 'AZ',
        zipCode: '85018',
        imageUrl: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=800&auto=format&fit=crop',
        category: 'Wellness',
        organizerName: 'Desert Run Club',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Desert+Run&size=200&background=FDAA3D&color=fff',
        bookmarkedCount: 63,
        interestedCount: 168,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 33.5200, longitude: -111.9658,
      ),
      Event(
        id: 'evt_gg_007',
        title: 'Nashville Songwriter Circle',
        description:
            'In the round songwriter showcase featuring four Nashville writers sharing original songs and stories. '
            'Intimate listening room, full bar. Doors at 6:30 PM, show at 7:30 PM.',
        dateTime: midnight.add(const Duration(days: 6, hours: 19)),
        location: 'The Bluebird Café',
        address: '4104 Hillsboro Pike',
        city: 'Nashville',
        state: 'TN',
        zipCode: '37215',
        cost: 12.00,
        imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=800&auto=format&fit=crop',
        category: 'Music',
        organizerName: 'Nashville Songwriters',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Nashville+SW&size=200&background=6C5CE7&color=fff',
        bookmarkedCount: 145,
        interestedCount: 398,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 36.1320, longitude: -86.7987,
      ),
      Event(
        id: 'evt_gg_008',
        title: 'Denver Tech & Coffee Morning',
        description:
            'Monthly morning meetup for tech professionals. Informal networking over great coffee with a 15-minute lightning talk from a local engineer or founder. No agenda, just good conversation.',
        dateTime: midnight.add(const Duration(days: 9, hours: 8)),
        location: 'Common Grounds Coffee',
        address: '1550 17th St',
        city: 'Denver',
        state: 'CO',
        zipCode: '80202',
        imageUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?q=80&w=800&auto=format&fit=crop',
        category: 'Technology',
        organizerName: 'Denver Tech Community',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Denver+Tech&size=200&background=74B9FF&color=fff',
        bookmarkedCount: 77,
        interestedCount: 204,
        source: EventSource.google,
        sourceUrl: 'https://google.com/events',
        latitude: 39.7512, longitude: -104.9861,
      ),

      // ── ADDITIONAL TICKETMASTER EVENTS ────────────────────────────────────
      Event(
        id: 'evt_tm_007',
        title: 'Electronic Music Festival',
        description:
            'Three stages, eight DJs, and twelve hours of electronic music spanning house, techno, and '
            'drum & bass. Outdoor festival with immersive light installations and art. Ages 18+.',
        dateTime: midnight.add(const Duration(days: 5, hours: 14)),
        location: 'Riverside Amphitheater',
        address: '1300 River Rd',
        city: 'Chicago',
        state: 'IL',
        zipCode: '60610',
        cost: 40.00,
        imageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?q=80&w=800&auto=format&fit=crop',
        category: 'Music',
        organizerName: 'Chicago Rave Collective',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=CHI+Rave&size=200&background=6C5CE7&color=fff',
        bookmarkedCount: 312,
        interestedCount: 847,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 41.8839, longitude: -87.6369,
      ),
      Event(
        id: 'evt_tm_008',
        title: 'Improv Comedy Showcase',
        description:
            'Three improv comedy troupes face off in a jam-packed showcase of audience-driven scenes. '
            'Completely unscripted, hilarious every time. BYOB — mixers and cups provided.',
        dateTime: midnight.add(const Duration(days: 3, hours: 20)),
        location: 'The Second City',
        address: '230 W North Ave',
        city: 'Chicago',
        state: 'IL',
        zipCode: '60610',
        cost: 15.00,
        imageUrl: 'https://images.unsplash.com/photo-1527224538127-2104bb71c51b?q=80&w=800&auto=format&fit=crop',
        category: 'Arts',
        organizerName: 'Second City Chicago',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Second+City&size=200&background=FFEAA7&color=333',
        bookmarkedCount: 143,
        interestedCount: 389,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 41.9112, longitude: -87.6362,
      ),
      Event(
        id: 'evt_tm_009',
        title: 'Portland Trail Blazers Watch Party',
        description:
            'Official watch party for the big game at the city\'s largest sports bar. Giant screens, '
            'drink specials, giveaways, and meet-and-greet with a former player. Ages 21+.',
        dateTime: midnight.add(const Duration(days: 2, hours: 19)),
        location: 'McTavish\'s Sports Bar',
        address: '811 NW 21st Ave',
        city: 'Portland',
        state: 'OR',
        zipCode: '97209',
        imageUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=800&auto=format&fit=crop',
        category: 'Sports',
        organizerName: 'PDX Sports Social',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=PDX+Sports&size=200&background=E17055&color=fff',
        bookmarkedCount: 201,
        interestedCount: 534,
        source: EventSource.ticketmaster,
        sourceUrl: 'https://ticketmaster.com',
        latitude: 45.5231, longitude: -122.6945,
      ),

      // ── ADDITIONAL LOCAL EVENTS ────────────────────────────────────────────
      Event(
        id: 'evt_lc_007',
        title: 'Neighborhood Association Potluck',
        description:
            'Bring a dish to share and meet your neighbors! All cuisines welcome. We\'ll have '
            'lawn games, a raffle, and a short community update from the association. Kids and pets welcome.',
        dateTime: midnight.add(const Duration(days: 6, hours: 17)),
        location: 'Greenfield Park Pavilion',
        address: '300 Greenfield Rd',
        city: 'Columbus',
        state: 'OH',
        zipCode: '43215',
        imageUrl: 'https://images.unsplash.com/photo-1529543544282-ea669407fca3?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'Greenfield NA',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Greenfield+NA&size=200&background=00B894&color=fff',
        bookmarkedCount: 28,
        interestedCount: 74,
        source: EventSource.local,
        latitude: 39.9612, longitude: -82.9988,
      ),
      Event(
        id: 'evt_lc_008',
        title: 'Beginner Hiking Club — First Sunday',
        description:
            'Monthly beginner-friendly hike on a well-marked trail. 4–6 miles, mostly flat. '
            'Group pace, no one left behind. Carpooling available from the library parking lot.',
        dateTime: midnight.add(const Duration(days: 4, hours: 8)),
        location: 'Ridgeline Trailhead',
        address: '8200 Ridgeline Rd',
        city: 'Seattle',
        state: 'WA',
        zipCode: '98177',
        imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=800&auto=format&fit=crop',
        category: 'Wellness',
        organizerName: 'Seattle Hiking Collective',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=SEA+Hike&size=200&background=00CEC9&color=fff',
        bookmarkedCount: 59,
        interestedCount: 148,
        source: EventSource.local,
        latitude: 47.7379, longitude: -122.3450,
      ),
      Event(
        id: 'evt_lc_009',
        title: 'Saturday Morning Swing Dance',
        description:
            'Beginner swing dance lesson from 9:30–10 AM, followed by open dancing until noon. '
            'No partner or experience needed. Wear soft-soled shoes. Coffee and pastries at the door.',
        dateTime: midnight.add(const Duration(days: 5, hours: 9)),
        location: 'Swing Hall',
        address: '740 Lindy Ln',
        city: 'Kansas City',
        state: 'MO',
        zipCode: '64108',
        cost: 8.00,
        imageUrl: 'https://images.unsplash.com/photo-1504609813442-a8924e83f76e?q=80&w=800&auto=format&fit=crop',
        category: 'Dance',
        organizerName: 'KC Swing Club',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=KC+Swing&size=200&background=FD79A8&color=fff',
        bookmarkedCount: 36,
        interestedCount: 91,
        source: EventSource.local,
        latitude: 39.0947, longitude: -94.5783,
      ),
      Event(
        id: 'evt_lc_010',
        title: 'Retro Video Game Expo',
        description:
            'Browse and buy vintage consoles, cartridges, and gaming memorabilia from 30+ vendors. '
            'Free-play arcade with 80s and 90s classics. Cosplay contest with prizes. Family friendly.',
        dateTime: midnight.add(const Duration(days: 8, hours: 10)),
        location: 'Convention Center Hall B',
        address: '400 Convention Way',
        city: 'Indianapolis',
        state: 'IN',
        zipCode: '46204',
        cost: 12.00,
        imageUrl: 'https://images.unsplash.com/photo-1606503153255-59d8b8b82176?q=80&w=800&auto=format&fit=crop',
        category: 'Fun & Games',
        organizerName: 'Retro Game Expo Indy',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=Retro+Indy&size=200&background=A29BFE&color=fff',
        bookmarkedCount: 107,
        interestedCount: 284,
        source: EventSource.local,
        latitude: 39.7744, longitude: -86.1586,
      ),
      Event(
        id: 'evt_lc_011',
        title: 'Free Legal Clinic — Know Your Rights',
        description:
            'Volunteer attorneys offer free 20-minute consultations on tenant rights, employment law, '
            'and immigration. No appointment needed. Walk-in first-come-first-served. Bilingual staff available.',
        dateTime: midnight.add(const Duration(days: 7, hours: 9)),
        location: 'Public Library Meeting Room',
        address: '630 W 5th St',
        city: 'Los Angeles',
        state: 'CA',
        zipCode: '90071',
        imageUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?q=80&w=800&auto=format&fit=crop',
        category: 'Community',
        organizerName: 'LA Legal Aid',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=LA+Legal&size=200&background=6C5CE7&color=fff',
        bookmarkedCount: 43,
        interestedCount: 112,
        source: EventSource.local,
        latitude: 34.0514, longitude: -118.2542,
      ),
      Event(
        id: 'evt_lc_012',
        title: 'Cooking Class — Thai Street Food',
        description:
            'Learn to cook four classic Thai street food dishes with an experienced home cook. '
            'Pad thai, som tum, mango sticky rice, and Thai iced tea. All ingredients provided. Eat what you make!',
        dateTime: midnight.add(const Duration(days: 10, hours: 14)),
        location: 'The Shared Kitchen',
        address: '200 Culinary Ave',
        city: 'Houston',
        state: 'TX',
        zipCode: '77006',
        cost: 45.00,
        imageUrl: 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?q=80&w=800&auto=format&fit=crop',
        category: 'Food',
        organizerName: 'Houston Home Cooks',
        organizerAvatarUrl: 'https://ui-avatars.com/api/?name=HTX+Cooks&size=200&background=FF7675&color=fff',
        bookmarkedCount: 84,
        interestedCount: 223,
        source: EventSource.local,
        latitude: 29.7452, longitude: -95.3698,
      ),
    ];
  }

  /// Returns a deterministically-generated set of events for the given city.
  /// Always produces results — never returns empty — regardless of which city
  /// is supplied, covering every location in America.
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return _generateEventsForLocation(city, state, zip, midnight);
  }

  Future<void> toggleBookmark(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> toggleInterested(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
