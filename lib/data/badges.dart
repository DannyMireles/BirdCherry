import 'package:flutter/material.dart';

import '../models/models.dart';

/// Badge catalogue. Earned state is a pure function of the user's sightings,
/// so badges work identically against static data or a future backend.
abstract final class Badges {
  static final List<BadgeDef> all = [
    BadgeDef(
      id: 'first-flight',
      name: 'First Flight',
      blurb: 'Log your very first bird.',
      icon: Icons.flight_takeoff_rounded,
      isEarned: (mine, _) => mine.isNotEmpty,
    ),
    BadgeDef(
      id: 'early-bird',
      name: 'Early Bird',
      blurb: 'Log a sighting before 7 in the morning.',
      icon: Icons.wb_twilight,
      isEarned: (mine, _) => mine.any((s) => s.seenAt.hour < 7),
    ),
    BadgeDef(
      id: 'night-owl',
      name: 'Night Owl',
      blurb: 'Log a sighting after 9 at night.',
      icon: Icons.nightlight_round,
      isEarned: (mine, _) => mine.any((s) => s.seenAt.hour >= 21),
    ),
    BadgeDef(
      id: 'collector-5',
      name: 'Curious Five',
      blurb: 'See 5 different species.',
      icon: Icons.auto_awesome,
      isEarned: (mine, _) => mine.map((s) => s.birdId).toSet().length >= 5,
    ),
    BadgeDef(
      id: 'collector-10',
      name: 'Field Collector',
      blurb: 'See 10 different species.',
      icon: Icons.grid_view_rounded,
      isEarned: (mine, _) => mine.map((s) => s.birdId).toSet().length >= 10,
    ),
    BadgeDef(
      id: 'streak-3',
      name: 'On a Roll',
      blurb: 'Log birds 3 days in a row.',
      icon: Icons.local_fire_department,
      isEarned: (mine, _) => _streak(mine) >= 3,
    ),
    BadgeDef(
      id: 'streak-7',
      name: 'Week of Wings',
      blurb: 'Log birds 7 days in a row.',
      icon: Icons.calendar_month,
      isEarned: (mine, _) => _streak(mine) >= 7,
    ),
    BadgeDef(
      id: 'rare-find',
      name: 'Rare Find',
      blurb: 'Spot a rare or legendary bird.',
      icon: Icons.diamond_outlined,
      isEarned: (mine, bird) => mine.any((s) =>
          bird(s.birdId).rarity == Rarity.rare ||
          bird(s.birdId).rarity == Rarity.legendary),
    ),
    BadgeDef(
      id: 'living-legend',
      name: 'Living Legend',
      blurb: 'Spot a legendary bird.',
      icon: Icons.workspace_premium,
      isEarned: (mine, bird) =>
          mine.any((s) => bird(s.birdId).rarity == Rarity.legendary),
    ),
    BadgeDef(
      id: 'globetrotter',
      name: 'Globetrotter',
      blurb: 'Log sightings in 2 different world regions.',
      icon: Icons.public,
      isEarned: (mine, _) =>
          mine.map((s) => Region.fromLatLng(s.point)).toSet().length >= 2,
    ),
    BadgeDef(
      id: 'raptor-fan',
      name: 'Raptor Fan',
      blurb: 'See 3 birds of prey.',
      icon: Icons.bolt,
      isEarned: (mine, bird) {
        const raptorFamilies = {
          'Hawks & Eagles', 'Falcons', 'Owls', 'Barn Owls', 'New World Vultures',
        };
        return mine
                .map((s) => bird(s.birdId))
                .where((b) => raptorFamilies.contains(b.family))
                .map((b) => b.id)
                .toSet()
                .length >=
            3;
      },
    ),
    BadgeDef(
      id: 'big-day',
      name: 'Big Day',
      blurb: 'Log 4 species in a single day.',
      icon: Icons.celebration,
      isEarned: (mine, _) {
        final byDay = <String, Set<String>>{};
        for (final s in mine) {
          final key = '${s.seenAt.year}-${s.seenAt.month}-${s.seenAt.day}';
          (byDay[key] ??= {}).add(s.birdId);
        }
        return byDay.values.any((species) => species.length >= 4);
      },
    ),
  ];

  /// Consecutive-day streak ending today or yesterday.
  static int _streak(List<Sighting> mine) {
    if (mine.isEmpty) return 0;
    final days = mine
        .map((s) => DateTime(s.seenAt.year, s.seenAt.month, s.seenAt.day))
        .toSet();
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int streakOf(List<Sighting> mine) => _streak(mine);
}
