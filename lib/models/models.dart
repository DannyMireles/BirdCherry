import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// How hard a bird is to find. Drives points, colors and bragging rights.
enum Rarity {
  common('Common', 10),
  uncommon('Uncommon', 25),
  rare('Rare', 50),
  legendary('Legendary', 100);

  const Rarity(this.label, this.points);
  final String label;
  final int points;
}

/// Rough world regions used for "what can I expect to see here?".
enum Region {
  northAmerica('North America'),
  southAmerica('South America'),
  europe('Europe'),
  africa('Africa'),
  asia('Asia'),
  oceania('Oceania');

  const Region(this.label);
  final String label;

  /// Coarse continent lookup from a map tap. Intentionally approximate —
  /// good enough to answer "what birds live around here?" anywhere on Earth.
  static Region fromLatLng(LatLng p) {
    final lat = p.latitude, lng = p.longitude;
    if (lng >= -170 && lng < -30) {
      return lat >= 13 ? Region.northAmerica : Region.southAmerica;
    }
    if (lng >= -30 && lng < 60) {
      if (lat >= 36) return Region.europe;
      return Region.africa;
    }
    // lng >= 60 (or wrapped past the antimeridian)
    if (lat < -8 || (lng >= 110 && lat < 10)) return Region.oceania;
    return Region.asia;
  }
}

/// A species in the BirdCherry database.
///
/// Two provenances share one type so the whole UI stays simple:
///   • Curated birds (hand-written, [curated] == true) carry rich content:
///     description, fun fact, call mnemonic, range, authored rarity.
///   • eBird birds ([Bird.fromEbird]) carry just the essentials from the eBird
///     taxonomy; rarity/tint are derived deterministically and the prose
///     fields are empty. Photos still resolve live (iNaturalist by sci-name)
///     and audio via xeno-canto, so they look and sound complete.
class Bird {
  const Bird({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.family,
    required this.rarity,
    required this.regions,
    required this.habitat,
    required this.size,
    required this.description,
    required this.funFact,
    required this.call,
    required this.wikiTitle,
    required this.tint,
    this.ebirdCode,
    this.curated = true,
  });

  /// Build a [Bird] from an eBird taxonomy entry. Rarity and tint are derived
  /// deterministically from the species code so points stay varied and the
  /// brand color is stable. (A real release would source rarity from eBird
  /// abundance or IUCN status — tracked as a TODO.)
  factory Bird.fromEbird({
    required String speciesCode,
    required String comName,
    required String sciName,
    required String family,
  }) {
    return Bird(
      id: 'ebird-$speciesCode',
      name: comName,
      scientificName: sciName,
      family: family.isEmpty ? 'Birds' : family,
      rarity: _derivedRarity(speciesCode),
      regions: const {},
      habitat: '',
      size: '',
      description: '',
      funFact: '',
      call: '',
      wikiTitle: comName,
      tint: _derivedTint(speciesCode),
      ebirdCode: speciesCode,
      curated: false,
    );
  }

  final String id;
  final String name;
  final String scientificName;
  final String family;
  final Rarity rarity;
  final Set<Region> regions;
  final String habitat;
  final String size;
  final String description;
  final String funFact;

  /// Mnemonic for the song/call, the way field guides write it. May be empty
  /// for eBird species (their audio comes from xeno-canto instead).
  final String call;

  /// English Wikipedia article title — used to fetch a live photo
  /// from the Wikipedia REST API.
  final String wikiTitle;

  /// Brand-friendly fallback color when no photo is available.
  final Color tint;

  /// eBird species code (e.g. `norcar`), when this bird is known to eBird.
  /// Present on both curated birds (for nearby matching) and eBird birds.
  final String? ebirdCode;

  /// True for the hand-written featured set; false for eBird-sourced species.
  final bool curated;

  int get points => rarity.points;

  bool get hasProse => description.isNotEmpty;

  Bird copyWith({String? ebirdCode}) => Bird(
        id: id,
        name: name,
        scientificName: scientificName,
        family: family,
        rarity: rarity,
        regions: regions,
        habitat: habitat,
        size: size,
        description: description,
        funFact: funFact,
        call: call,
        wikiTitle: wikiTitle,
        tint: tint,
        ebirdCode: ebirdCode ?? this.ebirdCode,
        curated: curated,
      );

  // Weighted so most birds are common and legendaries stay special.
  static Rarity _derivedRarity(String code) {
    final h = code.codeUnits.fold(0, (a, c) => (a * 31 + c) & 0x7fffffff) % 100;
    if (h < 55) return Rarity.common;
    if (h < 84) return Rarity.uncommon;
    if (h < 96) return Rarity.rare;
    return Rarity.legendary;
  }

  static const _palette = [
    Color(0xFFC9473F), Color(0xFF2F5D45), Color(0xFF4A7BA6), Color(0xFFC7842C),
    Color(0xFF7B5EA7), Color(0xFF1F6E8C), Color(0xFFB35A37), Color(0xFF6B8F71),
  ];

  static Color _derivedTint(String code) {
    final h = code.codeUnits.fold(0, (a, c) => (a * 17 + c) & 0x7fffffff);
    return _palette[h % _palette.length];
  }
}

/// A person on BirdCherry (you or a friend).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.handle,
    required this.color,
    required this.home,
    required this.homePoint,
    this.isMe = false,
  });

  final String id;
  final String name;
  final String handle;
  final Color color;
  final String home;

  /// Approximate home coordinates, used to seed "birds near you".
  final LatLng homePoint;
  final bool isMe;

  String get initials {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1);
    return parts.first.substring(0, 1) + parts.last.substring(0, 1);
  }
}

/// One observation of one bird by one user, somewhere on Earth.
class Sighting {
  const Sighting({
    required this.id,
    required this.birdId,
    required this.userId,
    required this.seenAt,
    required this.point,
    required this.place,
    this.note,
  });

  final String id;
  final String birdId;
  final String userId;
  final DateTime seenAt;
  final LatLng point;
  final String place;
  final String? note;
}

/// An achievement definition. Earned state is computed from sightings,
/// so badges stay correct no matter where the data comes from.
class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.icon,
    required this.isEarned,
  });

  final String id;
  final String name;
  final String blurb;
  final IconData icon;

  /// Given the user's sightings and a bird lookup, is this badge earned?
  final bool Function(List<Sighting> mine, Bird Function(String id) bird) isEarned;
}
