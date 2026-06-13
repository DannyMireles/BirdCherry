import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'data/repositories.dart';
import 'data/supabase_repositories.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // When a Supabase project is configured (--dart-define SUPABASE_URL +
  // SUPABASE_ANON_KEY), use the real backend; otherwise everything runs on
  // local demo data. The species catalog always comes live from eBird.
  late final AppState appState;
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Accepts either a legacy anon JWT or a new publishable key.
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
      // Auth is an emailed 6-digit code verified in-app (verifyOTP) — no deep
      // link or redirect needed. supabase_flutter persists the session and
      // auto-refreshes it, so returning users aren't asked for a new code.
    );
    appState = AppState(
      birdRepo: StaticBirdRepository(), // curated set; eBird adds the rest
      sightingRepo: SupabaseSightingRepository(),
      socialRepo: SupabaseSocialRepository(),
      authRepo: SupabaseAuthRepository(),
    );
  } else {
    appState = AppState(
      birdRepo: StaticBirdRepository(),
      sightingRepo: StaticSightingRepository(),
      socialRepo: StaticSocialRepository(),
      authRepo: DemoAuthRepository(),
    );
  }
  appState.bootstrap();

  runApp(BirdCherryApp(appState: appState));
}

class BirdCherryApp extends StatelessWidget {
  const BirdCherryApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'BirdCherry',
        debugShowCheckedModeBanner: false,
        theme: BcTheme.light(),
        home: Consumer<AppState>(
          builder: (context, app, _) {
            if (!app.authChecked) return const _SplashScreen();
            if (app.locked) return const LockScreen();
            if (!app.signedIn) return const OnboardingScreen();
            if (!app.loaded) return const _SplashScreen();
            return const Shell();
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BcLogo(size: 132),
            const SizedBox(height: 16),
            Text('BirdCherry', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text('Birdwatching, together',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
