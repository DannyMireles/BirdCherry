import 'package:birdcherry/data/seed.dart';
import 'package:birdcherry/data/species_catalog.dart';
import 'package:birdcherry/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge dedupes curated vs eBird by scientific name and keeps curated',
      () {
    final curated = Seed.birds;
    // Two fake eBird entries: one duplicates a curated bird, one is new.
    final ebird = [
      Bird.fromEbird(
        speciesCode: 'norcar',
        comName: 'Northern Cardinal',
        sciName: 'Cardinalis cardinalis', // duplicate of a curated species
        family: 'Cardinals and Allies',
      ),
      Bird.fromEbird(
        speciesCode: 'houspa',
        comName: 'House Sparrow',
        sciName: 'Passer domesticus', // brand new
        family: 'Old World Sparrows',
      ),
    ];

    final merged = SpeciesCatalog.merge(curated, ebird);

    // Exactly one Northern Cardinal, and it's the curated (rich) one.
    final cardinals =
        merged.where((b) => b.scientificName == 'Cardinalis cardinalis');
    expect(cardinals.length, 1);
    expect(cardinals.first.curated, isTrue);
    expect(cardinals.first.hasProse, isTrue);
    // The curated cardinal absorbed the eBird species code for nearby matching.
    expect(cardinals.first.ebirdCode, 'norcar');

    // The new eBird-only species is present and marked non-curated.
    final sparrow =
        merged.firstWhere((b) => b.scientificName == 'Passer domesticus');
    expect(sparrow.curated, isFalse);
    expect(sparrow.hasProse, isFalse);

    // No duplicate scientific names overall.
    final scis = merged.map((b) => b.scientificName.toLowerCase()).toList();
    expect(scis.toSet().length, scis.length);
  });

  test('derived rarity is deterministic and spans tiers', () {
    Bird mk(String code) => Bird.fromEbird(
        speciesCode: code, comName: 'X', sciName: 'Genus $code', family: 'F');

    // Deterministic: same code -> same rarity.
    expect(mk('abcd').rarity, mk('abcd').rarity);

    // Across many codes we should see more than one tier represented.
    final tiers = {
      for (var i = 0; i < 200; i++) mk('sp$i').rarity,
    };
    expect(tiers.length, greaterThan(1));
  });
}
