import 'package:birdcherry/data/repositories.dart';
import 'package:birdcherry/main.dart';
import 'package:birdcherry/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sample_data.dart';

Future<AppState> _loadedState() async {
  // Production seed is empty now, so inject the sample social graph + sightings
  // to exercise gamification and the populated UI.
  final state = AppState(
    birdRepo: StaticBirdRepository(),
    sightingRepo: StaticSightingRepository(sightings: sampleSightings()),
    socialRepo: StaticSocialRepository(
      friends: sampleFriends,
      requests: sampleRequests,
      suggestions: sampleSuggestions,
    ),
    authRepo: DemoAuthRepository(),
  );
  await state.bootstrap(); // marks auth checked (starts signed out)
  await state.signIn(); // signs in + loads everything
  return state;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home screen renders greeting, challenge and bird of the day',
      (tester) async {
    final state = await _loadedState();
    await tester.pumpWidget(BirdCherryApp(appState: state));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Dani'), findsOneWidget);
    expect(find.text('WEEKLY CHALLENGE'), findsOneWidget);
    expect(find.text('Bird of the day'), findsOneWidget);
    expect(find.text('Likely near you'), findsOneWidget);
  });

  testWidgets('log flow opens from the center action', (tester) async {
    final state = await _loadedState();
    await tester.pumpWidget(BirdCherryApp(appState: state));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Who did you spot?'), findsOneWidget);
  });

  testWidgets('birdpedia lists and filters species', (tester) async {
    final state = await _loadedState();
    await tester.pumpWidget(BirdCherryApp(appState: state));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Birdpedia'));
    await tester.pump(const Duration(milliseconds: 400));

    // Birdpedia defaults to the Aviary; switch to the Guide to browse the DB.
    await tester.tap(find.text('Guide'));
    await tester.pump(const Duration(milliseconds: 400));

    // First grid row alphabetically — guaranteed on screen.
    expect(find.text('African Fish Eagle'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'kea');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kea'), findsWidgets);
    expect(find.text('African Fish Eagle'), findsNothing);
  });

  test('gamification math holds together', () async {
    final state = await _loadedState();

    expect(state.birds.length, 31);
    expect(state.mySightings, isNotEmpty);
    expect(state.myPoints, greaterThan(0));
    // Seeded data includes a rare bald eagle sighting -> Rare Find badge.
    expect(state.earnedBadges.map((b) => b.id), contains('rare-find'));
    // Leaderboard includes me and all four friends.
    expect(state.weeklyLeaderboard.length, 5);
  });
}
