import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Home: greeting, streak, weekly challenge, bird of the day,
/// birds to expect near you, and birds your friends are beating you on.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;

    final hour = DateTime.now().hour;
    final greeting = hour < 5
        ? 'Night owl hours'
        : hour < 12
            ? 'Good morning'
            : hour < 18
                ? 'Good afternoon'
                : 'Good evening';

    // "Bird of the day" rotates deterministically by date.
    final dayIndex = DateTime.now().difference(DateTime(2026)).inDays;
    final birdOfDay = app.birds[dayIndex % app.birds.length];

    final rivalry = app.birdsFriendsHaveSeen.take(6).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting.toUpperCase(), style: text.labelSmall),
                        const SizedBox(height: 2),
                        // Shrink-to-fit so a long name/handle stays on one line.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(app.me.name.split(' ').first,
                              maxLines: 1, style: text.displayMedium),
                        ),
                      ],
                    ),
                  ),
                  _StreakPill(streak: app.myStreak),
                  const SizedBox(width: 8),
                  const NotificationsBell(),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Open your profile',
                    child: GestureDetector(
                      onTap: () {
                        Haptic.tap();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ProfileScreen()));
                      },
                      child: UserAvatar(user: app.me, size: 44),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Weekly challenge card.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _ChallengeCard(
                progress: app.weeklyChallengeProgress,
                goal: AppState.weeklyChallengeGoal,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SectionHeader(title: 'Bird of the day'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _BirdOfDayCard(bird: birdOfDay),
            ),
          ),

          SliverToBoxAdapter(
            child: SectionHeader(
                title: app.hasLiveNearby ? 'Seen near you lately' : 'Likely near you'),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 208,
              child: FutureBuilder<List<Bird>>(
                future: app.birdsNear(app.me.homePoint),
                builder: (context, snap) {
                  final nearMe = snap.data;
                  if (nearMe == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: BcColors.cherry),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: nearMe.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _NearbyCard(
                        bird: nearMe[i], seen: app.seenByMe(nearMe[i].id)),
                  );
                },
              ),
            ),
          ),

          if (rivalry.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Your flock is ahead on these'),
            ),
            SliverList.separated(
              itemCount: rivalry.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final (bird, users) = rivalry[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _RivalryTile(bird: bird, users: users),
                );
              },
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Semantics(
      label: active
          ? 'Current streak: $streak days'
          : 'No active streak — log a bird today',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? BcColors.cherry.withValues(alpha: 0.1) : BcColors.cream,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 18, color: active ? BcColors.cherry : BcColors.muted),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: active ? BcColors.cherry : BcColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.progress, required this.goal});

  final int progress;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = progress >= goal;
    final fraction = (progress / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('WEEKLY CHALLENGE', style: text.labelSmall)),
                Text(
                  done ? 'Complete!' : '$progress of $goal',
                  style: text.titleSmall?.copyWith(
                      color: done ? BcColors.leaf : BcColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Log $goal species this week', style: text.titleLarge),
            const SizedBox(height: 14),
            Semantics(
              label: 'Weekly challenge progress: $progress of $goal species',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: BcColors.cream,
                    color: done ? BcColors.leaf : BcColors.cherry,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirdOfDayCard extends StatelessWidget {
  const _BirdOfDayCard({required this.bird});

  final Bird bird;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Bird of the day: ${bird.name}. Open details.',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: bird)));
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Hero(
                tag: 'bird-image-${bird.id}',
                child: BirdImage(
                  bird: bird,
                  size: 116,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bird.name, style: text.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        bird.funFact,
                        style: text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      RarityChip(rarity: bird.rarity),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Icon(Icons.chevron_right_rounded, color: BcColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.bird, required this.seen});

  final Bird bird;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          '${bird.name}, ${bird.rarity.label}${seen ? ', already on your life list' : ''}',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: bird)));
        },
        child: SizedBox(
          width: 150,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    BirdImage(
                        bird: bird, size: 148, borderRadius: BorderRadius.zero),
                    if (seen)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: BcColors.leaf,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Text(
                    bird.name,
                    style: text.titleSmall?.copyWith(color: BcColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                  child: Text(bird.rarity.label,
                      style: text.bodySmall
                          ?.copyWith(color: rarityColor(bird.rarity))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RivalryTile extends StatelessWidget {
  const _RivalryTile({required this.bird, required this.users});

  final Bird bird;
  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final names = users.length == 1
        ? users.first.name.split(' ').first
        : '${users.first.name.split(' ').first} +${users.length - 1}';
    return Semantics(
      button: true,
      label: '${bird.name}, seen by $names but not by you yet. '
          'Worth ${bird.points} points.',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: bird)));
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                BirdImage(bird: bird, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bird.name,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Seen by $names — not you. Yet.',
                          style: text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('+${bird.points}',
                    style: text.titleMedium?.copyWith(color: BcColors.cherry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
