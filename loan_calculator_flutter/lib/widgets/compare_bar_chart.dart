import 'package:flutter/material.dart';

import '../theme/revolut_theme.dart';

const comparePlanColors = <Color>[
  RevolutColors.brandSolid,
  RevolutColors.income,
  RevolutColors.spend,
];

class CompareBarSeries {
  const CompareBarSeries({
    required this.label,
    required this.color,
    required this.monthly,
    required this.interest,
    required this.total,
  });

  final String label;
  final Color color;
  final double monthly;
  final double interest;
  final double total;
}

/// Grouped bars for monthly payment, total interest, and total cost. Matches the web compare page.
class CompareBarChart extends StatelessWidget {
  const CompareBarChart({
    super.key,
    required this.title,
    required this.groupLabels,
    required this.series,
  });

  final String title;
  final List<String> groupLabels;
  final List<CompareBarSeries> series;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: RevolutColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevolutColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RevolutColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 168,
            child: CustomPaint(
              painter: _CompareBarPainter(series: series, groupLabels: groupLabels),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final s in series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: RevolutColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareBarPainter extends CustomPainter {
  _CompareBarPainter({required this.series, required this.groupLabels});

  final List<CompareBarSeries> series;
  final List<String> groupLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || groupLabels.length < 3) return;

    final groups = <List<double>>[
      series.map((s) => s.monthly).toList(),
      series.map((s) => s.interest).toList(),
      series.map((s) => s.total).toList(),
    ];
    var maxV = 1.0;
    for (final g in groups) {
      for (final v in g) {
        if (v > maxV) maxV = v;
      }
    }

    const top = 8.0;
    const bottom = 28.0;
    const left = 4.0;
    const right = 4.0;
    final innerW = size.width - left - right;
    final innerH = size.height - top - bottom;
    final groupW = innerW / groups.length;
    const gap = 3.0;
    final slot = (groupW - 16) / series.length;

    for (var gi = 0; gi < groups.length; gi++) {
      final gx = left + gi * groupW + 8;
      final values = groups[gi];
      for (var pi = 0; pi < values.length; pi++) {
        final v = values[pi];
        final h = (v / maxV) * innerH;
        final x = gx + pi * slot;
        final y = top + innerH - h;
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, (slot - gap).clamp(6, 40), h.clamp(2, innerH)),
          const Radius.circular(4),
        );
        canvas.drawRRect(r, Paint()..color = series[pi].color);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: groupLabels[gi],
          style: const TextStyle(fontSize: 10, color: RevolutColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: groupW);
      tp.paint(canvas, Offset(gx + (groupW - 16 - tp.width) / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _CompareBarPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.groupLabels != groupLabels;
}
