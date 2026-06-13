import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'profile_screen.dart';

/// Manage your flock: accept incoming requests, view friends (and their life
/// lists), remove people, and add new birders.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();

    bool matches(AppUser u) =>
        q.isEmpty ||
        u.name.toLowerCase().contains(q) ||
        u.handle.toLowerCase().contains(q);

    final requests = app.friendRequests.where(matches).toList();
    final friends = app.friends.where(matches).toList();
    final suggestions = app.suggestions.where(matches).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            Haptic.tick();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search people by name or handle…',
              prefixIcon: Icon(Icons.search_rounded, color: BcColors.muted),
            ),
          ),

          if (requests.isNotEmpty) ...[
            const SizedBox(height: 24),
            _heading(context, 'Requests', requests.length),
            const SizedBox(height: 10),
            for (final u in requests)
              _UserTile(
                user: u,
                subtitle: 'Wants to be friends',
                trailing: _RequestActions(
                  onAccept: () {
                    Haptic.confirm();
                    app.acceptFriendRequest(u.id);
                  },
                  onDecline: () {
                    Haptic.tick();
                    app.declineFriendRequest(u.id);
                  },
                ),
              ),
          ],

          const SizedBox(height: 24),
          _heading(context, 'Your flock', app.friends.length),
          const SizedBox(height: 10),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                q.isEmpty ? 'No friends yet — add some below.' : 'No matches.',
                style: text.bodyMedium,
              ),
            ),
          for (final u in friends)
            _UserTile(
              user: u,
              subtitle:
                  '${app.lifeListOf(u.id).length} species · ${app.pointsOf(u.id)} pts',
              onTap: () {
                Haptic.tap();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: u.id)));
              },
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    color: BcColors.muted),
                tooltip: 'Remove friend',
                onPressed: () => _confirmRemove(context, app, u),
              ),
            ),

          const SizedBox(height: 24),
          _heading(context, 'Add friends', suggestions.length),
          const SizedBox(height: 4),
          Text('People you might know around the world.',
              style: text.bodySmall),
          const SizedBox(height: 10),
          for (final u in suggestions)
            _UserTile(
              user: u,
              subtitle: u.home,
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BcColors.ink,
                  minimumSize: const Size(96, 40),
                ),
                onPressed: () {
                  Haptic.confirm();
                  app.sendFriendRequest(u.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Friend request sent to ${u.name.split(' ').first}')),
                  );
                },
                child: const Text('Add'),
              ),
            ),
          if (suggestions.isEmpty && q.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('You’ve added everyone we suggested!',
                  style: text.bodyMedium),
            ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String title, int count) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: text.headlineSmall),
        const SizedBox(width: 8),
        Text('$count', style: text.bodyMedium),
      ],
    );
  }

  void _confirmRemove(BuildContext context, AppState app, AppUser u) {
    Haptic.tap();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BcColors.canvas,
        title: Text('Remove ${u.name.split(' ').first}?'),
        content: const Text(
            'They’ll move back to suggestions and drop off your leaderboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BcColors.cherry),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              app.removeFriend(u.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final AppUser user;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: onTap != null,
        label: '${user.name}. $subtitle',
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  UserAvatar(user: user, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: text.titleMedium),
                        const SizedBox(height: 1),
                        Text(subtitle,
                            style: text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({required this.onAccept, required this.onDecline});

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDecline,
          icon: const Icon(Icons.close_rounded, color: BcColors.muted),
          tooltip: 'Decline',
        ),
        const SizedBox(width: 2),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: BcColors.leaf,
            minimumSize: const Size(80, 40),
          ),
          onPressed: onAccept,
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
