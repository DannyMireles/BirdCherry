import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// The BirdCherry mark — a cherry-red cherry-bird. Vector, so it's crisp at
/// any size. Single source of truth shared with the app icon.
class BcLogo extends StatelessWidget {
  const BcLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/birdcherry_mark.svg',
      width: size,
      height: size,
      semanticsLabel: 'BirdCherry logo',
    );
  }
}

/// The wordmark: the mark beside the "BirdCherry" name.
class BcWordmark extends StatelessWidget {
  const BcWordmark({super.key, this.markSize = 40, this.fontSize = 22});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BcLogo(size: markSize),
        const SizedBox(width: 10),
        Text(
          'BirdCherry',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: fontSize,
                color: BcColors.ink,
              ),
        ),
      ],
    );
  }
}

/// A simple single-colour bird silhouette, used as the photo-fallback
/// monogram. Authored white so it reads on any tinted background.
class BirdGlyph extends StatelessWidget {
  const BirdGlyph({super.key, this.size, this.color});

  final double? size;

  /// When set, tints the whole glyph (e.g. ink/white for small UI).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/bird_glyph.svg',
      width: size,
      height: size,
      semanticsLabel: 'Bird',
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
