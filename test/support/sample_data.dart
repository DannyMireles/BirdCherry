import 'package:birdcherry/models/models.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Sample social graph + sightings used ONLY by tests (and not shipped).
///
/// Production `Seed` ships an empty social graph so real users start with a
/// clean slate; tests inject this fixture into the Static* repositories to keep
/// exercising friends, the activity feed, and gamification math.

const List<AppUser> sampleFriends = [
  AppUser(
    id: 'maya',
    name: 'Maya Lindqvist',
    handle: '@maya.birds',
    color: Color(0xFF2F5D45),
    home: 'Stockholm',
    homePoint: LatLng(59.3293, 18.0686),
  ),
  AppUser(
    id: 'kofi',
    name: 'Kofi Mensah',
    handle: '@kofi_scope',
    color: Color(0xFF1F6E8C),
    home: 'Accra',
    homePoint: LatLng(5.6037, -0.1870),
  ),
  AppUser(
    id: 'sofia',
    name: 'Sofía Reyes',
    handle: '@sofia.field',
    color: Color(0xFF7B5EA7),
    home: 'Mexico City',
    homePoint: LatLng(19.4326, -99.1332),
  ),
  AppUser(
    id: 'jin',
    name: 'Jin Park',
    handle: '@jinwatches',
    color: Color(0xFFC7842C),
    home: 'Seoul',
    homePoint: LatLng(37.5665, 126.9780),
  ),
];

const List<AppUser> sampleRequests = [
  AppUser(
    id: 'liam',
    name: 'Liam O’Connor',
    handle: '@liam.birds',
    color: Color(0xFF3B7A57),
    home: 'Dublin',
    homePoint: LatLng(53.3498, -6.2603),
  ),
  AppUser(
    id: 'priya',
    name: 'Priya Nair',
    handle: '@priyawings',
    color: Color(0xFFB5524E),
    home: 'Bengaluru',
    homePoint: LatLng(12.9716, 77.5946),
  ),
];

const List<AppUser> sampleSuggestions = [
  AppUser(
    id: 'noah',
    name: 'Noah Berg',
    handle: '@noah.scope',
    color: Color(0xFF4A6FA5),
    home: 'Cape Town',
    homePoint: LatLng(-33.9249, 18.4241),
  ),
  AppUser(
    id: 'emi',
    name: 'Emi Tanaka',
    handle: '@emi.birds',
    color: Color(0xFFA8567E),
    home: 'Kyoto',
    homePoint: LatLng(35.0116, 135.7681),
  ),
  AppUser(
    id: 'tomas',
    name: 'Tomás Silva',
    handle: '@tomasfield',
    color: Color(0xFF2E8C7E),
    home: 'Lisbon',
    homePoint: LatLng(38.7223, -9.1393),
  ),
  AppUser(
    id: 'amara',
    name: 'Amara Okafor',
    handle: '@amara.wild',
    color: Color(0xFFC77D2C),
    home: 'Lagos',
    homePoint: LatLng(6.5244, 3.3792),
  ),
];

/// Sightings seeded relative to now, for me + the four sample friends.
List<Sighting> sampleSightings() {
  final now = DateTime.now();
  DateTime ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));

  var n = 0;
  Sighting s(String birdId, String userId, DateTime at, double lat, double lng,
          String place, [String? note]) =>
      Sighting(
        id: 'sample-${n++}',
        birdId: birdId,
        userId: userId,
        seenAt: at,
        point: LatLng(lat, lng),
        place: place,
        note: note,
      );

  return [
    // --- Mine ---
    s('northern-cardinal', 'me', ago(hours: 3), 30.2862, -97.7394,
        'Pease Park, Austin', 'Singing from the top of a pecan tree.'),
    s('blue-jay', 'me', ago(days: 1, hours: 2), 30.2747, -97.7404,
        'Shoal Creek Trail, Austin'),
    s('great-horned-owl', 'me', ago(days: 2, hours: 14), 30.2950, -97.7713,
        'Mount Bonnell, Austin', 'Pair duetting at dusk.'),
    s('bald-eagle', 'me', ago(days: 12, hours: 4), 30.4548, -97.9222,
        'Lake Travis', 'Adult cruising the north shore!'),

    // --- Maya ---
    s('eurasian-blue-tit', 'maya', ago(hours: 1, minutes: 20), 59.3326, 18.0649,
        'Humlegården, Stockholm'),
    s('atlantic-puffin', 'maya', ago(days: 9, hours: 10), 63.4030, -19.0820,
        'Dyrhólaey cliffs, Iceland', 'Hundreds.'),

    // --- Kofi ---
    s('african-fish-eagle', 'kofi', ago(hours: 7), 6.4090, 0.2980,
        'Lake Volta, Ghana'),
    s('shoebill', 'kofi', ago(days: 16, hours: 7), 0.4170, 32.4900,
        'Mabamba Swamp, Uganda', 'LIFER.'),

    // --- Sofía ---
    s('toco-toucan', 'sofia', ago(days: 7, hours: 9), -12.8650, -69.3620,
        'Tambopata, Peru'),

    // --- Jin ---
    s('red-crowned-crane', 'jin', ago(days: 13, hours: 8), 43.0800, 144.3000,
        'Kushiro Marsh, Hokkaido', 'Dancing pair in the snow.'),
  ];
}
