import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/revolut_theme.dart';

class DonutSegment {
  const DonutSegment({required this.value, required this.color, required this.label});
  final double value;
  final Color color;
  final String label;
}

class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.centerLabel,
    this.centerSub,
    this.size = 160,
    this.stroke = 14,
    this.animate = true,
  });

  final List<DonutSegment> segments;
  final String centerLabel;
  final String? centerSub;
  final double size;
  final double stroke;
  final bool animate;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.animate ? 0 : 1,
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    } else if (!widget.animate) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.segments.fold<double>(0, (s, x) => s + x.value);
    final safeTotal = total <= 0 ? 1.0 : total;
    final r = (widget.size - widget.stroke) / 2;
    final c = 2 * math.pi * r;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _DonutPainter(
                      segments: widget.segments,
                      total: safeTotal,
                      stroke: widget.stroke,
                      progress: _progress.value,
                      circumference: c,
                      trackColor: RevolutColors.donutTrack,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.centerLabel,
                        textAlign: TextAlign.center,
                        style: monoStyle(context, size: 22, w: FontWeight.w700),
                      ),
                      if (widget.centerSub != null)
                        Text(
                          widget.centerSub!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, height: 1.3, color: RevolutColors.textSecondary),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          alignment: WrapAlignment.center,
          children: widget.segments.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(s.label, style: const TextStyle(fontSize: 12, color: RevolutColors.textSecondary)),
              ],
            );
          }).toList(),
        ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.total,
    required this.stroke,
    required this.progress,
    required this.circumference,
    required this.trackColor,
  });

  final List<DonutSegment> segments;
  final double total;
  final double stroke;
  final double progress;
  final double circumference;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, r, track);

    var startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.segments != segments;
}
