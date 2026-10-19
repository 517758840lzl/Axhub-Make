import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/revolut_theme.dart';

class LoanHeroBanner extends StatelessWidget {
  const LoanHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badges,
    this.marginBottom = 16,
  });

  final String title;
  final String subtitle;
  final List<Widget> badges;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: RevolutColors.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [RevolutColors.ctaShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white.withValues(alpha: 0.92)),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: badges),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class LoanHeroBadge extends StatelessWidget {
  const LoanHeroBadge({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class LoanFeatureRow extends StatelessWidget {
  const LoanFeatureRow({
    super.key,
    required this.ratioLabel,
    required this.amortLabel,
    required this.compareLabel,
    required this.onRatio,
    required this.onAmort,
    required this.onCompare,
  });

  final String ratioLabel;
  final String amortLabel;
  final String compareLabel;
  final VoidCallback onRatio;
  final VoidCallback onAmort;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.pieChart, ratioLabel, onRatio),
      (LucideIcons.tableProperties, amortLabel, onAmort),
      (LucideIcons.columns2, compareLabel, onCompare),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
                child: Material(
                  color: RevolutColors.surface1,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: items[i].$3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RevolutColors.divider),
                        boxShadow: [RevolutColors.softShadow],
                      ),
                      child: Column(
                        children: [
                          Icon(items[i].$1, size: 20, color: RevolutColors.brandSolid),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RevolutColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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

class LoanPreviewCard extends StatelessWidget {
  const LoanPreviewCard({
    super.key,
    required this.previewTitle,
    required this.payment,
    required this.totalInterest,
    required this.totalPayment,
    required this.interestLabel,
    required this.totalLabel,
  });

  final String previewTitle;
  final String payment;
  final String totalInterest;
  final String totalPayment;
  final String interestLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF8F9FE)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevolutColors.divider),
        boxShadow: [RevolutColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 14, color: RevolutColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  previewTitle,
                  style: const TextStyle(fontSize: 12, color: RevolutColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(payment, style: monoStyle(context, size: 28, w: FontWeight.w700).copyWith(color: RevolutColors.brandSolid)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metaBox(interestLabel, totalInterest, context)),
              const SizedBox(width: 8),
              Expanded(child: _metaBox(totalLabel, totalPayment, context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaBox(String label, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: RevolutColors.surface2, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: RevolutColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: monoStyle(context, size: 13)),
        ],
      ),
    );
  }
}
