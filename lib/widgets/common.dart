import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/bird_image_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'logo.dart';

Color rarityColor(Rarity r) => switch (r) {
      Rarity.common => BcColors.common,
      Rarity.uncommon => BcColors.uncommon,
      Rarity.rare => BcColors.rare,
      Rarity.legendary => BcColors.legendary,
    };

/// Pill showing a bird's rarity tier.
class RarityChip extends StatelessWidget {
  const RarityChip({super.key, required this.rarity, this.compact = false});

  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(rarity);
    return Semantics(
      label: '${rarity.label} rarity, worth ${rarity.points} points',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              compact ? rarity.label : '${rarity.label} · ${rarity.points} pts',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bird photo loaded live from open sources (Wikipedia → iNaturalist), with a
/// clean tinted monogram fallback so the design never looks broken offline.
///
/// Walks the service's ordered candidate URLs: when one fails to load it
/// advances to the next, only showing the monogram once all are exhausted.
/// Every image request carries a descriptive User-Agent so Wikimedia doesn't
/// throttle it.
class BirdImage extends StatefulWidget {
  const BirdImage({
    super.key,
    required this.bird,
    this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Bird bird;
  final double? size;
  final BorderRadius borderRadius;

  @override
  State<BirdImage> createState() => _BirdImageState();
}

class _BirdImageState extends State<BirdImage> {
  int _attempt = 0;
  String? _url;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(BirdImage old) {
    super.didUpdateWidget(old);
    if (old.bird.id != widget.bird.id) {
      _attempt = 0;
      _url = null;
      _exhausted = false;
      _resolve();
    }
  }

  /// Find the next candidate URL at or after [_attempt]; monogram if none.
  Future<void> _resolve() async {
    final images = context.read<AppState>().images;
    for (var a = _attempt; a < 3; a++) {
      final url = await images.sourceAt(widget.bird, a);
      if (!mounted) return;
      if (url != null) {
        setState(() {
          _attempt = a;
          _url = url;
        });
        return;
      }
    }
    if (mounted) setState(() => _exhausted = true);
  }

  void _onError() {
    _attempt += 1;
    _url = null;
    _resolve();
  }

  @override
  Widget build(BuildContext context) {
    final bird = widget.bird;
    final url = _url;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: url == null
            ? _Monogram(bird: bird, dim: !_exhausted)
            : Image(
                key: ValueKey(url),
                image: NetworkImage(url,
                    headers: const {'User-Agent': kBirdCherryUserAgent}),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                semanticLabel: 'Photo of ${bird.name}',
                errorBuilder: (_, __, ___) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _onError();
                  });
                  return _Monogram(bird: bird, dim: true);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _Monogram(bird: bird, dim: true);
                },
                frameBuilder: (context, child, frame, syncLoaded) {
                  if (syncLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({required this.bird, this.dim = false});

  final Bird bird;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dim ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bird.tint.withValues(alpha: 0.85),
              bird.tint.withValues(alpha: 0.55),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: const FractionallySizedBox(
          widthFactor: 0.5,
          child: BirdGlyph(),
        ),
      ),
    );
  }
}

/// Circular user avatar with initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 40});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${user.name}’s avatar',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: user.color.withValues(alpha: 0.14),
          border: Border.all(color: user.color.withValues(alpha: 0.5), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          user.initials,
          style: TextStyle(
            color: user.color,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Section heading with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (action != null)
            GestureDetector(
              onTap: () {
                Haptic.tick();
                onAction?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  action!,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: BcColors.cherry),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Animated faux-sonogram used on bird call cards. Purely decorative —
/// hidden from screen readers; the call mnemonic carries the meaning.
class Sonogram extends StatefulWidget {
  const Sonogram({super.key, required this.color, this.playing = false});

  final Color color;
  final bool playing;

  @override
  State<Sonogram> createState() => _SonogramState();
}

class _SonogramState extends State<Sonogram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // Deterministic pseudo-random bar heights so each bird's "song" is stable.
  static const _heights = [
    0.3, 0.7, 0.45, 0.9, 0.6, 0.35, 0.8, 0.5, 1.0, 0.4,
    0.65, 0.85, 0.3, 0.55, 0.75, 0.4, 0.95, 0.6, 0.35, 0.7,
    0.5, 0.85, 0.45, 0.65, 0.3, 0.9, 0.55, 0.75, 0.4, 0.6,
  ];

  @override
  void didUpdateWidget(Sonogram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !oldWidget.playing) {
      _controller.repeat();
    } else if (!widget.playing && oldWidget.playing) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 36,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < _heights.length; i++)
                  _bar(i),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bar(int i) {
    var h = _heights[i];
    if (widget.playing) {
      final phase = (_controller.value * 2 + i / _heights.length) % 1.0;
      final wave = (phase < 0.5 ? phase : 1 - phase) * 2; // triangle wave
      h = (h * (0.45 + 0.55 * wave)).clamp(0.12, 1.0);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 3,
      height: 36 * h,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: widget.playing ? 0.9 : 0.45),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Friendly relative time: "just now", "3h ago", "2d ago".
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
  return '${(d.inDays / 30).floor()}mo ago';
}
