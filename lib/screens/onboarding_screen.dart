import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/logo.dart';

/// A short intro carousel followed by a sign-in sheet. Auth is a demo today
/// (any credentials work and sign you in as the sample profile); the flow and
/// screens are real so wiring Supabase auth later is a drop-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.travel_explore_rounded,
      color: BcColors.leaf,
      title: 'Every bird, everywhere',
      body:
          'Search 11,000+ species from the eBird world guide, with live photos and real recordings.',
    ),
    (
      icon: Icons.add_location_alt_rounded,
      color: BcColors.cherry,
      title: 'Log what you see',
      body:
          'Tap one button to record a sighting. Watch your life list and your aviary grow.',
    ),
    (
      icon: Icons.groups_rounded,
      color: BcColors.gold,
      title: 'Bird with your flock',
      body:
          'Follow friends, see their sightings on the map, and climb the weekly leaderboard together.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSignIn() {
    Haptic.tap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _SignInSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const BcWordmark(markSize: 38, fontSize: 19),
                  const Spacer(),
                  TextButton(
                    onPressed: _openSignIn,
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  Haptic.tick();
                  setState(() => _page = i);
                },
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 60, color: p.color),
                        ),
                        const SizedBox(height: 40),
                        Text(p.title,
                            style: text.displaySmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Text(p.body,
                            style: text.bodyLarge?.copyWith(color: BcColors.inkSoft),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _page == i ? BcColors.ink : BcColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: BcColors.cherry),
                  onPressed: _openSignIn,
                  child: const Text('Get started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInSheet extends StatefulWidget {
  const _SignInSheet();

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false; // real auth only: we emailed a one-time code
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Demo: immediate sign-in. Real: send an email code, then reveal the field.
  Future<void> _continue() async {
    Haptic.confirm();
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();
    setState(() => _error = null);

    if (!app.requiresOtp) {
      await app.signIn(email: email);
      if (navigator.canPop()) navigator.pop();
      return;
    }
    try {
      await app.sendOtp(email);
      if (mounted) setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Couldn’t send a code. Check the email and try again.');
    }
  }

  Future<void> _verify() async {
    Haptic.confirm();
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    setState(() => _error = null);
    try {
      await app.verifyOtp(_emailController.text.trim(), _codeController.text.trim());
      // Root Consumer swaps to the app on success; close the sheet.
      if (navigator.canPop()) navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _error = 'That code didn’t match. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final app = context.watch<AppState>();
    final signingIn = app.signingIn;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BcColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(_codeSent ? 'Check your email' : 'Welcome',
                style: text.displaySmall),
            const SizedBox(height: 6),
            Text(
              _codeSent
                  ? 'We sent a one-time code to ${_emailController.text.trim()}.'
                  : 'Sign in to start your life list.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 22),
            if (!_codeSent)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon:
                      Icon(Icons.mail_outline_rounded, color: BcColors.muted),
                ),
              )
            else
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '6-digit code',
                  prefixIcon:
                      Icon(Icons.password_rounded, color: BcColors.muted),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: text.bodySmall?.copyWith(color: BcColors.cherry)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: BcColors.cherry),
              onPressed: signingIn ? null : (_codeSent ? _verify : _continue),
              child: signingIn
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_codeSent
                      ? 'Verify & continue'
                      : (app.requiresOtp ? 'Email me a code' : 'Continue')),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: signingIn
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _codeController.clear();
                        }),
                child: const Text('Use a different email'),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.face_rounded, size: 18, color: BcColors.muted),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'We’ll remember you and offer Face ID next time.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              app.requiresOtp
                  ? 'We’ll email you a one-time code — no password to remember.'
                  : 'Demo mode — any email signs you in as the sample birder. Real accounts arrive with Supabase auth.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
