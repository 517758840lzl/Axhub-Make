import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/currencies.dart';
import '../state/app_state.dart';
import '../theme/revolut_theme.dart';
import 'loan_widgets.dart';

class CurrencyPicker extends StatelessWidget {
  const CurrencyPicker({super.key, required this.currencyCode, required this.onChange, this.compact = false});

  final String currencyCode;
  final ValueChanged<String> onChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final active = getCurrency(currencyCode);
    final activeName = app.tr('currency.${active.code}');
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
                LoanLabel(app.tr('currency.label')),
                LoanChip(app.tr('currency.current', {'symbol': active.symbol, 'name': activeName})),
              ],
            ),
          if (!compact) const SizedBox(height: 16),
          _CurrencyGrid(
            columns: compact ? 6 : 4,
            spacing: compact ? 6 : 8,
            options: currencyOptions,
            selectedCode: currencyCode,
            compact: compact,
            labelFor: (code) => app.tr('currency.$code'),
            onChange: onChange,
          ),
        ],
      ),
    );
  }
}

class _CurrencyGrid extends StatelessWidget {
  const _CurrencyGrid({
    required this.columns,
    required this.spacing,
    required this.options,
    required this.selectedCode,
    required this.compact,
    required this.labelFor,
    required this.onChange,
  });

  final int columns;
  final double spacing;
  final List<CurrencyOption> options;
  final String selectedCode;
  final bool compact;
  final String Function(String code) labelFor;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += columns) {
      final end = i + columns > options.length ? options.length : i + columns;
      final slice = options.sublist(i, end);
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(
                child: j < slice.length
                    ? _CurrencyTile(
                        option: slice[j],
                        selected: slice[j].code == selectedCode,
                        compact: compact,
                        label: labelFor(slice[j].code),
                        onTap: () => onChange(slice[j].code),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.option,
    required this.selected,
    required this.compact,
    required this.label,
    required this.onTap,
  });

  final CurrencyOption option;
  final bool selected;
  final bool compact;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? RevolutColors.brandStart.withValues(alpha: 0.12) : RevolutColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : RevolutColors.divider),
          boxShadow: selected
              ? [BoxShadow(color: RevolutColors.brandStart.withValues(alpha: 0.28), blurRadius: 0, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.symbol, style: const TextStyle(fontSize: 18, height: 1.1, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(option.code, style: const TextStyle(fontSize: 10, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            if (!compact) ...[
              const SizedBox(height: 1),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, height: 1.2, color: RevolutColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
