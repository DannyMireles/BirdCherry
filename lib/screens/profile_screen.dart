import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'friends_screen.dart';

/// A birder's profile: level, stats, badge case, and life list. Renders for
/// yourself (with Friends + Settings) or for any friend you tap into.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.userId});

  /// Null = your own profile.
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final isMe = userId == null || userId == app.me.id;
    final user = isMe ? app.me : app.userById(userId!);
    final uid = user.id;

    final lifeList = app.lifeListOf(uid).map(app.birdById).toList()
      ..sort((a, b) => b.points.compareTo(a.points));
    final earned = app.earnedBadgesOf(uid);
    final locked = app.lockedBadgesOf(uid);
    final firstName = user.name.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMe ? 'Profile' : firstName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            Haptic.tick();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Haptic.tap();
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => const _SettingsSheet(),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              UserAvatar(user: user, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: text.headlineMedium),
                    Text(
                      [user.handle, if (user.home.isNotEmpty) user.home].join(' · '),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Level card.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('LEVEL ${app.levelOf(uid)}',
                            style: text.labelSmall),
                      ),
                      Text(
                          '${app.pointsToNextLevelOf(uid)} pts to level ${app.levelOf(uid) + 1}',
                          style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_levelName(app.levelOf(uid)), style: text.headlineSmall),
                  const SizedBox(height: 14),
                  Semantics(
                    label:
                        'Level progress: ${(app.levelProgressOf(uid) * 100).round()} percent',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: app.levelProgressOf(uid)),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: BcColors.cream,
                          color: BcColors.cherry,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats grid.
          Row(
            children: [
              _stat(context, '${lifeList.length}', 'species'),
              const SizedBox(width: 10),
              _stat(context, '${app.sightingsOf(uid).length}', 'sightings'),
              const SizedBox(width: 10),
              _stat(context, '${app.streakOf(uid)}', 'day streak'),
              const SizedBox(width: 10),
              _stat(context, '${app.pointsOf(uid)}', 'points'),
            ],
          ),

          // Friends row (own profile only).
          if (isMe) ...[
            const SizedBox(height: 12),
            _FriendsRow(
              friendCount: app.friends.length,
              requestCount: app.friendRequests.length,
              onTap: () {
                Haptic.tap();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const FriendsScreen()));
              },
            ),
          ],

          const SizedBox(height: 28),
          Text('Badge case', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('${earned.length} of ${earned.length + locked.length} earned',
              style: text.bodySmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final b in earned)
                _BadgeTile(name: b.name, blurb: b.blurb, icon: b.icon, earned: true),
              for (final b in locked)
                _BadgeTile(name: b.name, blurb: b.blurb, icon: b.icon, earned: false),
            ],
          ),

          const SizedBox(height: 28),
          Text('Life list', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
              isMe
                  ? 'Every species you’ve ever logged, best first'
                  : 'Species $firstName has logged, best first',
              style: text.bodySmall),
          const SizedBox(height: 14),
          if (lifeList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No sightings logged yet.', style: text.bodyMedium),
            ),
          for (final bird in lifeList)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                button: true,
                label: '${bird.name}, ${bird.points} points',
                child: GestureDetector(
                  onTap: () {
                    Haptic.tap();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BirdDetailScreen(bird: bird)));
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          BirdImage(bird: bird, size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(bird.name, style: text.titleMedium),
                          ),
                          RarityChip(rarity: bird.rarity, compact: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _levelName(int level) => switch (level) {
        1 => 'Fledgling',
        2 => 'Hatchling Hunter',
        3 => 'Branch Hopper',
        4 => 'Keen Eye',
        5 => 'Field Regular',
        6 => 'Sharp Spotter',
        7 => 'Wing Expert',
        8 => 'Master Birder',
        _ => 'Living Legend',
      };

  Widget _stat(BuildContext context, String value, String label) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        label: '$value $label',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: BcColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BcColors.line),
          ),
          child: ExcludeSemantics(
            child: Column(
              children: [
                Text(value, style: text.headlineSmall),
                const SizedBox(height: 2),
                Text(label, style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsRow extends StatelessWidget {
  const _FriendsRow({
    required this.friendCount,
    required this.requestCount,
    required this.onTap,
  });

  final int friendCount;
  final int requestCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Friends. $friendCount friends'
          '${requestCount > 0 ? ', $requestCount pending requests' : ''}.',
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, color: BcColors.leaf),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Friends', style: text.titleMedium),
                ),
                if (requestCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: BcColors.cherry,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('$requestCount new',
                        style: text.labelSmall?.copyWith(color: Colors.white)),
                  ),
                Text('$friendCount', style: text.titleMedium),
                const Icon(Icons.chevron_right_rounded, color: BcColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: text.headlineSmall),
            const SizedBox(height: 16),
            _statusRow('Live bird photos', 'Wikipedia + iNaturalist', true),
            _statusRow('eBird “near you” data',
                AppConfig.hasEbirdKey ? 'Connected' : 'Add a key to enable',
                AppConfig.hasEbirdKey),
            _statusRow('Bird call audio (xeno-canto)',
                AppConfig.hasXenoCantoKey ? 'Connected' : 'Add a key to enable',
                AppConfig.hasXenoCantoKey),
            _statusRow('Account & sync (Supabase)', 'Demo mode — not connected',
                false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: BcColors.cherry,
                  side: const BorderSide(color: BcColors.line),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                onPressed: () {
                  Haptic.confirm();
                  Navigator.of(context).pop(); // close sheet
                  Navigator.of(context).maybePop(); // close profile if pushed
                  app.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value, bool ok) {
    return Builder(builder: (context) {
      final text = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18, color: ok ? BcColors.leaf : BcColors.muted),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: text.titleSmall)),
            Text(value, style: text.bodySmall),
          ],
        ),
      );
    });
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.name,
    required this.blurb,
    required this.icon,
    required this.earned,
  });

  final String name;
  final String blurb;
  final IconData icon;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: earned ? 'Badge earned: $name. $blurb' : 'Badge locked: $name. $blurb',
      child: Tooltip(
        message: blurb,
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: earned ? BcColors.leafSoft : BcColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: earned ? BcColors.leaf.withValues(alpha: 0.4) : BcColors.line),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 26, color: earned ? BcColors.leaf : BcColors.muted),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: text.labelMedium?.copyWith(
                    color: earned ? BcColors.ink : BcColors.muted),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
