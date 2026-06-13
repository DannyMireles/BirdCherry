import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';

/// Your collection as a little woodland: the birds you've logged perch among
/// painted trees, flutter gently on their own, and can be dragged anywhere.
/// Tap one to open it. Rarer birds perch a touch larger.
class AviaryView extends StatefulWidget {
  const AviaryView({super.key});

  @override
  State<AviaryView> createState() => _AviaryViewState();
}

class _AviaryViewState extends State<AviaryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  // User-set base positions (px), per bird id. Drift is added on top.
  final Map<String, Offset> _base = {};
  Size _lastSize = Size.zero;
  String? _dragging;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _sizeFor(Rarity r) => switch (r) {
        Rarity.common => 56,
        Rarity.uncommon => 62,
        Rarity.rare => 70,
        Rarity.legendary => 80,
      };

  /// Lay birds out on a golden-angle spiral the first time, or when the area
  /// resizes. Keeps existing dragged positions when only the list grows.
  void _ensureLayout(List<Bird> birds, Size size) {
    final resized = (size.width - _lastSize.width).abs() > 1 ||
        (size.height - _lastSize.height).abs() > 1;
    if (resized) _base.clear();
    _lastSize = size;

    const golden = 2.399963229728653;
    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final maxR = math.min(size.width, size.height * 0.92) * 0.40;
    for (var i = 0; i < birds.length; i++) {
      _base.putIfAbsent(birds[i].id, () {
        final radius = math.sqrt((i + 0.5) / birds.length) * maxR;
        final angle = i * golden;
        return Offset(cx + math.cos(angle) * radius,
            cy + math.sin(angle) * radius * 0.86);
      });
    }
  }

  Offset _displayPos(Bird bird, int i, Size size) {
    final base = _base[bird.id]!;
    if (_dragging == bird.id) return base;
    // Gentle continuous drift (seamless loop via integer cycle counts).
    final t = _controller.value;
    final seed = bird.id.codeUnits.fold(0, (a, c) => (a * 31 + c) & 0x7fffffff);
    final rnd = math.Random(seed);
    final sx = 1 + rnd.nextInt(2);
    final sy = 1 + rnd.nextInt(2);
    final phx = rnd.nextDouble();
    final phy = rnd.nextDouble();
    final dx = math.sin(2 * math.pi * (t * sx + phx)) * 10;
    final dy = math.sin(2 * math.pi * (t * sy + phy)) * 9;
    return base + Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final collected = app.lifeListOf(app.me.id).map(app.birdById).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    if (collected.isEmpty) return const _EmptyAviary();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${collected.length} collected · drag them around, tap to open',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Icon(Icons.pan_tool_alt_outlined,
                  size: 16, color: BcColors.muted),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                _ensureLayout(collected, size);
                return Semantics(
                  container: true,
                  label: 'Your aviary, a woodland with '
                      '${collected.length} collected birds',
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _ForestPainter()),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Stack(
                            children: [
                              for (var i = 0; i < collected.length; i++)
                                _buildBird(collected[i], i, size),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBird(Bird bird, int i, Size size) {
    final avatar = _sizeFor(bird.rarity);
    final pos = _displayPos(bird, i, size);
    final isDragging = _dragging == bird.id;

    // Subtle breathing + tilt unless being dragged.
    final t = _controller.value;
    final phase = (bird.id.hashCode & 0xff) / 255.0;
    final bob = isDragging ? 1.06 : 1 + 0.04 * math.sin(2 * math.pi * (t * 2 + phase));
    final tilt = isDragging ? 0.0 : 0.05 * math.sin(2 * math.pi * (t * 2 + phase));

    final left = (pos.dx - avatar / 2).clamp(2.0, size.width - avatar - 2);
    final top = (pos.dy - avatar / 2).clamp(2.0, size.height - avatar - 2);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: bird)));
        },
        onPanStart: (_) {
          Haptic.tick();
          // Bake current drifted position into base so there's no jump.
          setState(() {
            _base[bird.id] = _displayPos(bird, i, size);
            _dragging = bird.id;
          });
        },
        onPanUpdate: (d) {
          setState(() {
            final next = _base[bird.id]! + d.delta;
            _base[bird.id] = Offset(
              next.dx.clamp(avatar / 2, size.width - avatar / 2),
              next.dy.clamp(avatar / 2, size.height - avatar / 2),
            );
          });
        },
        onPanEnd: (_) => setState(() => _dragging = null),
        child: Transform.rotate(
          angle: tilt,
          child: Transform.scale(
            scale: bob,
            child: _AviaryAvatar(
                bird: bird, size: avatar, elevated: isDragging),
          ),
        ),
      ),
    );
  }
}

class _AviaryAvatar extends StatelessWidget {
  const _AviaryAvatar({
    required this.bird,
    required this.size,
    this.elevated = false,
  });

  final Bird bird;
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${bird.name}, ${bird.rarity.label}. Drag to move, tap to open.',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: BcColors.ink.withValues(alpha: elevated ? 0.32 : 0.18),
              blurRadius: elevated ? 20 : 11,
              offset: Offset(0, elevated ? 10 : 5),
            ),
          ],
        ),
        child: ClipOval(
          child: Hero(
            tag: 'bird-image-${bird.id}',
            child: BirdImage(bird: bird, borderRadius: BorderRadius.zero),
          ),
        ),
      ),
    );
  }
}

/// Flat, on-brand woodland: soft sky, a low sun, layered hills, and a few
/// stylised trees for depth. Intentionally simple so it never competes with
/// the bird photos.
class _ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Sky wash.
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3EFE6), Color(0xFFE7EEE2)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // Low sun.
    canvas.drawCircle(
        Offset(w * 0.80, h * 0.16), 34, Paint()..color = const Color(0x22C7842C));
    canvas.drawCircle(
        Offset(w * 0.80, h * 0.16), 20, Paint()..color = const Color(0x33D9A24A));

    // Distant tree line + hills.
    final hillFar = Paint()..color = const Color(0xFFD8E3D2);
    final hillNear = Paint()..color = const Color(0xFFC3D6BC);

    final far = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.25, h * 0.64, w * 0.5, h * 0.71)
      ..quadraticBezierTo(w * 0.78, h * 0.78, w, h * 0.69)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, hillFar);

    final near = Path()
      ..moveTo(0, h * 0.83)
      ..quadraticBezierTo(w * 0.3, h * 0.77, w * 0.55, h * 0.84)
      ..quadraticBezierTo(w * 0.82, h * 0.9, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, hillNear);

    // A few simple trees.
    _tree(canvas, Offset(w * 0.12, h * 0.74), 30, const Color(0xFFA9C6A0));
    _tree(canvas, Offset(w * 0.88, h * 0.80), 26, const Color(0xFF9BBE93));
    _tree(canvas, Offset(w * 0.62, h * 0.70), 22, const Color(0xFFB6CEAE));
  }

  void _tree(Canvas canvas, Offset base, double r, Color foliage) {
    final trunk = Paint()..color = const Color(0xFFB39B7D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: base.translate(0, r * 0.7), width: r * 0.22, height: r * 1.1),
        const Radius.circular(3),
      ),
      trunk,
    );
    final leaf = Paint()..color = foliage;
    canvas.drawCircle(base, r, leaf);
    canvas.drawCircle(base.translate(-r * 0.6, r * 0.2), r * 0.66, leaf);
    canvas.drawCircle(base.translate(r * 0.6, r * 0.2), r * 0.66, leaf);
    canvas.drawCircle(base.translate(0, -r * 0.5), r * 0.6, leaf);
  }

  @override
  bool shouldRepaint(_ForestPainter oldDelegate) => false;
}

class _EmptyAviary extends StatelessWidget {
  const _EmptyAviary();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: BcColors.leafSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.forest_rounded,
                  size: 42, color: BcColors.leaf),
            ),
            const SizedBox(height: 18),
            Text('Your woodland is quiet', style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Log a bird with the ＋ button and it’ll come live here, fluttering through the trees.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
