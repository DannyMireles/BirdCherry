import '../models/models.dart';
import '../services/ebird_service.dart';

/// Pure functions that combine the curated featured birds with the full eBird
/// taxonomy into one catalog. Kept separate from state so it's trivially
/// testable and has no Flutter dependency.
abstract final class SpeciesCatalog {
  /// Merge [curated] (hand-written, rich) with [ebird] (the world checklist).
  ///
  /// A curated bird and its eBird twin are matched by scientific name: the
  /// curated entry wins and absorbs the eBird species code (for nearby
  /// matching), and the duplicate eBird entry is dropped. Everything else from
  /// eBird is appended. Result is sorted by name.
  static List<Bird> merge(List<Bird> curated, List<Bird> ebird) {
    final ebirdBySci = <String, Bird>{
      for (final b in ebird) b.scientificName.toLowerCase(): b,
    };

    final enrichedCurated = [
      for (final b in curated)
        b.ebirdCode != null
            ? b
            : b.copyWith(
                ebirdCode: ebirdBySci[b.scientificName.toLowerCase()]?.ebirdCode,
              ),
    ];

    final curatedSci = {
      for (final b in curated) b.scientificName.toLowerCase(),
    };

    final merged = <Bird>[
      ...enrichedCurated,
      ...ebird.where((b) => !curatedSci.contains(b.scientificName.toLowerCase())),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return merged;
  }

  /// Turn a nearby observation into a [Bird], preferring a catalog match (so we
  /// keep curated richness) and otherwise synthesizing one from the eBird data.
  static Bird birdFor(
    NearbyObservation obs,
    Map<String, Bird> byEbirdCode,
    Map<String, Bird> bySci,
  ) {
    return byEbirdCode[obs.speciesCode] ??
        bySci[obs.sciName.toLowerCase()] ??
        Bird.fromEbird(
          speciesCode: obs.speciesCode,
          comName: obs.comName,
          sciName: obs.sciName,
          family: 'Birds',
        );
  }
}
