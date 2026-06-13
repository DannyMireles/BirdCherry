import 'package:birdcherry/data/repositories.dart';
import 'package:birdcherry/models/models.dart';
import 'package:birdcherry/screens/bird_detail_screen.dart';
import 'package:birdcherry/state/app_state.dart';
import 'package:birdcherry/widgets/common.dart';
import 'package:birdcherry/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A worst-case species: every continent + a long habitat string, so the
/// "geography" fact pills must wrap instead of running off the side.
const _busyBird = Bird(
  id: 'test-busy',
  name: 'Resplendent Quetzal',
  scientificName: 'Pharomachrus mocinno',
  family: 'Trogonidae',
  rarity: Rarity.legendary,
  regions: {
    Region.northAmerica,
    Region.southAmerica,
    Region.europe,
    Region.africa,
    Region.asia,
    Region.oceania,
  },
  habitat: 'Cloud forest, montane rainforest and humid highland woodland edges',
  size: '36–40 cm',
  description: 'A dazzling trogon of Central American cloud forests.',
  funFact: 'Its tail streamers can be nearly a metre long.',
  call: 'keow keow',
  wikiTitle: 'Resplendent_quetzal',
  tint: Color(0xFF2F5D45),
);

Future<AppState> _state() async {
  final state = AppState(
    birdRepo: StaticBirdRepository(),
    sightingRepo: StaticSightingRepository(),
    socialRepo: StaticSocialRepository(),
    authRepo: DemoAuthRepository(),
  );
  await state.load();
  return state;
}

Widget _host(AppState state, Widget child) => ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(theme: BcTheme.light(), home: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bird detail: many regions lay out with no overflow + zoom hint',
      (tester) async {
    // Real phone dimensions so the fact pills wrap at a true width.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _state();
    await tester.pumpWidget(_host(state, const BirdDetailScreen(bird: _busyBird)));
    await tester.pump(const Duration(milliseconds: 600));

    // No RenderFlex overflow was thrown while laying out.
    expect(tester.takeException(), isNull);
    // Each continent renders as its own pill.
    expect(find.text('Oceania'), findsOneWidget);
    expect(find.text('North America'), findsOneWidget);
    // The photo carries a zoom affordance.
    expect(find.text('Tap to zoom'), findsOneWidget);
  });

  testWidgets('tapping the header photo opens a full-screen zoom viewer',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _state();
    await tester.pumpWidget(_host(state, const BirdDetailScreen(bird: _busyBird)));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byType(BirdImage).first);
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('logging a bird shows the celebration with confetti',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _state();
    final bird = state.birds.firstWhere((b) => b.name == 'Northern Cardinal');
    await tester.pumpWidget(_host(state, BirdDetailScreen(bird: bird)));
    await tester.pump(const Duration(milliseconds: 600));

    // Open the log sheet (species preselected) via the bottom CTA, then save.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Log sighting'));
    await tester.pump(); // build the overlay
    await tester.pump(const Duration(milliseconds: 300)); // confetti first frames

    expect(tester.takeException(), isNull);
    expect(find.text('Keep birding'), findsOneWidget);
    expect(find.textContaining('points'), findsWidgets);
  });
}
