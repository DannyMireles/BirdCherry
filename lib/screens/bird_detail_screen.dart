import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/xeno_canto_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'log_sighting_sheet.dart';

/// Everything about one species: photo, facts, call, range,
/// your history with it, and which friends have seen it.
class BirdDetailScreen extends StatefulWidget {
  const BirdDetailScreen({super.key, required this.bird});

  final Bird bird;

  @override
  State<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends State<BirdDetailScreen> {
  final AudioPlayer _player = AudioPlayer();

  bool _playing = false;
  bool _loading = false;
  bool _noRecording = false;
  BirdRecording? _recording;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final app = context.read<AppState>();
    Haptic.tap();

    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }

    // No key configured: animate the sonogram as a short teaser.
    if (!app.audio.enabled) {
      setState(() => _playing = true);
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _playing = false);
      });
      return;
    }

    setState(() => _loading = true);
    final rec =
        _recording ?? await app.audio.recordingFor(widget.bird.scientificName);
    if (!mounted) return;
    _recording = rec;
    if (rec == null) {
      setState(() {
        _loading = false;
        _noRecording = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No recording found for this species yet.')));
      return;
    }
    try {
      await _player.play(UrlSource(rec.audioUrl));
      if (mounted) {
        setState(() {
          _loading = false;
          _playing = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final bird = widget.bird;

    final seen = app.seenByMe(bird.id);
    final mySightings =
        app.sightingsForBird(bird.id).where((s) => s.userId == app.me.id);
    final friendsSeen = app
        .sightingsForBird(bird.id)
        .where((s) => s.userId != app.me.id)
        .map((s) => s.userId)
        .toSet()
        .map(app.userById)
        .toList();

    final factPills = <Widget>[
      RarityChip(rarity: bird.rarity),
      if (bird.size.isNotEmpty) _factPill(Icons.straighten_rounded, bird.size),
      if (bird.habitat.isNotEmpty) _factPill(Icons.forest_outlined, bird.habitat),
      for (final r in bird.regions) _factPill(Icons.public, r.label),
      if (bird.regions.isEmpty && !bird.curated)
        _factPill(Icons.menu_book_rounded, 'eBird species'),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () {
                    Haptic.tick();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () {
                  Haptic.tap();
                  Navigator.of(context).push(MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => _BirdPhotoViewer(bird: bird),
                  ));
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'bird-image-${bird.id}',
                      child:
                          BirdImage(bird: bird, borderRadius: BorderRadius.zero),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_out_map_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text('Tap to zoom',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bird.name, style: text.displaySmall),
                            const SizedBox(height: 2),
                            Text(bird.scientificName,
                                style: text.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      if (seen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: BcColors.leafSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 16, color: BcColors.leaf),
                              const SizedBox(width: 4),
                              Text('On your list',
                                  style: text.labelMedium
                                      ?.copyWith(color: BcColors.leaf)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: factPills),
                  const SizedBox(height: 20),
                  Text(
                    bird.hasProse
                        ? bird.description
                        : 'A member of the ${bird.family} family. We don’t have a '
                            'written profile yet — enjoy the live photo and, with '
                            'sound enabled, its real recordings.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  _buildCallCard(bird, app, text),
                  const SizedBox(height: 16),

                  if (bird.funFact.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BcColors.cream,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DID YOU KNOW?', style: text.labelSmall),
                          const SizedBox(height: 6),
                          Text(bird.funFact, style: text.bodyLarge),
                        ],
                      ),
                    ),

                  if (mySightings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Your sightings', style: text.headlineSmall),
                    const SizedBox(height: 10),
                    for (final s in mySightings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded,
                                size: 18, color: BcColors.cherry),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${s.place} · ${timeAgo(s.seenAt)}',
                                  style: text.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                  ],

                  if (friendsSeen.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Flock check', style: text.headlineSmall),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final u in friendsSeen.take(4))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: UserAvatar(user: u, size: 36),
                          ),
                        Expanded(
                          child: Text(
                            seen
                                ? 'You and ${friendsSeen.length} ${friendsSeen.length == 1 ? 'friend' : 'friends'} have seen this bird'
                                : '${friendsSeen.map((u) => u.name.split(' ').first).join(', ')} ${friendsSeen.length == 1 ? 'has' : 'have'} this one — you don’t. Yet.',
                            style: text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: BcColors.canvas,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: BcColors.cherry),
            onPressed: () {
              Haptic.tap();
              showLogSightingSheet(context, preselected: bird);
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(seen ? 'Log another sighting' : 'I spotted this bird'),
          ),
        ),
      ),
    );
  }

  Widget _buildCallCard(Bird bird, AppState app, TextTheme text) {
    final caption = _callCaption(bird, app);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('SONG & CALL', style: text.labelSmall)),
                Semantics(
                  button: true,
                  label: _playing
                      ? 'Stop call for ${bird.name}'
                      : 'Play call for ${bird.name}',
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _playing ? BcColors.cherry : BcColors.ink,
                      foregroundColor: Colors.white,
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_playing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded),
                    onPressed: _loading ? null : _togglePlay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Sonogram(color: bird.tint, playing: _playing),
            const SizedBox(height: 10),
            if (bird.call.isNotEmpty)
              Text('“${bird.call}”',
                  style:
                      text.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
            if (bird.call.isNotEmpty) const SizedBox(height: 4),
            Text(caption, style: text.bodySmall),
          ],
        ),
      ),
    );
  }

  String _callCaption(Bird bird, AppState app) {
    if (_recording != null) {
      final r = _recording!;
      final type = r.type.isEmpty ? 'recording' : r.type;
      return 'Now playing: $type · ${r.attribution}';
    }
    if (_noRecording) return 'No xeno-canto recording found for this species yet.';
    if (app.audio.enabled) return 'Tap play to stream a real recording (xeno-canto).';
    return 'Add a xeno-canto key to hear real recordings.';
  }

  Widget _factPill(IconData icon, String label) {
    return ConstrainedBox(
      // Never let a single long pill run past the screen edge.
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: BcColors.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: BcColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: BcColors.inkSoft),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom view of a bird photo. Shares the Hero tag with
/// the detail header so it zooms open and back smoothly. Tap anywhere to close.
class _BirdPhotoViewer extends StatelessWidget {
  const _BirdPhotoViewer({required this.bird});

  final Bird bird;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Hero(
                  tag: 'bird-image-${bird.id}',
                  child:
                      BirdImage(bird: bird, borderRadius: BorderRadius.zero),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () {
                      Haptic.tick();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
