import 'package:flutter/material.dart';

import '../theme/revolut_theme.dart';

/// Same artwork as the home-screen icon: `assets/branding/app_icon.png`.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 96,
    this.ringProgress = 1,
    this.glow = 0,
  });

  static const assetPath = 'assets/branding/app_icon.png';

  final double size;
  /// Reveal progress from 0 to 1. Keeps the opening-screen parameter name.
  final double ringProgress;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final t = ringProgress.clamp(0.0, 1.0);
    final markScale = 0.86 + 0.14 * Curves.easeOutBack.transform(t);
    final radius = size * 0.22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow > 0)
            Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    RevolutColors.brandSolid.withValues(alpha: 0.35 * glow),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          Opacity(
            opacity: Curves.easeOut.transform(t),
            child: Transform.scale(
              scale: markScale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.asset(
                  assetPath,
                  width: size * 0.88,
                  height: size * 0.88,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
