import 'package:birdcherry/data/repositories.dart';
import 'package:birdcherry/screens/friends_screen.dart';
import 'package:birdcherry/screens/notifications_screen.dart';
import 'package:birdcherry/screens/onboarding_screen.dart';
import 'package:birdcherry/state/app_state.dart';
import 'package:birdcherry/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _signedIn() async {
  final state = AppState(
    birdRepo: StaticBirdRepository(),
    sightingRepo: StaticSightingRepository(),
    socialRepo: StaticSocialRepository(),
    authRepo: DemoAuthRepository(),
  );
  await state.bootstrap();
  await state.signIn();
  return state;
}

Widget _host(AppState state, Widget child) => ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(theme: BcTheme.light(), home: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('auth gating: starts signed out, then signs in', () async {
    final state = AppState(
      birdRepo: StaticBirdRepository(),
      sightingRepo: StaticSightingRepository(),
      socialRepo: StaticSocialRepository(),
      authRepo: DemoAuthRepository(),
    );
    await state.bootstrap();
    expect(state.authChecked, isTrue);
    expect(state.signedIn, isFalse);
    await state.signIn();
    expect(state.signedIn, isTrue);
    expect(state.loaded, isTrue);
  });

  test('friend actions move users between lists', () async {
    final state = await _signedIn();
    final friendsBefore = state.friends.length;
    final requestsBefore = state.friendRequests.length;
    final suggestionsBefore = state.suggestions.length;
    expect(requestsBefore, greaterThan(0));
    expect(suggestionsBefore, greaterThan(0));

    // Accept the first incoming request -> becomes a friend.
    final reqId = state.friendRequests.first.id;
    await state.acceptFriendRequest(reqId);
    expect(state.friends.length, friendsBefore + 1);
    expect(state.friendRequests.length, requestsBefore - 1);
    expect(state.friends.any((u) => u.id == reqId), isTrue);

    // Send a request to a suggestion -> leaves suggestions, marked pending.
    final sugId = state.suggestions.first.id;
    await state.sendFriendRequest(sugId);
    expect(state.suggestions.any((u) => u.id == sugId), isFalse);
    expect(state.isRequestPending(sugId), isTrue);

    // Remove a friend -> back to suggestions.
    final friendId = state.friends.first.id;
    final removed = state.friends.first;
    await state.removeFriend(friendId);
    expect(state.friends.any((u) => u.id == friendId), isFalse);
    expect(state.suggestions.any((u) => u.id == removed.id), isTrue);
  });

  testWidgets('onboarding shows value props and a sign-in entry',
      (tester) async {
    final state = AppState(
      birdRepo: StaticBirdRepository(),
      sightingRepo: StaticSightingRepository(),
      socialRepo: StaticSocialRepository(),
      authRepo: DemoAuthRepository(),
    );
    await state.bootstrap();
    await tester.pumpWidget(_host(state, const OnboardingScreen()));
    await tester.pump();

    expect(find.text('Every bird, everywhere'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('friends screen lists requests, flock and suggestions',
      (tester) async {
    // Tall surface so every section lays out (no below-the-fold misses).
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _signedIn();
    await tester.pumpWidget(_host(state, const FriendsScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your flock'), findsOneWidget);
    expect(find.text('Add friends'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    // An incoming requester is shown with an Accept action.
    expect(find.text('Accept'), findsWidgets);
    // A friend from the seed is listed.
    expect(find.text('Maya Lindqvist'), findsWidgets);
  });

  testWidgets('notifications feed renders friend activity', (tester) async {
    final state = await _signedIn();
    await tester.pumpWidget(_host(state, const NotificationsScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Activity'), findsOneWidget);
    // Incoming friend request card present.
    expect(find.textContaining('wants to be friends'), findsWidgets);
  });
}
