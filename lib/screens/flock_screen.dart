import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';

/// Social hub: live feed of everyone's sightings + the weekly leaderboard.
class FlockScreen extends StatefulWidget {
  const FlockScreen({super.key});

  @override
  State<FlockScreen> createState() => _FlockScreenState();
}

class _FlockScreenState extends State<FlockScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(child: Text('Flock', style: text.displayMedium)),
                _FriendsButton(
                  requestCount: context.select<AppState, int>(
                      (a) => a.friendRequests.length),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: BcColors.cream,
                borderRadius: BorderRadius.circular(99),
              ),
              child: TabBar(
                controller: _tabs,
                onTap: (_) => Haptic.tick(),
                indicator: BoxDecoration(
                  color: BcColors.ink,
                  borderRadius: BorderRadius.circular(99),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: BcColors.inkSoft,
                labelStyle: text.labelLarge,
                tabs: const [
                  Tab(text: 'Feed', height: 44),
                  Tab(text: 'Leaderboard', height: 44),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [_FeedTab(), _LeaderboardTab()],
            ),
          ),
        ],
      ),
    );
  }
}

/// People-add button with a pending-request badge, opens Friends.
class _FriendsButton extends StatelessWidget {
  const _FriendsButton({required this.requestCount});

  final int requestCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: requestCount > 0
          ? 'Friends, $requestCount pending requests'
          : 'Friends',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendsScreen()));
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
              color: BcColors.card, shape: BoxShape.circle),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.group_add_outlined, color: BcColors.ink),
              if (requestCount > 0)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: BcColors.cherry,
                      shape: BoxShape.circle,
                      border: Border.all(color: BcColors.canvas, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final feed = app.allSightings;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      itemCount: feed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _FeedCard(sighting: feed[i]),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final text = Theme.of(context).textTheme;
    final bird = app.birdById(sighting.birdId);
    final user = app.userById(sighting.userId);
    final iveSeenIt = app.seenByMe(bird.id);

    return Semantics(
      button: true,
      label:
          '${user.isMe ? 'You' : user.name} spotted a ${bird.name} at ${sighting.place}, ${timeAgo(sighting.seenAt)}',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: bird)));
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(user: user, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.isMe ? 'You' : user.name,
                            style: text.titleSmall?.copyWith(color: BcColors.ink),
                          ),
                          Text(timeAgo(sighting.seenAt), style: text.bodySmall),
                        ],
                      ),
                    ),
                    Text('+${bird.points}',
                        style:
                            text.titleMedium?.copyWith(color: BcColors.cherry)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    BirdImage(bird: bird, size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bird.name, style: text.titleMedium),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 14, color: BcColors.muted),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(sighting.place,
                                    style: text.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          RarityChip(rarity: bird.rarity, compact: true),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sighting.note != null) ...[
                  const SizedBox(height: 10),
                  Text('“${sighting.note}”',
                      style: text.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ],
                if (!user.isMe && !iveSeenIt) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: BcColors.cherry.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('Not on your life list yet',
                        style: text.labelMedium
                            ?.copyWith(color: BcColors.cherry)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final rows = app.weeklyLeaderboard;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        Text('This week', style: text.headlineSmall),
        const SizedBox(height: 4),
        Text('Points from sightings in the last 7 days. Resets Monday.',
            style: text.bodySmall),
        const SizedBox(height: 16),
        for (var i = 0; i < rows.length; i++) ...[
          _LeaderRow(rank: i + 1, user: rows[i].$1, points: rows[i].$2),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: BcColors.gold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tauntFor(app, rows),
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _tauntFor(AppState app, List<(AppUser, int)> rows) {
    final myRank = rows.indexWhere((r) => r.$1.isMe) + 1;
    if (myRank == 1) return 'You’re leading the flock this week. Defend the crown!';
    final ahead = rows[myRank - 2];
    final gap = ahead.$2 - rows[myRank - 1].$2;
    final next = app.birdsFriendsHaveSeen.isNotEmpty
        ? app.birdsFriendsHaveSeen.first.$1
        : null;
    final hint = next == null
        ? 'Get out there!'
        : 'A ${next.name} (+${next.points}) would close the gap fast.';
    return 'You’re $gap points behind ${ahead.$1.name.split(' ').first}. $hint';
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.user, required this.points});

  final int rank;
  final AppUser user;
  final int points;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isTop = rank == 1;
    return Semantics(
      button: true,
      label:
          'Rank $rank: ${user.isMe ? 'you' : user.name}, $points points this week. Open profile.',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ProfileScreen(userId: user.isMe ? null : user.id)));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: user.isMe ? BcColors.ink : BcColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: user.isMe ? BcColors.ink : BcColors.line),
          ),
          child: Row(
          children: [
            SizedBox(
              width: 30,
              child: isTop
                  ? const Icon(Icons.emoji_events_rounded,
                      color: BcColors.gold, size: 24)
                  : Text('$rank',
                      textAlign: TextAlign.center,
                      style: text.titleLarge?.copyWith(
                          color: user.isMe ? Colors.white54 : BcColors.muted)),
            ),
            const SizedBox(width: 10),
            UserAvatar(user: user, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.isMe ? 'You' : user.name,
                    style: text.titleMedium
                        ?.copyWith(color: user.isMe ? Colors.white : BcColors.ink),
                  ),
                  Text(
                    user.home,
                    style: text.bodySmall?.copyWith(
                        color: user.isMe ? Colors.white60 : BcColors.muted),
                  ),
                ],
              ),
            ),
            Text(
              '$points',
              style: text.headlineSmall
                  ?.copyWith(color: user.isMe ? Colors.white : BcColors.ink),
            ),
            Text(
              ' pts',
              style: text.bodySmall?.copyWith(
                  color: user.isMe ? Colors.white60 : BcColors.muted),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
