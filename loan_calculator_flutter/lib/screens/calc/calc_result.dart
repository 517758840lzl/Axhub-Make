import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../data/calc.dart';
import '../../data/input_utils.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';
import '../../widgets/donut_chart.dart';
import '../../widgets/loan_widgets.dart';
import '../screen_shared.dart';

String _interestShare(CalcResult result) {
  if (result.totalPayment <= 0) return '0';
  return (result.totalInterest / result.totalPayment * 100).toStringAsFixed(0);
}

String _whole(double n) => formatGroupedAmount(n.toStringAsFixed(0));

String _yearsText(int months) {
  final years = months / 12;
  return months % 12 == 0 ? years.toStringAsFixed(0) : years.toStringAsFixed(1);
}

List<String> _resultInsightLines(CalcResult result, AppState app) {
  final input = result.input;
  if (input.category == LoanCategory.dual && (result.partsResults?.length ?? 0) == 2) {
    final parts = input.parts;
    final a = parts != null && parts.isNotEmpty ? '${parts[0].annualRatePercent}' : '-';
    final b = parts != null && parts.length > 1 ? '${parts[1].annualRatePercent}' : '-';
    return [
      app.tr('dual.insight', {
        'monthly': _whole(result.monthlyPayment),
        'interest': _whole(result.totalInterest),
        'total': _whole(result.totalPayment),
      }),
      app.tr('result.insight.3', {
        'principal': _whole(input.principal),
        'rate': '$a / $b',
      }),
    ];
  }

  final lines = <String>[
    app.tr('result.insight.1', {
      'mode': modeLabel(input.mode, app.locale),
      'years': _yearsText(input.termMonths),
      'share': _interestShare(result),
    }),
    app.tr('result.insight.2', {
      'monthly': _whole(result.monthlyPayment),
      'interest': _whole(result.totalInterest),
    }),
  ];
  final vehicle = input.vehiclePrice;
  final down = input.downPayment;
  if (input.category == LoanCategory.auto && vehicle != null && down != null) {
    final pct = vehicle > 0 ? down / vehicle * 100 : 0;
    lines.insert(
      0,
      app.tr('result.insight.auto', {
        'vehicle': _whole(vehicle),
        'pct': pct.toStringAsFixed(0),
        'down': _whole(down),
        'principal': _whole(input.principal),
      }),
    );
  } else {
    lines.add(app.tr('result.insight.3', {
      'principal': _whole(input.principal),
      'rate': '${input.annualRatePercent}',
    }));
  }
  return lines.take(3).toList();
}

class CalcResultScreen extends StatelessWidget {
  const CalcResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final result = app.pendingResult;
    if (result == null) return const RedirectCalcScreen();

    final isDual = result.input.category == LoanCategory.dual;
    final isEqPrincipal = result.input.mode == RepaymentMode.equalPrincipal;
    final hero = isDual
        ? app.money(result.firstMonthPayment)
        : isEqPrincipal
            ? '${app.money(result.firstMonthPayment)} → ${app.money(result.lastMonthPayment)}'
            : app.money(result.monthlyPayment);
    final showSave = !app.isDuplicateSave(result);
    final insights = _resultInsightLines(result, app);
    final rawParts = result.partsResults;
    final List<CalcResult>? dualParts =
        isDual && rawParts != null && rawParts.length >= 2 ? rawParts : null;
    final partShare = dualParts != null && result.firstMonthPayment > 0
        ? ((dualParts[0].firstMonthPayment / result.firstMonthPayment) * 100).toStringAsFixed(0)
        : _interestShare(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('result.title'),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanMuted(
                isDual
                    ? categoryLabel(result.input.category, app.locale)
                    : '${categoryLabel(result.input.category, app.locale)} · ${modeLabel(result.input.mode, app.locale)}',
                fontSize: 13,
              ),
              const SizedBox(height: 12),
              LoanLabel(
                isDual
                    ? app.tr('dual.combinedMonthly')
                    : isEqPrincipal
                        ? app.tr('result.firstLast')
                        : app.tr('result.monthly'),
              ),
              LoanHeroAmount(hero),
              DonutChart(
                segments: dualParts != null
                    ? [
                        DonutSegment(
                          value: dualParts[0].firstMonthPayment,
                          color: RevolutColors.brandStart,
                          label: app.tr('dual.partA'),
                          amountText: app.money(dualParts[0].firstMonthPayment),
                        ),
                        DonutSegment(
                          value: dualParts[1].firstMonthPayment,
                          color: RevolutColors.brandEnd,
                          label: app.tr('dual.partB'),
                          amountText: app.money(dualParts[1].firstMonthPayment),
                        ),
                      ]
                    : [
                        DonutSegment(
                          value: result.input.principal,
                          color: RevolutColors.brandStart,
                          label: app.tr('result.principal'),
                          amountText: app.money(result.input.principal),
                        ),
                        DonutSegment(
                          value: result.totalInterest,
                          color: RevolutColors.brandEnd,
                          label: app.tr('result.interest'),
                          amountText: app.money(result.totalInterest),
                        ),
                      ],
                centerLabel: dualParts != null ? '$partShare%' : '${_interestShare(result)}%',
                centerSub: dualParts != null ? app.tr('dual.partA') : app.tr('result.interestShare'),
              ),
              LoanRow(label: app.tr('result.totalPayment'), value: app.money(result.totalPayment)),
              LoanRow(
                label: app.tr('result.totalInterest'),
                value: app.money(result.totalInterest),
                valueColor: RevolutColors.spend,
              ),
              if (dualParts != null) ...[
                LoanLabel(app.tr('dual.partBreakdown'), marginTop: 8),
                for (var i = 0; i < dualParts.length; i++)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                    decoration: BoxDecoration(
                      color: RevolutColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i == 0 ? app.tr('dual.partA') : app.tr('dual.partB'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        LoanRow(
                          label: app.tr('home.principal'),
                          value: app.money(dualParts[i].input.principal),
                        ),
                        LoanRow(
                          label: app.tr('home.rate'),
                          value: '${dualParts[i].input.annualRatePercent}%',
                        ),
                        LoanRow(
                          label: app.tr('result.monthly'),
                          value: app.money(dualParts[i].firstMonthPayment),
                        ),
                        LoanRow(
                          label: app.tr('result.totalInterest'),
                          value: app.money(dualParts[i].totalInterest),
                          valueColor: RevolutColors.spend,
                          divider: false,
                        ),
                      ],
                    ),
                  ),
              ] else
                LoanRow(label: app.tr('result.loanPrincipal'), value: app.money(result.input.principal)),
              if (result.input.vehiclePrice != null)
                LoanRow(label: app.tr('result.vehicle'), value: app.money(result.input.vehiclePrice!)),
              if (result.input.downPayment != null)
                LoanRow(label: app.tr('result.downPayment'), value: app.money(result.input.downPayment!)),
            ],
          ),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanSectionHead(icon: LucideIcons.sparkles, title: app.tr('result.insights')),
              for (var i = 0; i < insights.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == insights.length - 1 ? 0 : 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•  ',
                        style: TextStyle(fontSize: 13, height: 1.55, color: RevolutColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          insights[i],
                          style: const TextStyle(fontSize: 13, height: 1.55, color: RevolutColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        LoanPrimaryButton(label: app.tr('result.amort'), onPressed: () => app.push(AppRoute.amortization)),
        const SizedBox(height: 8),
        LoanSecondaryButton(
          label: app.tr('result.compare'),
          onPressed: () {
            app.addPendingToCompare();
          },
        ),
        if (showSave) ...[
          const SizedBox(height: 8),
          LoanSecondaryButton(
            label: app.tr('result.save'),
            onPressed: () async {
              if (app.pendingResult != null) await app.saveCalc(app.pendingResult!);
            },
          ),
        ],
        const SizedBox(height: 8),
        LoanSecondaryButton(
          label: app.tr('result.savings'),
          onPressed: () {
            app.push(AppRoute.savingsNew, prefill: '${(result.monthlyPayment * 3).round()}');
          },
        ),
      ],
    );
  }
}
