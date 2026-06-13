import 'package:birdcherry/data/repositories.dart';
import 'package:birdcherry/screens/bird_detail_screen.dart';
import 'package:birdcherry/state/app_state.dart';
import 'package:birdcherry/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('bird detail renders and call card degrades without a key',
      (tester) async {
    final state = AppState(
      birdRepo: StaticBirdRepository(),
      sightingRepo: StaticSightingRepository(),
      socialRepo: StaticSocialRepository(),
      authRepo: DemoAuthRepository(),
    );
    await state.load();
    final bird = state.birds.firstWhere((b) => b.name == 'Northern Cardinal');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: BcTheme.light(),
          home: BirdDetailScreen(bird: bird),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Northern Cardinal'), findsWidgets);
    expect(find.text('SONG & CALL'), findsOneWidget);
    // No xeno-canto key configured in tests -> graceful caption.
    expect(find.text('Add a xeno-canto key to hear real recordings.'),
        findsOneWidget);
  });
}
