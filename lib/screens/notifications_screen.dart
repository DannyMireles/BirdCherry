import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'profile_screen.dart';

/// Activity feed: friend sightings, lifers, and incoming friend requests.
/// Derived from the social graph today; real push delivery comes with the
/// Supabase backend (see README).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final feed = app.activityFeed();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            Haptic.tick();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: feed.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 44, color: BcColors.muted),
                  const SizedBox(height: 10),
                  Text('Nothing yet', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text('Your flock’s sightings will show up here.',
                      style: text.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ActivityRow(item: feed[i]),
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final text = Theme.of(context).textTheme;

    if (item.kind == ActivityKind.friendRequest) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(user: item.user, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: item.user.name.split(' ').first,
                            style: text.titleSmall?.copyWith(color: BcColors.ink)),
                        TextSpan(
                            text: ' wants to be friends',
                            style: text.bodyMedium),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BcColors.leaf,
                            minimumSize: const Size(80, 36),
                          ),
                          onPressed: () {
                            Haptic.confirm();
                            app.acceptFriendRequest(item.user.id);
                          },
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(80, 36)),
                          onPressed: () {
                            Haptic.tick();
                            app.declineFriendRequest(item.user.id);
                          },
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sighting / lifer.
    final bird = item.bird!;
    final isLifer = item.kind == ActivityKind.lifer;
    return Semantics(
      button: true,
      label:
          '${item.user.name} spotted a ${bird.name}, ${timeAgo(item.time)}. Open.',
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
                GestureDetector(
                  onTap: () {
                    Haptic.tap();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: item.user.id)));
                  },
                  child: UserAvatar(user: item.user, size: 44),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: item.user.name.split(' ').first,
                              style:
                                  text.titleSmall?.copyWith(color: BcColors.ink)),
                          TextSpan(
                              text: isLifer
                                  ? ' bagged a lifer: '
                                  : ' spotted a ',
                              style: text.bodyMedium),
                          TextSpan(
                              text: bird.name,
                              style:
                                  text.titleSmall?.copyWith(color: BcColors.ink)),
                        ]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.sighting?.place ?? ''} · ${timeAgo(item.time)}',
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BirdImage(bird: bird, size: 48),
                    if (isLifer)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: BcColors.gold, shape: BoxShape.circle),
                          child: const Icon(Icons.star_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bell button with an unread badge, for app bars.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<AppState, int>((a) => a.unreadCount);
    return Semantics(
      button: true,
      label: count > 0 ? 'Activity, $count new' : 'Activity',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: BcColors.card,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, color: BcColors.ink),
              if (count > 0)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: BcColors.cherry,
                      shape: BoxShape.circle,
                      border: Border.all(color: BcColors.canvas, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1),
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
