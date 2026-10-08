import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/revolut_theme.dart';

/// 与 App Icon 同语义的矢量 Logo（启动动画用，任意分辨率清晰）
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 96,
    this.ringProgress = 1,
    this.glow = 0,
  });

  final double size;
  /// 0～1 环形成长动画
  final double ringProgress;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandLogoPainter(ringProgress: ringProgress, glow: glow),
      ),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  _BrandLogoPainter({required this.ringProgress, required this.glow});

  final double ringProgress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    if (glow > 0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            RevolutColors.brandSolid.withValues(alpha: 0.35 * glow),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.8));
      canvas.drawCircle(center, r * 1.6, glowPaint);
    }

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * 0.88, height: size.height * 0.88),
      Radius.circular(size.width * 0.22),
    );
    final bgPaint = Paint()
      ..shader = RevolutColors.gradient.createShader(bgRect.outerRect);
    canvas.drawRRect(bgRect, bgPaint);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * 0.72 * ringProgress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final gridOrigin = Offset(center.dx - r * 0.35, center.dy + r * 0.05);
    const cols = 3;
    const rows = 2;
    final gap = size.width * 0.07;
    final dotR = size.width * 0.035;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final o = Offset(gridOrigin.dx + col * gap, gridOrigin.dy + row * gap);
        canvas.drawCircle(o, dotR, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrandLogoPainter old) =>
      old.ringProgress != ringProgress || old.glow != glow;
}
