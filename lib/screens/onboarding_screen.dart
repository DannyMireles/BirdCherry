import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/logo.dart';

/// A short intro carousel followed by a sign-in sheet. With Supabase configured
/// it emails a 6-digit code and shows a code-entry step (iOS auto-fills it);
/// in demo mode any email signs you straight in as the sample profile.
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
  bool _codeSent = false; // real auth: we emailed a 6-digit code
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);

  /// Demo: immediate sign-in. Real: email a 6-digit code, then show the
  /// code-entry step.
  Future<void> _sendOrSignIn() async {
    Haptic.confirm();
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();
    setState(() => _error = null);

    if (!app.usesEmailCode) {
      await app.signIn(email: email);
      if (navigator.canPop()) navigator.pop();
      return;
    }
    if (!_looksLikeEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    try {
      await app.sendCode(email);
      if (mounted) setState(() => _codeSent = true);
    } catch (e) {
      final s = e.toString().toLowerCase();
      final rateLimited =
          s.contains('rate') || s.contains('429') || s.contains('over_email');
      if (mounted) {
        setState(() => _error = rateLimited
            ? 'Too many emails right now — wait a minute, then try again.'
            : 'Couldn’t send the code. Check the email and try again.');
      }
    }
  }

  /// Verify the typed/auto-filled code; on success dismiss the sheet so the
  /// app (now signed in) shows through.
  Future<void> _verify() async {
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.length < 6 || app.signingIn) return;
    setState(() => _error = null);
    Haptic.confirm();
    try {
      await app.verifyCode(email, code);
      if (navigator.canPop()) navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'That code didn’t work. Check it and try again.');
        _codeController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final app = context.watch<AppState>();
    final signingIn = app.signingIn;
    final email = _emailController.text.trim();

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

            if (_codeSent) ...[
              // Code-entry state — the field auto-fills from the email on iOS
              // and auto-submits once six digits are present.
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: BcColors.leaf.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      size: 34, color: BcColors.leaf),
                ),
              ),
              const SizedBox(height: 18),
              Text('Enter your code', style: text.displaySmall),
              const SizedBox(height: 6),
              Text(
                'We emailed a 6-digit code to $email. It expires in an hour.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: text.displaySmall?.copyWith(
                    letterSpacing: 12, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                ),
                onChanged: (v) {
                  if (_error != null) setState(() => _error = null);
                  if (v.trim().length == 6) _verify();
                },
                onSubmitted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: text.bodySmall?.copyWith(color: BcColors.cherry),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 14),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: BcColors.cherry),
                onPressed: signingIn ? null : _verify,
                child: signingIn
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & sign in'),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: signingIn ? null : _sendOrSignIn,
                child: const Text('Resend code'),
              ),
              TextButton(
                onPressed: signingIn
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _codeController.clear();
                          _error = null;
                        }),
                child: const Text('Use a different email'),
              ),
            ] else ...[
              Text('Welcome', style: text.displaySmall),
              const SizedBox(height: 6),
              Text('Sign in to start your life list.', style: text.bodyMedium),
              const SizedBox(height: 22),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.go,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _sendOrSignIn(),
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon:
                      Icon(Icons.mail_outline_rounded, color: BcColors.muted),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: text.bodySmall?.copyWith(color: BcColors.cherry)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: BcColors.cherry),
                onPressed: signingIn ? null : _sendOrSignIn,
                child: signingIn
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(app.usesEmailCode ? 'Email me a code' : 'Continue'),
              ),
              const SizedBox(height: 16),
              Text(
                app.usesEmailCode
                    ? 'No password — we’ll email you a 6-digit code.'
                    : 'Demo mode — any email signs you in as the sample birder.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
