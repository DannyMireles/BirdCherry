import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/logo.dart';

/// Shown to returning users with a saved session: unlock with Face ID / Touch
/// ID (or device passcode) to restore your session. "Not you?" signs out and
/// returns to onboarding.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Offer the prompt immediately, the way most apps do.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.tap();
    final ok = await context.read<AppState>().unlock();
    if (mounted && !ok) setState(() => _busy = false);
    // On success the root Consumer swaps to the app.
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const BcLogo(size: 120),
              const SizedBox(height: 18),
              Text('Welcome back', style: text.displaySmall),
              const SizedBox(height: 6),
              Text('Unlock to pick up where you left off.',
                  style: text.bodyMedium, textAlign: TextAlign.center),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: BcColors.cherry),
                  onPressed: _busy ? null : _unlock,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.face_rounded),
                  label: const Text('Unlock with Face ID'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        Haptic.tick();
                        context.read<AppState>().signOut();
                      },
                child: const Text('Not you? Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
