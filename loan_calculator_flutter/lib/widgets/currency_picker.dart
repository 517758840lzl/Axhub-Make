import 'package:flutter/material.dart';

import '../data/currencies.dart';
import '../theme/revolut_theme.dart';
import 'loan_widgets.dart';

class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({super.key, required this.currencyCode, required this.onChange, this.compact = false});

  final String currencyCode;
  final ValueChanged<String> onChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = getCurrency(currencyCode);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 14 : 14),
      decoration: BoxDecoration(
        color: RevolutColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevolutColors.divider),
        boxShadow: [RevolutColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LoanLabel('显示货币'),
                LoanChip('当前 ${active.symbol} ${active.name}'),
              ],
            ),
          GridView.count(
            crossAxisCount: compact ? 6 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: compact ? 6 : 8,
            crossAxisSpacing: compact ? 6 : 8,
            childAspectRatio: compact ? 0.85 : 0.75,
            children: currencyOptions.map((c) {
              final selected = c.code == currencyCode;
              return GestureDetector(
                onTap: () => onChange(c.code),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: selected ? RevolutColors.brandStart.withValues(alpha: 0.12) : RevolutColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? Colors.transparent : RevolutColors.divider),
                    boxShadow: selected
                        ? [BoxShadow(color: RevolutColors.brandStart.withValues(alpha: 0.28), blurRadius: 0, spreadRadius: 1)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(c.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      if (!compact)
                        Text(c.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, height: 1.2, color: RevolutColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
