import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';

/// Static demo dataset.
///
/// This is the only file that knows the demo content. The rest of the app
/// talks to repositories, so swapping this for Supabase tables later means
/// touching `repositories.dart` — nothing else.
abstract final class Seed {
  // ---------------------------------------------------------------------
  // Species database — 30 birds across six regions.
  // ---------------------------------------------------------------------
  static final List<Bird> birds = [
    // ----- North America -----
    const Bird(
      id: 'northern-cardinal',
      name: 'Northern Cardinal',
      scientificName: 'Cardinalis cardinalis',
      family: 'Cardinals',
      rarity: Rarity.common,
      regions: {Region.northAmerica},
      habitat: 'Backyards, woodland edges',
      size: '21–23 cm',
      description:
          'A crimson flash against winter snow. Males are brilliant red with a black mask; females wear warm taupe with red accents.',
      funFact: 'Cardinals don’t migrate — the same pair may visit your feeder for years.',
      call: 'cheer-cheer-cheer, birdie-birdie-birdie',
      wikiTitle: 'Northern cardinal',
      tint: Color(0xFFC9473F),
    ),
    const Bird(
      id: 'american-robin',
      name: 'American Robin',
      scientificName: 'Turdus migratorius',
      family: 'Thrushes',
      rarity: Rarity.common,
      regions: {Region.northAmerica},
      habitat: 'Lawns, parks, forests',
      size: '23–28 cm',
      description:
          'The classic herald of spring, hopping across lawns with its head cocked, listening for earthworms underground.',
      funFact: 'A robin can eat up to 4 metres of earthworms in a single day.',
      call: 'cheerily, cheer-up, cheer-up, cheerily',
      wikiTitle: 'American robin',
      tint: Color(0xFFB35A37),
    ),
    const Bird(
      id: 'blue-jay',
      name: 'Blue Jay',
      scientificName: 'Cyanocitta cristata',
      family: 'Crows & Jays',
      rarity: Rarity.common,
      regions: {Region.northAmerica},
      habitat: 'Oak woodland, suburbs',
      size: '25–30 cm',
      description:
          'Bold, brainy and loud. Blue Jays plant thousands of acorns a year, quietly reforesting the continent.',
      funFact: 'Blue Jays can mimic the cry of hawks to scare rivals away from feeders.',
      call: 'jay! jay! plus a squeaky-gate whine',
      wikiTitle: 'Blue jay',
      tint: Color(0xFF4A7BA6),
    ),
    const Bird(
      id: 'common-yellowthroat',
      name: 'Common Yellowthroat',
      scientificName: 'Geothlypis trichas',
      family: 'Warblers',
      rarity: Rarity.uncommon,
      regions: {Region.northAmerica},
      habitat: 'Marshes, brushy fields',
      size: '11–13 cm',
      description:
          'A tiny masked bandit of the reeds. You’ll hear its rolling song long before the black-masked male pops into view.',
      funFact: 'One of the first New World birds catalogued by Linnaeus, in 1766.',
      call: 'witchety-witchety-witchety',
      wikiTitle: 'Common yellowthroat',
      tint: Color(0xFFD7A52A),
    ),
    const Bird(
      id: 'ruby-throated-hummingbird',
      name: 'Ruby-throated Hummingbird',
      scientificName: 'Archilochus colubris',
      family: 'Hummingbirds',
      rarity: Rarity.uncommon,
      regions: {Region.northAmerica},
      habitat: 'Gardens, forest edges',
      size: '7–9 cm',
      description:
          'A glittering green sprite that beats its wings 53 times a second and crosses the Gulf of Mexico nonstop.',
      funFact: 'Its heart beats over 1,200 times per minute in flight.',
      call: 'soft tchew; wings hum like a tiny motor',
      wikiTitle: 'Ruby-throated hummingbird',
      tint: Color(0xFF2F8F6B),
    ),
    const Bird(
      id: 'great-horned-owl',
      name: 'Great Horned Owl',
      scientificName: 'Bubo virginianus',
      family: 'Owls',
      rarity: Rarity.uncommon,
      regions: {Region.northAmerica, Region.southAmerica},
      habitat: 'Forests, deserts, cities',
      size: '46–63 cm',
      description:
          'The tiger of the night sky. Ear tufts, yellow eyes and a grip strong enough to take prey three times its weight.',
      funFact: 'Its hearing is so precise it can strike prey under 30 cm of snow.',
      call: 'hoo-h’HOO, hoo-hoo',
      wikiTitle: 'Great horned owl',
      tint: Color(0xFF6E5A43),
    ),
    const Bird(
      id: 'bald-eagle',
      name: 'Bald Eagle',
      scientificName: 'Haliaeetus leucocephalus',
      family: 'Hawks & Eagles',
      rarity: Rarity.rare,
      regions: {Region.northAmerica},
      habitat: 'Lakes, rivers, coasts',
      size: '70–102 cm',
      description:
          'White head, chocolate body, two-metre wingspan. Once nearly lost, now soaring over most of North America again.',
      funFact: 'Bald Eagle nests can weigh more than a tonne — the largest of any bird.',
      call: 'surprisingly thin, stuttering whistle',
      wikiTitle: 'Bald eagle',
      tint: Color(0xFF5C4A36),
    ),
    const Bird(
      id: 'peregrine-falcon',
      name: 'Peregrine Falcon',
      scientificName: 'Falco peregrinus',
      family: 'Falcons',
      rarity: Rarity.rare,
      regions: {
        Region.northAmerica,
        Region.southAmerica,
        Region.europe,
        Region.africa,
        Region.asia,
        Region.oceania,
      },
      habitat: 'Cliffs, skyscrapers',
      size: '34–58 cm',
      description:
          'The fastest animal on Earth, stooping on prey at over 300 km/h. Found on every continent except Antarctica.',
      funFact: 'Peregrines nest on city skyscrapers, treating them as artificial cliffs.',
      call: 'harsh kak-kak-kak near the nest',
      wikiTitle: 'Peregrine falcon',
      tint: Color(0xFF4E5C66),
    ),
    const Bird(
      id: 'california-condor',
      name: 'California Condor',
      scientificName: 'Gymnogyps californianus',
      family: 'New World Vultures',
      rarity: Rarity.legendary,
      regions: {Region.northAmerica},
      habitat: 'Canyons, coastal cliffs',
      size: '109–140 cm',
      description:
          'North America’s largest land bird, back from the very brink — every living condor descends from just 27 survivors.',
      funFact: 'A condor can soar for an hour without a single wingbeat.',
      call: 'mostly silent; hisses and grunts up close',
      wikiTitle: 'California condor',
      tint: Color(0xFF3B3430),
    ),

    // ----- Europe -----
    const Bird(
      id: 'european-robin',
      name: 'European Robin',
      scientificName: 'Erithacus rubecula',
      family: 'Chats & Flycatchers',
      rarity: Rarity.common,
      regions: {Region.europe},
      habitat: 'Gardens, hedgerows',
      size: '12–14 cm',
      description:
          'The round, orange-breasted companion of every European gardener — fiercely territorial despite the cute look.',
      funFact: 'European Robins sing through the night in cities lit by streetlights.',
      call: 'thin, silvery warble — twiddle-oo, twiddle-eedee',
      wikiTitle: 'European robin',
      tint: Color(0xFFD06A3B),
    ),
    const Bird(
      id: 'eurasian-blue-tit',
      name: 'Eurasian Blue Tit',
      scientificName: 'Cyanistes caeruleus',
      family: 'Tits',
      rarity: Rarity.common,
      regions: {Region.europe},
      habitat: 'Woodland, gardens',
      size: '10–12 cm',
      description:
          'A tiny acrobat in lemon and sky-blue, happiest hanging upside-down from the thinnest twigs.',
      funFact: 'Blue Tits famously learned to open milk-bottle tops across 1920s Britain.',
      call: 'tsee-tsee-tsee-chu-chu',
      wikiTitle: 'Eurasian blue tit',
      tint: Color(0xFF5B8FBF),
    ),
    const Bird(
      id: 'common-kingfisher',
      name: 'Common Kingfisher',
      scientificName: 'Alcedo atthis',
      family: 'Kingfishers',
      rarity: Rarity.uncommon,
      regions: {Region.europe, Region.asia, Region.africa},
      habitat: 'Slow rivers, canals',
      size: '16–17 cm',
      description:
          'An electric-blue dart along the riverbank. Blink and you’ll miss it; listen for the sharp whistle instead.',
      funFact: 'Its beak inspired the nose of Japan’s Shinkansen bullet train.',
      call: 'sharp zii-ti whistle in flight',
      wikiTitle: 'Common kingfisher',
      tint: Color(0xFF1D7F9E),
    ),
    const Bird(
      id: 'barn-owl',
      name: 'Barn Owl',
      scientificName: 'Tyto alba',
      family: 'Barn Owls',
      rarity: Rarity.uncommon,
      regions: {
        Region.europe,
        Region.northAmerica,
        Region.southAmerica,
        Region.africa,
        Region.asia,
        Region.oceania,
      },
      habitat: 'Farmland, old buildings',
      size: '33–39 cm',
      description:
          'A ghost-faced hunter drifting over midnight fields on silent wings. One of the most widespread birds on Earth.',
      funFact: 'Barn Owl feathers are so soft that flight is almost perfectly silent.',
      call: 'long, eerie shriiiiek (not a hoot)',
      wikiTitle: 'Barn owl',
      tint: Color(0xFFC8A468),
    ),
    const Bird(
      id: 'white-stork',
      name: 'White Stork',
      scientificName: 'Ciconia ciconia',
      family: 'Storks',
      rarity: Rarity.uncommon,
      regions: {Region.europe, Region.africa},
      habitat: 'Wet meadows, rooftops',
      size: '100–115 cm',
      description:
          'The baby-delivering legend itself, nesting in huge stick platforms on chimneys and pylons across Europe.',
      funFact: 'Storks are nearly voiceless — they greet mates by clattering their bills.',
      call: 'bill-clattering, like applause',
      wikiTitle: 'White stork',
      tint: Color(0xFF9A8F85),
    ),
    const Bird(
      id: 'atlantic-puffin',
      name: 'Atlantic Puffin',
      scientificName: 'Fratercula arctica',
      family: 'Auks',
      rarity: Rarity.rare,
      regions: {Region.europe, Region.northAmerica},
      habitat: 'Sea cliffs, open ocean',
      size: '26–29 cm',
      description:
          'The clown of the sea, whirring over the waves with a rainbow bill stuffed full of sand eels.',
      funFact: 'A puffin can hold a dozen fish crosswise in its bill at once.',
      call: 'low growling arr-arr-arr from the burrow',
      wikiTitle: 'Atlantic puffin',
      tint: Color(0xFFE08A3C),
    ),
    const Bird(
      id: 'golden-eagle',
      name: 'Golden Eagle',
      scientificName: 'Aquila chrysaetos',
      family: 'Hawks & Eagles',
      rarity: Rarity.rare,
      regions: {Region.europe, Region.asia, Region.northAmerica, Region.africa},
      habitat: 'Mountains, moorland',
      size: '66–102 cm',
      description:
          'The emperor of high country, riding mountain thermals on golden-naped wings that span over two metres.',
      funFact: 'Golden Eagles have been clocked diving at over 240 km/h.',
      call: 'mostly silent; occasional thin yelps',
      wikiTitle: 'Golden eagle',
      tint: Color(0xFF8A6B3A),
    ),

    // ----- South America -----
    const Bird(
      id: 'scarlet-macaw',
      name: 'Scarlet Macaw',
      scientificName: 'Ara macao',
      family: 'Parrots',
      rarity: Rarity.rare,
      regions: {Region.southAmerica},
      habitat: 'Lowland rainforest',
      size: '81–96 cm',
      description:
          'A flying carnival of red, yellow and blue, screeching across the rainforest canopy in lifelong pairs.',
      funFact: 'Macaws eat river clay, which may help neutralise toxins in wild seeds.',
      call: 'raucous rrraaark echoing over the canopy',
      wikiTitle: 'Scarlet macaw',
      tint: Color(0xFFD13B30),
    ),
    const Bird(
      id: 'toco-toucan',
      name: 'Toco Toucan',
      scientificName: 'Ramphastos toco',
      family: 'Toucans',
      rarity: Rarity.uncommon,
      regions: {Region.southAmerica},
      habitat: 'Forest edge, cerrado',
      size: '55–65 cm',
      description:
          'The biggest toucan of all, hopping through the treetops behind an impossible sunset-orange bill.',
      funFact: 'The huge bill doubles as a radiator, dumping body heat on hot days.',
      call: 'deep croaking grrrunt, like a frog in a tree',
      wikiTitle: 'Toco toucan',
      tint: Color(0xFFE0762E),
    ),
    const Bird(
      id: 'andean-condor',
      name: 'Andean Condor',
      scientificName: 'Vultur gryphus',
      family: 'New World Vultures',
      rarity: Rarity.legendary,
      regions: {Region.southAmerica},
      habitat: 'High Andes, coastal deserts',
      size: '100–130 cm',
      description:
          'The largest flying bird in the world by combined size, circling Andean peaks on a 3-metre wingspan.',
      funFact: 'An Andean Condor once flew 170 km without flapping a single time.',
      call: 'silent — no voice box at all',
      wikiTitle: 'Andean condor',
      tint: Color(0xFF2E2A28),
    ),

    // ----- Africa -----
    const Bird(
      id: 'lilac-breasted-roller',
      name: 'Lilac-breasted Roller',
      scientificName: 'Coracias caudatus',
      family: 'Rollers',
      rarity: Rarity.uncommon,
      regions: {Region.africa},
      habitat: 'Savanna, open woodland',
      size: '36–38 cm',
      description:
          'Eight colours on one bird. Perches like a jewel on acacia snags, then tumbles through the air to impress mates.',
      funFact: 'Its courtship flight is a full aerial roll — hence the name.',
      call: 'harsh rak-rak-rak during display dives',
      wikiTitle: 'Lilac-breasted roller',
      tint: Color(0xFF9B6BB3),
    ),
    const Bird(
      id: 'african-fish-eagle',
      name: 'African Fish Eagle',
      scientificName: 'Icthyophaga vocifer',
      family: 'Hawks & Eagles',
      rarity: Rarity.uncommon,
      regions: {Region.africa},
      habitat: 'Lakes, rivers, wetlands',
      size: '63–75 cm',
      description:
          'The voice of wild Africa. Its ringing cry over Rift Valley lakes is one of nature’s great sound signatures.',
      funFact: 'Pairs duet together, throwing their heads back as they call.',
      call: 'ringing weee-ah, hyo-hyo-hyo',
      wikiTitle: 'African fish eagle',
      tint: Color(0xFF7A5230),
    ),
    const Bird(
      id: 'common-ostrich',
      name: 'Common Ostrich',
      scientificName: 'Struthio camelus',
      family: 'Ostriches',
      rarity: Rarity.uncommon,
      regions: {Region.africa},
      habitat: 'Savanna, semi-desert',
      size: '175–275 cm',
      description:
          'The largest living bird: too big to fly, fast enough not to care, sprinting at 70 km/h on two toes.',
      funFact: 'An ostrich egg weighs as much as two dozen chicken eggs.',
      call: 'deep booming that carries for kilometres',
      wikiTitle: 'Common ostrich',
      tint: Color(0xFF8C8378),
    ),
    const Bird(
      id: 'secretarybird',
      name: 'Secretarybird',
      scientificName: 'Sagittarius serpentarius',
      family: 'Secretarybird',
      rarity: Rarity.rare,
      regions: {Region.africa},
      habitat: 'Open grassland',
      size: '112–150 cm',
      description:
          'An eagle on supermodel legs that strides across the savanna stomping snakes with lightning-fast kicks.',
      funFact: 'Its kick delivers five times its body weight in a hundredth of a second.',
      call: 'deep croaking groan during display',
      wikiTitle: 'Secretarybird',
      tint: Color(0xFF7E8287),
    ),
    const Bird(
      id: 'shoebill',
      name: 'Shoebill',
      scientificName: 'Balaeniceps rex',
      family: 'Shoebill',
      rarity: Rarity.legendary,
      regions: {Region.africa},
      habitat: 'Papyrus swamps',
      size: '110–140 cm',
      description:
          'A prehistoric statue of a bird that stands motionless for hours in Ugandan swamps before lunging at lungfish.',
      funFact: 'Shoebills greet each other by machine-gun bill-clattering.',
      call: 'bill-clattering like a machine gun',
      wikiTitle: 'Shoebill',
      tint: Color(0xFF5A6470),
    ),

    // ----- Asia -----
    const Bird(
      id: 'indian-peafowl',
      name: 'Indian Peafowl',
      scientificName: 'Pavo cristatus',
      family: 'Pheasants',
      rarity: Rarity.uncommon,
      regions: {Region.asia},
      habitat: 'Forest edge, farmland, temples',
      size: '100–235 cm',
      description:
          'The peacock. A male’s train carries up to 200 shimmering eyespots, shaken in one of nature’s great performances.',
      funFact: 'Peafowl trains regrow from scratch every single year.',
      call: 'loud may-AWE, may-AWE at dawn and dusk',
      wikiTitle: 'Indian peafowl',
      tint: Color(0xFF1F6E8C),
    ),
    const Bird(
      id: 'mandarin-duck',
      name: 'Mandarin Duck',
      scientificName: 'Aix galericulata',
      family: 'Ducks',
      rarity: Rarity.uncommon,
      regions: {Region.asia, Region.europe},
      habitat: 'Wooded lakes, parks',
      size: '41–49 cm',
      description:
          'Arguably the world’s most ornate duck — orange sails, purple chest, painted face — gliding under overhanging willows.',
      funFact: 'In Chinese tradition, mandarin pairs symbolise lifelong devotion.',
      call: 'soft rising whistle from drakes',
      wikiTitle: 'Mandarin duck',
      tint: Color(0xFFB3563A),
    ),
    const Bird(
      id: 'red-crowned-crane',
      name: 'Red-crowned Crane',
      scientificName: 'Grus japonensis',
      family: 'Cranes',
      rarity: Rarity.rare,
      regions: {Region.asia},
      habitat: 'Marshes, snowfields',
      size: '150–158 cm',
      description:
          'Snow-white elegance with a crimson crown, famous for duet dances in the snows of Hokkaido.',
      funFact: 'In Japan it symbolises a thousand years of luck and fidelity.',
      call: 'bugling duets that carry 3 km',
      wikiTitle: 'Red-crowned crane',
      tint: Color(0xFFB6452F),
    ),

    // ----- Oceania -----
    const Bird(
      id: 'rainbow-lorikeet',
      name: 'Rainbow Lorikeet',
      scientificName: 'Trichoglossus moluccanus',
      family: 'Parrots',
      rarity: Rarity.common,
      regions: {Region.oceania},
      habitat: 'Coastal bush, city gardens',
      size: '25–30 cm',
      description:
          'A shrieking rainbow that mobs flowering gums at sunset. Sydney’s most colourful commuter.',
      funFact: 'Lorikeets have brush-tipped tongues for licking nectar.',
      call: 'constant high-pitched screeching chatter',
      wikiTitle: 'Rainbow lorikeet',
      tint: Color(0xFF2E8C5A),
    ),
    const Bird(
      id: 'laughing-kookaburra',
      name: 'Laughing Kookaburra',
      scientificName: 'Dacelo novaeguineae',
      family: 'Kingfishers',
      rarity: Rarity.common,
      regions: {Region.oceania},
      habitat: 'Eucalypt woodland, suburbs',
      size: '40–47 cm',
      description:
          'The bushman’s alarm clock. Family groups laugh together at dawn to mark their territory.',
      funFact: 'Kookaburras are giant kingfishers that rarely eat fish.',
      call: 'rolling kook-kook-kook-ka-ka-KA laughter',
      wikiTitle: 'Laughing kookaburra',
      tint: Color(0xFF8A7A5C),
    ),
    const Bird(
      id: 'southern-cassowary',
      name: 'Southern Cassowary',
      scientificName: 'Casuarius casuarius',
      family: 'Cassowaries',
      rarity: Rarity.legendary,
      regions: {Region.oceania},
      habitat: 'Tropical rainforest',
      size: '127–170 cm',
      description:
          'A living dinosaur in electric blue, patrolling Queensland’s rainforest with dagger claws and a bony casque.',
      funFact: 'Cassowaries are vital gardeners, spreading seeds of over 200 rainforest plants.',
      call: 'subsonic booming you feel in your chest',
      wikiTitle: 'Southern cassowary',
      tint: Color(0xFF24506B),
    ),
    const Bird(
      id: 'kea',
      name: 'Kea',
      scientificName: 'Nestor notabilis',
      family: 'Parrots',
      rarity: Rarity.rare,
      regions: {Region.oceania},
      habitat: 'Alpine New Zealand',
      size: '46–50 cm',
      description:
          'The world’s only alpine parrot — olive-green, scarlet underwings, and clever enough to dismantle your car.',
      funFact: 'Keas solve logic puzzles as well as great apes in lab tests.',
      call: 'keee-aa! ringing across the valleys',
      wikiTitle: 'Kea',
      tint: Color(0xFF6B7A3D),
    ),
  ];

  // ---------------------------------------------------------------------
  // People — you plus four friends.
  // ---------------------------------------------------------------------
  static const AppUser me = AppUser(
    id: 'me',
    name: 'Dani Mireles',
    handle: '@dani',
    color: Color(0xFFC9473F),
    home: 'Austin, TX',
    homePoint: LatLng(30.2862, -97.7394),
    isMe: true,
  );

  // The social graph ships EMPTY so real users start with a clean slate:
  // friends, incoming requests, and discovery all come from the backend
  // (Supabase) in production. Sample fixtures for tests live in
  // `test/support/sample_data.dart`.
  static const List<AppUser> friends = [];
  static const List<AppUser> friendRequests = [];
  static const List<AppUser> discoverable = [];

  // No pre-seeded sightings — your life list starts empty.
  static List<Sighting> sightings() => const [];

  // ---------------------------------------------------------------------
  // Named hotspots for the log flow's location picker.
  // ---------------------------------------------------------------------
  static final List<(String, LatLng)> hotspots = [
    ('Pease Park, Austin', const LatLng(30.2862, -97.7394)),
    ('Zilker Park, Austin', const LatLng(30.2500, -97.7500)),
    ('Lady Bird Lake, Austin', const LatLng(30.2565, -97.7445)),
    ('McKinney Falls SP', const LatLng(30.1830, -97.7251)),
    ('Lake Travis', const LatLng(30.4548, -97.9222)),
    ('Central Park, NYC', const LatLng(40.7812, -73.9665)),
    ('Hyde Park, London', const LatLng(51.5073, -0.1657)),
  ];
}
