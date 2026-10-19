part of 'loan_screens.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  int _bestIndex(List<double> values, {required bool lowerBetter}) {
    if (values.isEmpty) return -1;
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (lowerBetter ? values[i] < values[best] : values[i] > values[best]) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ids = app.compareIds;
    final results = <(String, CalcResult)>[];
    for (final id in ids) {
      final r = app.resultForCompareId(id);
      if (r != null) results.add((id, r));
    }

    final monthlyValues = results
        .map(
          (e) => e.$2.input.mode == RepaymentMode.equalPrincipal
              ? e.$2.firstMonthPayment
              : e.$2.monthlyPayment,
        )
        .toList();
    final interestVals = results.map((e) => e.$2.totalInterest).toList();
    final totalVals = results.map((e) => e.$2.totalPayment).toList();

    final winInterest = _bestIndex(interestVals, lowerBetter: true);
    final winMonthly = _bestIndex(monthlyValues, lowerBetter: true);
    String rateText(double rate) {
      final text = rate.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
      return '$text%';
    }

    String rawPlanName(CalcResult result) {
      final cat = categoryLabel(result.input.category, app.locale);
      final rate = rateText(result.input.annualRatePercent);
      return '$cat $rate';
    }

    final planNames = <String>[
      for (var i = 0; i < results.length; i++) rawPlanName(results[i].$2),
    ];

    Widget? richCompare;
    if (results.length >= 2) {
      int maxIndex(List<double> values) {
        var best = 0;
        for (var i = 1; i < values.length; i++) {
          if (values[i] > values[best]) best = i;
        }
        return best;
      }

      final lowInterest = winInterest < 0 ? 0 : winInterest;
      final highInterest = maxIndex(interestVals);
      final lowMonthly = winMonthly < 0 ? 0 : winMonthly;
      final interestGap = (interestVals[highInterest] - interestVals[lowInterest]).abs();
      String detailName(int i) {
        final result = results[i].$2;
        return '${planNames[i]} · ${app.tr('compare.termMonths', {'n': '${result.input.termMonths}'})}';
      }

      final summary = results.length == 2
          ? (lowInterest == lowMonthly
              ? app.tr('compare.summaryTwoSame', {
                  'low': detailName(lowInterest),
                  'high': detailName(lowInterest == 0 ? 1 : 0),
                  'lowInterestAmt': app.money(interestVals[lowInterest]),
                  'interestDiff': app.money(interestGap),
                  'monthlyAmt': app.money(monthlyValues[lowMonthly]),
                })
              : app.tr('compare.summaryTwo', {
                  'low': detailName(lowInterest),
                  'high': detailName(lowInterest == 0 ? 1 : 0),
                  'lowInterestAmt': app.money(interestVals[lowInterest]),
                  'interestDiff': app.money(interestGap),
                  'monthly': detailName(lowMonthly),
                  'monthlyAmt': app.money(monthlyValues[lowMonthly]),
                }))
          : lowInterest == lowMonthly
              ? app.tr('compare.summaryManySame', {
                  'n': '${results.length}',
                  'low': detailName(lowInterest),
                  'high': detailName(highInterest),
                  'lowInterestAmt': app.money(interestVals[lowInterest]),
                  'interestDiff': app.money(interestGap),
                  'monthlyAmt': app.money(monthlyValues[lowMonthly]),
                })
              : app.tr('compare.summaryMany', {
                  'n': '${results.length}',
                  'low': detailName(lowInterest),
                  'high': detailName(highInterest),
                  'lowInterestAmt': app.money(interestVals[lowInterest]),
                  'interestDiff': app.money(interestGap),
                  'monthly': detailName(lowMonthly),
                  'monthlyAmt': app.money(monthlyValues[lowMonthly]),
                });
      final showDown = results.any((e) => e.$2.input.downPayment != null);

      String cellMoney(double v) => app.money(v);
      String cellPct(double v) => '${v.toStringAsFixed(1)}%';

      List<double> metricVals(String key) => switch (key) {
            'monthly' => monthlyValues,
            'first' => results.map((e) => e.$2.firstMonthPayment).toList(),
            'last' => results.map((e) => e.$2.lastMonthPayment).toList(),
            'interest' => interestVals,
            'total' => totalVals,
            'share' => results
                .map(
                  (e) => e.$2.totalPayment > 0
                      ? (e.$2.totalInterest / e.$2.totalPayment) * 100
                      : 0.0,
                )
                .toList(),
            'daily' => results.map((e) {
                final days = (e.$2.input.termMonths * 30).clamp(1, 1000000);
                return e.$2.totalInterest / days;
              }).toList(),
            _ => <double>[],
          };

      final moneyMetricKeys = ['monthly', 'first', 'last', 'interest', 'total', 'share', 'daily'];
      final metricLabels = {
        'monthly': app.tr('compare.monthly'),
        'first': app.tr('compare.firstMonth'),
        'last': app.tr('compare.lastMonth'),
        'interest': app.tr('result.totalInterest'),
        'total': app.tr('result.totalPayment'),
        'share': app.tr('compare.interestShare'),
        'daily': app.tr('compare.dailyInterest'),
      };

      const labelW = 80.0;
      const valueW = 118.0;
      final valueStyle = monoStyle(context, size: 12);
      const plainStyle = TextStyle(fontSize: 12, height: 1.35, color: RevolutColors.text);

      Widget cell({
        required Widget child,
        required double width,
        bool head = false,
        bool best = false,
      }) {
        return Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          color: best
              ? RevolutColors.income.withValues(alpha: 0.08)
              : (head ? RevolutColors.surface2 : RevolutColors.surface1),
          alignment: Alignment.centerLeft,
          child: child,
        );
      }

      Widget textCell(String text, double width, {bool head = false, bool best = false, bool mono = false}) {
        return cell(
          width: width,
          head: head,
          best: best,
          child: Text(
            text,
            style: (mono ? valueStyle : plainStyle).copyWith(
              fontWeight: head || best ? FontWeight.w700 : FontWeight.w500,
              color: best ? RevolutColors.income : (head ? RevolutColors.text : RevolutColors.text),
            ),
          ),
        );
      }

      List<Widget> labelAndValues(String label, List<String> values, {List<bool>? best}) {
        return [
          textCell(label, labelW),
          for (var i = 0; i < values.length; i++)
            textCell(values[i], valueW, best: best != null && best[i], mono: true),
        ];
      }

      final rows = <List<Widget>>[
        [
          textCell(app.tr('compare.metric'), labelW, head: true),
          for (var i = 0; i < results.length; i++)
            cell(
              width: valueW,
              head: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planNames[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  GestureDetector(
                    onTap: () => app.removeFromCompare(results[i].$1),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        app.tr('compare.remove'),
                        style: const TextStyle(fontSize: 11, color: RevolutColors.textMuted, height: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        labelAndValues(
          app.tr('compare.category'),
          results.map((e) => categoryLabel(e.$2.input.category, app.locale)).toList(),
        ),
        labelAndValues(
          app.tr('compare.mode'),
          results.map((e) => modeLabel(e.$2.input.mode, app.locale)).toList(),
        ),
        labelAndValues(
          app.tr('compare.principal'),
          results.map((e) => app.money(e.$2.input.principal)).toList(),
        ),
        if (showDown)
          labelAndValues(
            app.tr('compare.downPayment'),
            results
                .map((e) => e.$2.input.downPayment != null ? app.money(e.$2.input.downPayment!) : '—')
                .toList(),
          ),
        labelAndValues(
          app.tr('compare.rate'),
          results.map((e) => '${e.$2.input.annualRatePercent}%').toList(),
        ),
        labelAndValues(
          app.tr('compare.term'),
          results.map((e) => app.tr('compare.termMonths', {'n': '${e.$2.input.termMonths}'})).toList(),
        ),
        for (final key in moneyMetricKeys)
          () {
            final vals = metricVals(key);
            final bi = _bestIndex(vals, lowerBetter: true);
            final pct = key == 'share';
            return labelAndValues(
              metricLabels[key]!,
              vals.map((v) => pct ? cellPct(v) : cellMoney(v)).toList(),
              best: [for (var i = 0; i < vals.length; i++) i == bi],
            );
          }(),
      ];

      richCompare = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoanLabel(app.tr('compare.summaryTitle')),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                    color: RevolutColors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LoanCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: RevolutColors.divider,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var r = 0; r < rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: 1),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var c = 0; c < rows[r].length; c++) ...[
                              if (c > 0) const SizedBox(width: 1),
                              rows[r][c],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CompareBarChart(
            title: app.tr('compare.chartBar'),
            groupLabels: [
              app.tr('compare.monthly'),
              app.tr('result.totalInterest'),
              app.tr('result.totalPayment'),
            ],
            series: [
              for (var i = 0; i < results.length; i++)
                CompareBarSeries(
                  label: planNames[i],
                  color: comparePlanColors[i % comparePlanColors.length],
                  monthly: monthlyValues[i],
                  interest: interestVals[i],
                  total: totalVals[i],
                ),
            ],
          ),
          if (_CompareExtras.list(app).isNotEmpty) ...[
            const SizedBox(height: 12),
            _CompareExtras(app: app),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('compare.title'),
        ),
        if (results.length < 2)
          LoanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoanMuted(app.tr('compare.needTwo'), fontSize: 13),
                const SizedBox(height: 12),
                LoanPrimaryButton(
                  label: app.tr('compare.goSaved'),
                  onPressed: () => app.push(AppRoute.savedList),
                ),
              ],
            ),
          )
        else
          richCompare!,
        if (results.length < 2) _CompareExtras(app: app),
      ],
    );
  }
}

class _CompareExtras extends StatelessWidget {
  const _CompareExtras({required this.app});

  final AppState app;

  static List<SavedCalculation> list(AppState app) {
    if (app.compareIds.length >= 3) return const <SavedCalculation>[];
    return app.calculations.where((c) => !app.compareIds.contains(c.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final extras = list(app);
    if (extras.isEmpty) return const SizedBox.shrink();
    return LoanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanLabel(app.tr('compare.addSaved')),
          for (var i = 0; i < extras.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: RevolutColors.divider),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _savedTitle(extras[i].note, extras[i].result, app),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      LoanMuted(
                        app.tr('compare.perMonth', {
                          'amount': app.money(
                            extras[i].result.input.mode == RepaymentMode.equalPrincipal
                                ? extras[i].result.firstMonthPayment
                                : extras[i].result.monthlyPayment,
                          ),
                        }),
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
                LoanQuickChip(
                  label: app.tr('compare.addOne'),
                  onTap: () => app.addToCompare(extras[i].id, openCompare: false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
