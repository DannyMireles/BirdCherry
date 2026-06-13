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
  bool _linkSent = false; // real auth: we emailed a magic link
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Demo: immediate sign-in. Real: email a magic link, then wait for the tap.
  Future<void> _continue() async {
    Haptic.confirm();
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();
    setState(() => _error = null);

    if (!app.usesMagicLink) {
      await app.signIn(email: email);
      if (navigator.canPop()) navigator.pop();
      return;
    }
    try {
      await app.sendMagicLink(email);
      if (mounted) setState(() => _linkSent = true);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Couldn’t send the link. Check the email and try again.');
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

            if (_linkSent) ...[
              // "Check your email" state — the app continues automatically
              // once the link is tapped (handled by AppState's auth listener).
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
              Text('Check your email', style: text.displaySmall),
              const SizedBox(height: 6),
              Text(
                'We sent a sign-in link to $email. Tap it on this device and '
                'you’ll be signed in automatically.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: signingIn ? null : _continue,
                child: const Text('Resend link'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: signingIn
                    ? null
                    : () => setState(() => _linkSent = false),
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
                onChanged: (_) => setState(() {}),
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
                onPressed: signingIn ? null : _continue,
                child: signingIn
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(app.usesMagicLink
                        ? 'Email me a sign-in link'
                        : 'Continue'),
              ),
              const SizedBox(height: 16),
              Text(
                app.usesMagicLink
                    ? 'No password — just tap the link we email you.'
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
