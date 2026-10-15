import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/revolut_theme.dart';

/// 计算器 + % 品牌标（与 App Icon 同语义；启动动画可任意分辨率清晰）
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 96,
    this.ringProgress = 1,
    this.glow = 0,
  });

  final double size;
  /// 0～1 符号显现进度（兼容启动页原参数名）
  final double ringProgress;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandLogoPainter(markProgress: ringProgress, glow: glow),
      ),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  _BrandLogoPainter({required this.markProgress, required this.glow});

  final double markProgress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = markProgress.clamp(0.0, 1.0);

    if (glow > 0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            RevolutColors.brandSolid.withValues(alpha: 0.35 * glow),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
      canvas.drawCircle(center, size.width * 0.62, glowPaint);
    }

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * 0.88, height: size.height * 0.88),
      Radius.circular(size.width * 0.22),
    );
    final bgPaint = Paint()..shader = RevolutColors.gradient.createShader(bgRect.outerRect);
    canvas.drawRRect(bgRect, bgPaint);

    // 符号区：随进度轻微放大 + 淡入
    final markAlpha = Curves.easeOut.transform(t);
    final markScale = 0.86 + 0.14 * Curves.easeOutBack.transform(t);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(markScale);
    canvas.translate(-center.dx, -center.dy);

    final stroke = size.width * 0.055;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.95 * markAlpha);

    final fill = Paint()..color = Colors.white.withValues(alpha: 0.95 * markAlpha);

    // 计算器外框（略偏左，给右侧 % 留位）
    final calcW = size.width * 0.42;
    final calcH = size.height * 0.48;
    final calcCenter = Offset(center.dx - size.width * 0.06, center.dy);
    final calcRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: calcCenter, width: calcW, height: calcH),
      Radius.circular(size.width * 0.07),
    );
    canvas.drawRRect(calcRect, paint);

    // 顶部显示条
    final display = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        calcCenter.dx - calcW * 0.32,
        calcCenter.dy - calcH * 0.36,
        calcW * 0.64,
        calcH * 0.14,
      ),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(display, fill);

    // 左侧竖键
    final keyGap = calcH * 0.08;
    final keyLeft = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        calcCenter.dx - calcW * 0.32,
        calcCenter.dy - calcH * 0.08,
        calcW * 0.16,
        calcH * 0.34,
      ),
      Radius.circular(size.width * 0.025),
    );
    canvas.drawRRect(keyLeft, fill);

    // 中间两颗方键
    final keySize = calcW * 0.16;
    final midX = calcCenter.dx - calcW * 0.06;
    final midY1 = calcCenter.dy - calcH * 0.08;
    final midY2 = midY1 + keySize + keyGap * 0.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(midX, midY1, keySize, keySize), Radius.circular(size.width * 0.025)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(midX, midY2, keySize, keySize), Radius.circular(size.width * 0.025)),
      fill,
    );

    // 右侧 %（略倾斜）
    final pctCenter = Offset(center.dx + size.width * 0.16, center.dy + size.height * 0.02);
    canvas.save();
    canvas.translate(pctCenter.dx, pctCenter.dy);
    canvas.rotate(math.pi / 7);
    canvas.translate(-pctCenter.dx, -pctCenter.dy);

    final slashLen = size.width * 0.22;
    final slashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.05
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.95 * markAlpha);
    canvas.drawLine(
      Offset(pctCenter.dx + slashLen * 0.28, pctCenter.dy - slashLen * 0.42),
      Offset(pctCenter.dx - slashLen * 0.28, pctCenter.dy + slashLen * 0.42),
      slashPaint,
    );

    final dotR = size.width * 0.038;
    canvas.drawCircle(
      Offset(pctCenter.dx - slashLen * 0.12, pctCenter.dy - slashLen * 0.28),
      dotR,
      fill,
    );
    canvas.drawCircle(
      Offset(pctCenter.dx + slashLen * 0.12, pctCenter.dy + slashLen * 0.28),
      dotR,
      fill,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandLogoPainter old) =>
      old.markProgress != markProgress || old.glow != glow;
}
