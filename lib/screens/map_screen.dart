import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';

enum _MapFilter { everyone, me, friends }

/// World map of sightings. Tap a pin for the sighting; tap anywhere else
/// to see which birds to expect in that part of the world.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  _MapFilter _filter = _MapFilter.everyone;
  String? _friendId; // when set (and filter==friends), show just this friend

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sightings = switch (_filter) {
      _MapFilter.everyone => app.allSightings,
      _MapFilter.me => app.mySightings,
      _MapFilter.friends => _friendId == null
          ? app.friendSightings
          : app.sightingsOf(_friendId!),
    };

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: const LatLng(30.2862, -97.7394),
            initialZoom: 4,
            minZoom: 2,
            maxZoom: 18,
            backgroundColor: BcColors.cream,
            onTap: (_, point) => _showRegionSheet(point),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'com.selerim.birdcherry',
            ),
            MarkerLayer(
              markers: [
                for (final s in sightings)
                  Marker(
                    point: s.point,
                    width: 44,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: _SightingPin(
                      sighting: s,
                      onTap: () => _showSightingSheet(s),
                    ),
                  ),
              ],
            ),
            const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8, bottom: 96),
                child: _Attribution(),
              ),
            ),
          ],
        ),

        // Filter chips + (when Friends) a per-friend selector.
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _filterChip('Everyone', _MapFilter.everyone),
                    const SizedBox(width: 8),
                    _filterChip('Just me', _MapFilter.me),
                    const SizedBox(width: 8),
                    _filterChip('Friends', _MapFilter.friends),
                  ],
                ),
              ),
              if (_filter == _MapFilter.friends && app.friends.isNotEmpty)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    children: [
                      _friendDot(null, 'All', app),
                      for (final f in app.friends) ...[
                        const SizedBox(width: 8),
                        _friendDot(f.id, f.name.split(' ').first, app),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Hint pill.
        Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Center(
            child: ExcludeSemantics(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: BcColors.ink.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Tap anywhere to explore birds of that region',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, _MapFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        Haptic.tick();
        setState(() {
          _filter = value;
          _friendId = null; // reset per-friend selection on filter change
        });
      },
    );
  }

  /// A small avatar pill to filter the map to one friend (or All).
  Widget _friendDot(String? id, String label, AppState app) {
    final selected = _friendId == id;
    final user = id == null ? null : app.userById(id);
    return GestureDetector(
      onTap: () {
        Haptic.tick();
        setState(() => _friendId = id);
        if (user != null) {
          _controller.move(user.homePoint, 4);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: selected ? BcColors.ink : BcColors.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? BcColors.ink : BcColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user == null)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: BcColors.cream, shape: BoxShape.circle),
                child: Icon(Icons.groups_rounded,
                    size: 16,
                    color: selected ? Colors.white : BcColors.inkSoft),
              )
            else
              UserAvatar(user: user, size: 28),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : BcColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  void _showSightingSheet(Sighting s) {
    Haptic.tap();
    final app = context.read<AppState>();
    final bird = app.birdById(s.birdId);
    final user = app.userById(s.userId);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BirdImage(bird: bird, size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bird.name,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        RarityChip(rarity: bird.rarity),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  UserAvatar(user: user, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${user.isMe ? 'You' : user.name} · ${timeAgo(s.seenAt)} · ${s.place}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (s.note != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BcColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('“${s.note}”',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic, color: BcColors.ink)),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => BirdDetailScreen(bird: bird)));
                  },
                  child: Text('About ${bird.name}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRegionSheet(LatLng point) {
    Haptic.tick();
    final app = context.read<AppState>();
    final region = Region.fromLatLng(point);
    final live = app.hasLiveNearby;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, scrollController) => FutureBuilder<List<Bird>>(
          future: app.birdsNear(point),
          builder: (context, snap) {
            final birds = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(live ? 'Seen here recently' : 'Birds of ${region.label}',
                      style: Theme.of(context).textTheme.displaySmall),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    birds == null
                        ? (live
                            ? 'Checking eBird for recent reports…'
                            : 'Loading the regional guide…')
                        : (live
                            ? '${birds.length} species reported nearby on eBird · last 2 weeks'
                            : '${birds.length} species in the BirdCherry guide · sorted by rarity'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (birds == null)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: BcColors.cherry),
                    ),
                  )
                else if (birds.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No recent reports near here.',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: birds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _regionTile(birds[i], app, sheetContext),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _regionTile(Bird bird, AppState app, BuildContext sheetContext) {
    final seen = app.seenByMe(bird.id);
    final subtitle = bird.call.isNotEmpty ? '♪ ${bird.call}' : bird.family;
    return Semantics(
      button: true,
      label: '${bird.name}, ${bird.rarity.label}. $subtitle',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BirdDetailScreen(bird: bird)));
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                BirdImage(bird: bird, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(bird.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (seen) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: BcColors.leaf),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RarityChip(rarity: bird.rarity, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SightingPin extends StatelessWidget {
  const _SightingPin({required this.sighting, required this.onTap});

  final Sighting sighting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final user = app.userById(sighting.userId);
    final bird = app.birdById(sighting.birdId);
    final color = user.isMe ? BcColors.cherry : user.color;
    return Semantics(
      button: true,
      label: '${bird.name} seen by ${user.isMe ? 'you' : user.name} '
          'at ${sighting.place}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: BcColors.ink.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                user.isMe ? '★' : user.initials.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Pin tail.
            Container(
              width: 3,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '© OpenStreetMap contributors · © CARTO',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
      ),
    );
  }
}
