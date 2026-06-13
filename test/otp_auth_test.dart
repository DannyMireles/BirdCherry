import 'dart:async';

import 'package:birdcherry/data/repositories.dart';
import 'package:birdcherry/models/models.dart';
import 'package:birdcherry/screens/onboarding_screen.dart';
import 'package:birdcherry/state/app_state.dart';
import 'package:birdcherry/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the Supabase auth repo: real-auth (email-code) behaviour,
/// recording what was sent/verified and emitting a session like verifyOTP does.
class FakeOtpAuthRepository implements AuthRepository {
  final _authChanges = StreamController<bool>.broadcast();
  String? sentTo;
  String? verifiedCode;

  @override
  bool get usesEmailCode => true;

  @override
  Stream<bool> get authChanges => _authChanges.stream;

  @override
  Future<AppUser?> currentUser() async => null;

  @override
  Future<bool> hasSavedSession() async => false;

  @override
  Future<AppUser> signIn({String? email}) =>
      throw UnsupportedError('uses email code');

  @override
  Future<void> sendCode(String email) async => sentTo = email;

  @override
  Future<void> verifyCode(String email, String code) async {
    verifiedCode = code;
    _authChanges.add(true); // mirrors verifyOTP creating a session
  }

  @override
  Future<void> signOut() async => _authChanges.add(false);
}

Widget _host(AppState state, Widget child) => ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(theme: BcTheme.light(), home: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('OTP flow: email step → code step → verifies and signs in',
      (tester) async {
    final auth = FakeOtpAuthRepository();
    final state = AppState(
      birdRepo: StaticBirdRepository(),
      sightingRepo: StaticSightingRepository(),
      socialRepo: StaticSocialRepository(),
      authRepo: auth,
    );
    await state.bootstrap();
    await tester.pumpWidget(_host(state, const OnboardingScreen()));
    await tester.pump();

    // Open the sign-in sheet.
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Real-auth copy: a code, not a magic link or password.
    expect(find.text('Email me a code'), findsOneWidget);

    // Enter an email and request a code.
    await tester.enterText(find.byType(TextField).first, 'birder@example.com');
    await tester.tap(find.text('Email me a code'));
    await tester.pumpAndSettle();
    expect(auth.sentTo, 'birder@example.com');

    // Code-entry step is shown.
    expect(find.text('Enter your code'), findsOneWidget);

    // Typing/auto-filling six digits auto-submits and verifies.
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();

    expect(auth.verifiedCode, '123456');
    expect(state.signedIn, isTrue);
    expect(state.loaded, isTrue);
  });

  testWidgets('OTP code field advertises one-time-code autofill',
      (tester) async {
    final auth = FakeOtpAuthRepository();
    final state = AppState(
      birdRepo: StaticBirdRepository(),
      sightingRepo: StaticSightingRepository(),
      socialRepo: StaticSocialRepository(),
      authRepo: auth,
    );
    await state.bootstrap();
    await tester.pumpWidget(_host(state, const OnboardingScreen()));
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'birder@example.com');
    await tester.tap(find.text('Email me a code'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    expect(field.keyboardType, TextInputType.number);
  });
}
