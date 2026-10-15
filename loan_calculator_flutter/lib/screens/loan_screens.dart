import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/calc.dart';
import '../data/format.dart';
import '../data/i18n.dart';
import '../data/models.dart';
import '../data/savings_insights.dart';
import '../state/app_state.dart';
import '../theme/revolut_theme.dart';
import '../widgets/currency_picker.dart';
import '../widgets/donut_chart.dart';
import '../widgets/loan_widgets.dart';

// --- Calc ---

class CalcHomeScreen extends StatefulWidget {
  const CalcHomeScreen({super.key});

  @override
  State<CalcHomeScreen> createState() => _CalcHomeScreenState();
}

class _CalcHomeScreenState extends State<CalcHomeScreen> {
  RepaymentMode _mode = RepaymentMode.equalPayment;
  LoanCategory _category = LoanCategory.mortgage;
  final _principal = TextEditingController(text: '1000000');
  final _rate = TextEditingController(text: '4.2');
  final _years = TextEditingController(text: '30');
  final _months = TextEditingController(text: '0');
  final _vehicle = TextEditingController(text: '200000');
  final _down = TextEditingController(text: '40000');
  bool _loanManual = false;

  // Dual parts
  final _aPrincipal = TextEditingController(text: '800000');
  final _aRate = TextEditingController(text: '4.2');
  final _aYears = TextEditingController(text: '25');
  final _aMonths = TextEditingController(text: '0');
  RepaymentMode _aMode = RepaymentMode.equalPayment;
  final _bPrincipal = TextEditingController(text: '300000');
  final _bRate = TextEditingController(text: '3.1');
  final _bYears = TextEditingController(text: '20');
  final _bMonths = TextEditingController(text: '0');
  RepaymentMode _bMode = RepaymentMode.equalPayment;

  final _errors = <String, bool>{};

  @override
  void dispose() {
    for (final c in [
      _principal, _rate, _years, _months, _vehicle, _down,
      _aPrincipal, _aRate, _aYears, _aMonths,
      _bPrincipal, _bRate, _bYears, _bMonths,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncAutoLoan() {
    if (_loanManual) return;
    final price = double.tryParse(_vehicle.text) ?? 0;
    final down = double.tryParse(_down.text) ?? 0;
    final loan = (price - down).clamp(0, double.infinity);
    _principal.text = loan == loan.roundToDouble() ? '${loan.round()}' : loan.toStringAsFixed(2);
  }

  int _term(TextEditingController y, TextEditingController m) =>
      (int.tryParse(y.text) ?? 0) * 12 + (int.tryParse(m.text) ?? 0);

  CalcResult? _preview() {
    try {
      return _buildResult();
    } catch (_) {
      return null;
    }
  }

  CalcResult? _buildResult() {
    if (_category == LoanCategory.dual) {
      final ap = double.tryParse(_aPrincipal.text);
      final ar = double.tryParse(_aRate.text);
      final at = _term(_aYears, _aMonths);
      final bp = double.tryParse(_bPrincipal.text);
      final br = double.tryParse(_bRate.text);
      final bt = _term(_bYears, _bMonths);
      if (ap == null || ap <= 0 || ar == null || ar < 0 || at <= 0) return null;
      if (bp == null || bp <= 0 || br == null || br < 0 || bt <= 0) return null;
      return computeLoan(CalcInput(
        principal: ap + bp,
        annualRatePercent: ar,
        termMonths: at > bt ? at : bt,
        mode: _aMode,
        category: LoanCategory.dual,
        parts: [
          DualLoanPart(principal: ap, annualRatePercent: ar, termMonths: at, mode: _aMode),
          DualLoanPart(principal: bp, annualRatePercent: br, termMonths: bt, mode: _bMode),
        ],
      ));
    }

    if (_category == LoanCategory.auto) _syncAutoLoan();
    final p = double.tryParse(_principal.text);
    final r = double.tryParse(_rate.text);
    final termMonths = _term(_years, _months);
    if (p == null || p <= 0 || r == null || r < 0 || termMonths <= 0) return null;

    double? vehicle;
    double? down;
    if (_category == LoanCategory.auto) {
      vehicle = double.tryParse(_vehicle.text);
      down = double.tryParse(_down.text);
    }

    return computeLoan(CalcInput(
      principal: p,
      annualRatePercent: r,
      termMonths: termMonths,
      mode: _mode,
      category: _category,
      vehiclePrice: vehicle,
      downPayment: down,
    ));
  }

  void _submit(AppState app) {
    _errors.clear();
    final result = _buildResult();
    if (result == null) {
      if (_category == LoanCategory.dual) {
        _errors['a'] = true;
        _errors['b'] = true;
      } else {
        _errors['principal'] = true;
        _errors['rate'] = true;
        _errors['term'] = true;
      }
      setState(() {});
      app.showToast(app.tr('home.fillFirst'));
      return;
    }
    setState(() {});
    app.setPendingResult(result);
    app.push(AppRoute.calcResult);
  }

  void _ensureResultThen(AppState app, AppRoute route) {
    final result = app.pendingResult ?? _buildResult();
    if (result == null) {
      app.showToast(app.tr('home.fillFirst'));
      return;
    }
    app.setPendingResult(result, savedId: app.pendingSavedId);
    app.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final preview = _preview();
    final previewPayment = preview == null
        ? null
        : (preview.input.mode == RepaymentMode.equalPrincipal || preview.input.category == LoanCategory.dual
            ? preview.firstMonthPayment
            : preview.monthlyPayment);

    final downPct = () {
      if (_category != LoanCategory.auto) return null;
      final price = double.tryParse(_vehicle.text) ?? 0;
      final down = double.tryParse(_down.text) ?? 0;
      if (price <= 0) return null;
      return (down / price * 100).toStringAsFixed(0);
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanHeroBanner(
          title: app.tr('home.title'),
          subtitle: app.tr('home.subtitle'),
          badges: [
            LoanHeroBadge(icon: LucideIcons.shield, label: app.tr('home.badge.local')),
            if (app.calculations.isNotEmpty)
              LoanHeroBadge(
                icon: LucideIcons.clock3,
                label: app.tr('home.badge.saved', {'count': '${app.calculations.length}'}),
              ),
          ],
        ),
        LoanFeatureRow(
          ratioLabel: app.tr('home.feature.ratio'),
          amortLabel: app.tr('home.feature.amort'),
          compareLabel: app.tr('home.feature.compare'),
          onRatio: () => _ensureResultThen(app, AppRoute.calcResult),
          onAmort: () => _ensureResultThen(app, AppRoute.amortization),
          onCompare: () => app.push(AppRoute.compare),
        ),
        if (preview != null && previewPayment != null)
          LoanPreviewCard(
            previewTitle: app.tr('home.preview', {'mode': modeLabel(
                  preview.input.category == LoanCategory.dual ? preview.input.mode : _mode,
                  app.locale,
                )}) +
                (downPct != null ? app.tr('home.previewDown', {'pct': downPct}) : ''),
            payment: app.money(previewPayment),
            totalInterest: app.money(preview.totalInterest),
            totalPayment: app.money(preview.totalPayment),
            interestLabel: app.tr('home.totalInterest'),
            totalLabel: app.tr('home.totalPayment'),
          ),
        if (_category != LoanCategory.dual)
          LoanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoanSectionHead(icon: LucideIcons.landmark, title: app.tr('home.repayMode')),
                LoanSegment(
                  options: [
                    ('equal-payment', app.tr('mode.equalPayment')),
                    ('equal-principal', app.tr('mode.equalPrincipal')),
                  ],
                  selected: _mode == RepaymentMode.equalPayment ? 'equal-payment' : 'equal-principal',
                  onSelect: (v) => setState(() =>
                      _mode = v == 'equal-principal' ? RepaymentMode.equalPrincipal : RepaymentMode.equalPayment),
                ),
              ],
            ),
          ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanSectionHead(icon: LucideIcons.wallet, title: app.tr('home.loanType')),
              // 一行四等分：类型是轻量切换，不抢主参数区权重
              Row(
                children: [
                  for (final (i, k) in LoanCategory.values.where((k) => k != LoanCategory.other).indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Builder(builder: (context) {
                        final meta = _loanTypeMeta(k, app);
                        final active = _category == k;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _category = k;
                            if (k == LoanCategory.auto) {
                              _loanManual = false;
                              _syncAutoLoan();
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                            decoration: BoxDecoration(
                              color: active ? RevolutColors.brandStart.withValues(alpha: 0.12) : RevolutColors.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active ? RevolutColors.brandStart.withValues(alpha: 0.25) : RevolutColors.divider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(meta.$1, size: 20, color: active ? RevolutColors.brandSolid : RevolutColors.textSecondary),
                                const SizedBox(height: 4),
                                Text(
                                  meta.$2,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: active ? RevolutColors.brandSolid : RevolutColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_category == LoanCategory.dual)
          ..._dualForms(app)
        else if (_category == LoanCategory.auto)
          _autoForm(app)
        else
          _standardForm(app),
        LoanPrimaryButton(label: app.tr('home.cta'), onPressed: () => _submit(app)),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 0),
          child: LoanMuted(app.tr('home.disclaimer'), center: true, fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _dualForms(AppState app) {
    return [
      _partCard(app, app.tr('dual.partA'), _aPrincipal, _aRate, _aYears, _aMonths, _aMode, (m) => setState(() => _aMode = m), 'a'),
      _partCard(app, app.tr('dual.partB'), _bPrincipal, _bRate, _bYears, _bMonths, _bMode, (m) => setState(() => _bMode = m), 'b'),
    ];
  }

  Widget _partCard(
    AppState app,
    String title,
    TextEditingController principal,
    TextEditingController rate,
    TextEditingController years,
    TextEditingController months,
    RepaymentMode mode,
    ValueChanged<RepaymentMode> onMode,
    String errKey,
  ) {
    return LoanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanSectionHead(icon: LucideIcons.layers, title: title),
          LoanSegment(
            options: [
              ('equal-payment', app.tr('mode.equalPayment')),
              ('equal-principal', app.tr('mode.equalPrincipal')),
            ],
            selected: mode == RepaymentMode.equalPayment ? 'equal-payment' : 'equal-principal',
            onSelect: (v) => onMode(v == 'equal-principal' ? RepaymentMode.equalPrincipal : RepaymentMode.equalPayment),
          ),
          LoanLabel(app.tr('home.principal'), marginTop: 12),
          LoanInput(
            controller: principal,
            suffix: app.tr('home.unit.yuan'),
            error: _errors[errKey] == true,
            onChanged: (_) => setState(() {}),
          ),
          LoanLabel(app.tr('home.rate'), marginTop: 12),
          LoanInput(controller: rate, suffix: '%', error: _errors[errKey] == true, onChanged: (_) => setState(() {})),
          LoanLabel(app.tr('home.term'), marginTop: 12),
          Row(
            children: [
              Expanded(
                child: LoanInput(
                  controller: years,
                  suffix: app.tr('home.year'),
                  error: _errors[errKey] == true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LoanInput(
                  controller: months,
                  suffix: app.tr('home.month'),
                  error: _errors[errKey] == true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _autoForm(AppState app) {
    return LoanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanSectionHead(icon: LucideIcons.car, title: app.tr('home.paramsAuto')),
          LoanLabel(app.tr('home.vehiclePrice')),
          LoanInput(
            controller: _vehicle,
            suffix: app.tr('home.unit.yuan'),
            onChanged: (_) {
              _loanManual = false;
              _syncAutoLoan();
              setState(() {});
            },
          ),
          LoanLabel(app.tr('home.downAmount'), marginTop: 12),
          LoanInput(
            controller: _down,
            suffix: app.tr('home.unit.yuan'),
            onChanged: (_) {
              _loanManual = false;
              _syncAutoLoan();
              setState(() {});
            },
          ),
          LoanLabel(app.tr('home.loanAmount'), marginTop: 12),
          LoanInput(
            controller: _principal,
            suffix: app.tr('home.unit.yuan'),
            error: _errors['principal'] == true,
            onChanged: (_) {
              _loanManual = true;
              setState(() {});
            },
          ),
          LoanMuted(app.tr('home.loanHint'), fontSize: 12),
          LoanLabel(app.tr('home.rate'), marginTop: 12),
          LoanInput(controller: _rate, suffix: '%', error: _errors['rate'] == true, onChanged: (_) => setState(() {})),
          LoanLabel(app.tr('home.term'), marginTop: 12),
          Row(
            children: [
              Expanded(
                child: LoanInput(
                  controller: _years,
                  suffix: app.tr('home.year'),
                  error: _errors['term'] == true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LoanInput(
                  controller: _months,
                  suffix: app.tr('home.month'),
                  error: _errors['term'] == true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['5', '3', '2', '1']
                .map((y) => LoanQuickChip(
                      label: app.tr('home.yearsN', {'n': y}),
                      onTap: () {
                        _years.text = y;
                        _months.text = '0';
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _standardForm(AppState app) {
    return LoanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanSectionHead(icon: LucideIcons.calculator, title: app.tr('home.params')),
          LoanLabel(app.tr('home.principal')),
          LoanInput(
            controller: _principal,
            suffix: app.tr('home.unit.yuan'),
            error: _errors['principal'] == true,
            onChanged: (_) => setState(() {}),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [500000, 1000000, 1500000, 2000000].map((v) {
              final label = v >= 1000000
                  ? app.tr('home.million', {'n': '${v ~/ 1000000}'})
                  : app.tr('home.wan', {'n': '${v ~/ 10000}'});
              return LoanQuickChip(
                label: label,
                onTap: () {
                  _principal.text = '$v';
                  setState(() {});
                },
              );
            }).toList(),
          ),
          LoanLabel(app.tr('home.rate'), marginTop: 14),
          LoanInput(controller: _rate, suffix: '%', error: _errors['rate'] == true, onChanged: (_) => setState(() {})),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['3.1', '3.85', '4.2', '4.9']
                .map((v) => LoanQuickChip(label: '$v%', onTap: () { _rate.text = v; setState(() {}); }))
                .toList(),
          ),
          LoanLabel(app.tr('home.term'), marginTop: 14),
          Row(
            children: [
              Expanded(
                child: LoanInput(
                  controller: _years,
                  suffix: app.tr('home.year'),
                  error: _errors['term'] == true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LoanInput(
                  controller: _months,
                  suffix: app.tr('home.month'),
                  error: _errors['term'] == true,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['30', '20', '10', '5']
                .map((y) => LoanQuickChip(
                      label: app.tr('home.yearsN', {'n': y}),
                      onTap: () {
                        _years.text = y;
                        _months.text = '0';
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  (IconData, String) _loanTypeMeta(LoanCategory k, AppState app) => switch (k) {
        LoanCategory.mortgage => (LucideIcons.home, app.tr('cat.mortgage')),
        LoanCategory.auto => (LucideIcons.car, app.tr('cat.auto')),
        LoanCategory.personal => (LucideIcons.shoppingBag, app.tr('cat.personal')),
        LoanCategory.dual => (LucideIcons.layers, app.tr('cat.dual')),
        LoanCategory.other => (LucideIcons.moreHorizontal, app.tr('cat.other')),
      };
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
    final hero = isDual || isEqPrincipal
        ? '${app.money(result.firstMonthPayment)} → ${app.money(result.lastMonthPayment)}'
        : app.money(result.monthlyPayment);
    final share = result.totalPayment > 0
        ? (result.totalInterest / result.totalPayment * 100).toStringAsFixed(0)
        : '0';
    final fromSaved = app.pendingSavedId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('result.title'),
          subtitle: '${categoryLabel(result.input.category, app.locale)} · ${modeLabel(result.input.mode, app.locale)}',
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(isDual || isEqPrincipal ? app.tr('result.firstLast') : app.tr('result.monthly')),
              LoanHeroAmount(hero),
              DonutChart(
                segments: [
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
                centerLabel: '$share%',
                centerSub: app.tr('result.interestShare'),
              ),
              LoanRow(label: app.tr('result.totalPayment'), value: app.money(result.totalPayment)),
              LoanRow(
                label: app.tr('result.totalInterest'),
                value: app.money(result.totalInterest),
                valueColor: RevolutColors.spend,
              ),
              LoanRow(label: app.tr('result.loanPrincipal'), value: app.money(result.input.principal)),
              if (result.input.vehiclePrice != null)
                LoanRow(label: app.tr('result.vehicle'), value: app.money(result.input.vehiclePrice!)),
              if (result.input.downPayment != null)
                LoanRow(label: app.tr('result.downPayment'), value: app.money(result.input.downPayment!)),
            ],
          ),
        ),
        if (isDual && result.partsResults != null) ...[
          LoanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoanLabel(app.tr('dual.partBreakdown')),
                for (var i = 0; i < result.partsResults!.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LoanRow(
                      label: i == 0 ? app.tr('dual.partA') : app.tr('dual.partB'),
                      value: app.tr('compare.perMonth', {
                        'amount': app.money(result.partsResults![i].monthlyPayment),
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('result.insights')),
              LoanMuted(
                isDual
                    ? app.tr('dual.insight', {
                        'monthly': app.money(result.monthlyPayment),
                        'interest': app.money(result.totalInterest),
                        'total': app.money(result.totalPayment),
                      })
                    : app.tr('result.insight.1', {
                        'mode': modeLabel(result.input.mode, app.locale),
                        'years': (result.input.termMonths / 12).toStringAsFixed(result.input.termMonths % 12 == 0 ? 0 : 1),
                        'share': share,
                      }),
                fontSize: 13,
              ),
            ],
          ),
        ),
        LoanPrimaryButton(label: app.tr('result.amort'), onPressed: () => app.push(AppRoute.amortization)),
        const SizedBox(height: 8),
        LoanSecondaryButton(label: app.tr('result.compare'), onPressed: app.addPendingToCompare),
        if (!fromSaved) ...[
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

class AmortizationScreen extends StatefulWidget {
  const AmortizationScreen({super.key});

  @override
  State<AmortizationScreen> createState() => _AmortizationScreenState();
}

class _AmortizationScreenState extends State<AmortizationScreen> {
  String _view = 'month';
  final _from = TextEditingController(text: '1');
  final _to = TextEditingController();

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final result = app.pendingResult;
    if (result == null) return const RedirectCalcScreen();

    final max = result.schedule.length;
    if (_to.text.isEmpty) _to.text = '$max';

    List<AmortizationRow> rows;
    if (_view == 'year') {
      rows = _yearlyRows(result);
    } else if (_view == 'custom') {
      final from = (int.tryParse(_from.text) ?? 1).clamp(1, max);
      final to = (int.tryParse(_to.text) ?? max).clamp(from, max);
      rows = result.schedule.where((r) => r.period >= from && r.period <= to).toList();
    } else {
      rows = result.schedule;
    }

    final sumPay = rows.fold<double>(0, (s, r) => s + r.payment);
    final sumPrin = rows.fold<double>(0, (s, r) => s + r.principal);
    final sumInt = rows.fold<double>(0, (s, r) => s + r.interest);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('amort.title'),
          subtitle: app.tr('amort.periods', {'n': '$max'}),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanSegment(
                options: [
                  ('month', app.tr('amort.byMonth')),
                  ('year', app.tr('amort.byYear')),
                  ('custom', app.tr('amort.byCustom')),
                ],
                selected: _view,
                onSelect: (v) => setState(() => _view = v),
              ),
              if (_view == 'custom') ...[
                const SizedBox(height: 12),
                LoanMuted(app.tr('amort.rangeHint', {'max': '$max'}), fontSize: 12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoanLabel(app.tr('amort.fromPeriod')),
                          LoanInput(
                            controller: _from,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoanLabel(app.tr('amort.toPeriod')),
                          LoanInput(
                            controller: _to,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                LoanMuted(app.tr('amort.showing', {'n': '${rows.length}'}), fontSize: 12),
                const SizedBox(height: 8),
                LoanRow(label: app.tr('amort.rangeSum'), value: app.money(sumPay)),
                LoanRow(label: app.tr('amort.col.principal'), value: app.money(sumPrin)),
                LoanRow(label: app.tr('amort.col.interest'), value: app.money(sumInt)),
              ],
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RevolutColors.textSecondary,
                  ),
                  dataTextStyle: monoStyle(context, size: 11),
                  columns: [
                    DataColumn(label: Text(_view == 'year' ? app.tr('amort.col.year') : app.tr('amort.col.period'))),
                    DataColumn(label: Text(app.tr('amort.col.payment'))),
                    DataColumn(label: Text(app.tr('amort.col.principal'))),
                    DataColumn(label: Text(app.tr('amort.col.interest'))),
                    DataColumn(label: Text(app.tr('amort.col.balance'))),
                  ],
                  rows: rows.map((row) {
                    return DataRow(cells: [
                      DataCell(Text('${row.period}')),
                      DataCell(Text(app.money(row.payment))),
                      DataCell(Text(app.money(row.principal))),
                      DataCell(Text(app.money(row.interest))),
                      DataCell(Text(app.money(row.balance))),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<AmortizationRow> _yearlyRows(CalcResult result) {
    final out = <AmortizationRow>[];
    for (var i = 0; i < result.schedule.length; i += 12) {
      final chunk = result.schedule.skip(i).take(12).toList();
      out.add(AmortizationRow(
        period: i ~/ 12 + 1,
        payment: chunk.fold(0.0, (s, r) => s + r.payment),
        principal: chunk.fold(0.0, (s, r) => s + r.principal),
        interest: chunk.fold(0.0, (s, r) => s + r.interest),
        balance: chunk.last.balance,
      ));
    }
    return out;
  }
}

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ids = app.compareIds;
    final results = <(String, CalcResult)>[];
    for (final id in ids) {
      final r = app.resultForCompareId(id);
      if (r != null) results.add((id, r));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('compare.title'),
          subtitle: app.tr('compare.subtitle', {'n': '${results.length}'}),
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
          LoanCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                dataTextStyle: monoStyle(context, size: 11),
                columns: [
                  DataColumn(label: Text(app.tr('compare.metric'))),
                  ...results.asMap().entries.map((e) => DataColumn(
                        label: Text('#${e.key + 1}'),
                      )),
                ],
                rows: [
                  _cmpRow(app.tr('compare.principal'), results.map((e) => app.money(e.$2.input.principal)).toList()),
                  _cmpRow(app.tr('compare.rate'), results.map((e) => '${e.$2.input.annualRatePercent}%').toList()),
                  _cmpRow(
                    app.tr('compare.term'),
                    results.map((e) => app.tr('compare.termMonths', {'n': '${e.$2.input.termMonths}'})).toList(),
                  ),
                  _cmpRow(app.tr('compare.monthly'), results.map((e) => app.money(e.$2.monthlyPayment)).toList()),
                  _cmpRow(app.tr('result.totalInterest'), results.map((e) => app.money(e.$2.totalInterest)).toList()),
                  _cmpRow(app.tr('result.totalPayment'), results.map((e) => app.money(e.$2.totalPayment)).toList()),
                ],
              ),
            ),
          ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...results.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LoanSecondaryButton(
                  label: '${app.tr('compare.remove')} #${results.indexOf(e) + 1}',
                  onPressed: () => app.removeFromCompare(e.$1),
                ),
              )),
        ],
        LoanMuted(app.tr('compare.hint'), fontSize: 12),
        const SizedBox(height: 8),
        LoanSecondaryButton(
          label: app.tr('compare.addSaved'),
          onPressed: () => app.push(AppRoute.savedList),
        ),
      ],
    );
  }

  DataRow _cmpRow(String label, List<String> values) => DataRow(
        cells: [DataCell(Text(label)), ...values.map((v) => DataCell(Text(v)))],
      );
}

// --- Savings ---

class _SavingsInsightLine extends StatelessWidget {
  const _SavingsInsightLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.muted,
    this.marginBottom = 8,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool muted;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: muted ? RevolutColors.textSecondary : RevolutColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsListScreen extends StatelessWidget {
  const SavingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final goals = app.savingsGoals;

    if (goals.isEmpty) {
      return Column(
        children: [
          LoanTopBar(title: app.tr('savings.title'), subtitle: app.tr('savings.subtitle')),
          LoanEmpty(
            icon: const Icon(LucideIcons.piggyBank, size: 40, color: RevolutColors.brandSolid),
            message: app.tr('savings.empty'),
            action: LoanPrimaryButton(label: app.tr('savings.new'), onPressed: () => app.push(AppRoute.savingsNew)),
          ),
        ],
      );
    }

    final totalSaved = goals.fold<double>(0, (s, g) => s + g.current);
    final totalTarget = goals.fold<double>(0, (s, g) => s + g.target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          title: app.tr('savings.title'),
          subtitle: app.tr('savings.inProgress', {'n': '${goals.length}'}),
        ),
        LoanStatRow(
          children: [
            LoanStatBox(label: app.tr('savings.savedTotal'), value: app.money(totalSaved)),
            LoanStatBox(label: app.tr('savings.targetTotal'), value: app.money(totalTarget)),
          ],
        ),
        if (app.calculations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LoanMuted(
              app.tr('savings.linkedHint', {'n': '${app.calculations.length}'}),
              fontSize: 12,
            ),
          ),
        ...goals.map((g) {
          final pct = g.target > 0 ? (g.current / g.target * 100).clamp(0, 100) : 0.0;
          final left = (g.target - g.current).clamp(0, double.infinity);
          final name = _savingsName(g.name, app);
          return LoanCard(
            onTap: () => app.push(AppRoute.savingsDetail, id: g.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    LoanChip('${pct.toStringAsFixed(0)}%'),
                  ],
                ),
                Center(
                  child: DonutChart(
                    size: 120,
                    stroke: 10,
                    animate: false,
                    segments: [
                      DonutSegment(
                        value: g.current,
                        color: RevolutColors.brandStart,
                        label: app.tr('savings.done'),
                        amountText: app.money(g.current),
                      ),
                      DonutSegment(
                        value: left.toDouble(),
                        color: RevolutColors.donutTrack,
                        label: app.tr('savings.todo'),
                        amountText: app.money(left.toDouble()),
                      ),
                    ],
                    centerLabel: '${pct.toStringAsFixed(0)}%',
                    centerSub: app.tr('savings.progress'),
                  ),
                ),
                // 提示挂在对应目标卡片内，多目标时不会混淆
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LoanCard.savingsInsightGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RevolutColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoanLabel(
                        app.tr('savings.insightsFor', {'name': name}),
                        marginBottom: 10,
                      ),
                      _SavingsInsightLine(
                        icon: LucideIcons.clock3,
                        iconColor: RevolutColors.text,
                        text: savingsEtaLine(g, app.money, app.tr),
                        muted: false,
                      ),
                      _SavingsInsightLine(
                        icon: LucideIcons.shield,
                        iconColor: RevolutColors.textSecondary,
                        text: savingsBufferLine(g, app.calculations, app.money, app.tr),
                        muted: true,
                        marginBottom: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String _savingsName(String name, AppState app) {
  final n = name.trim();
  if (n.isEmpty || n == '月供缓冲金' || n == 'Payment buffer') {
    return app.tr('savings.defaultName');
  }
  return n;
}

class SavingsNewScreen extends StatefulWidget {
  const SavingsNewScreen({super.key});

  @override
  State<SavingsNewScreen> createState() => _SavingsNewScreenState();
}

class _SavingsNewScreenState extends State<SavingsNewScreen> {
  late final TextEditingController _name;
  late final TextEditingController _target;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name = TextEditingController(text: app.tr('savings.defaultName'));
    _target = TextEditingController(
      text: app.savingsPrefill?.isNotEmpty == true ? app.savingsPrefill : '15000',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('savings.create')),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('savings.name')),
              LoanInput(controller: _name, onChanged: (_) {}),
              LoanLabel(app.tr('savings.target'), marginTop: 12),
              LoanInput(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: app.tr('savings.createCta'),
          onPressed: () async {
            final target = double.tryParse(_target.text);
            if (_name.text.trim().isEmpty || target == null || target <= 0) return;
            final goal = SavingsGoal(
              id: uid('goal'),
              name: _name.text.trim(),
              target: target,
              current: 0,
              deadline: null,
              linkedCalcId: null,
              transactions: [],
              createdAt: DateTime.now().toIso8601String(),
            );
            await app.persistSavings([goal, ...app.savingsGoals]);
            app.showToast(app.tr('savings.created'));
            app.replaceRoute(AppRoute.savings);
          },
        ),
      ],
    );
  }
}

class SavingsDetailScreen extends StatefulWidget {
  const SavingsDetailScreen({super.key});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final goal2 = app.savingsGoals.where((x) => x.id == app.detailId).firstOrNull;

    if (goal2 == null) {
      return EmptyRedirectScreen(
        message: app.tr('savings.missing'),
        onGo: () => app.replaceRoute(AppRoute.savings),
      );
    }

    void addTx(String type) {
      final v = double.tryParse(_amount.text);
      if (v == null || v <= 0) return;
      final delta = type == 'deposit' ? v : -v;
      final next = (goal2.current + delta).clamp(0, double.infinity);
      final tx = SavingsTransaction(
        id: uid('tx'),
        amount: v,
        type: type,
        note: type == 'deposit' ? app.tr('savings.deposit') : app.tr('savings.withdraw'),
        at: DateTime.now().toIso8601String(),
      );
      app.persistSavings(
        app.savingsGoals
            .map((x) => x.id == goal2.id
                ? x.copyWith(current: next.toDouble(), transactions: [tx, ...x.transactions])
                : x)
            .toList(),
      );
      _amount.clear();
      setState(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: _savingsName(goal2.name, app),
          subtitle: '${app.money(goal2.current)} / ${app.money(goal2.target)}',
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('savings.depositWithdraw')),
              LoanInput(
                controller: _amount,
                placeholder: app.tr('savings.amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  LoanPrimaryButton(label: app.tr('savings.deposit'), flex: true, onPressed: () => addTx('deposit')),
                  const SizedBox(width: 8),
                  LoanSecondaryButton(label: app.tr('savings.withdraw'), flex: true, onPressed: () => addTx('withdraw')),
                ],
              ),
            ],
          ),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('savings.flow')),
              if (goal2.transactions.isEmpty)
                LoanMuted(app.tr('savings.noTx'), fontSize: 14)
              else
                ...goal2.transactions.map((tx) {
                  return LoanRow(
                    label:
                        '${tx.type == 'deposit' ? app.tr('savings.deposit') : app.tr('savings.withdraw')} · ${formatShortDate(DateTime.parse(tx.at))}',
                    value: '${tx.type == 'deposit' ? '+' : '-'}${app.money(tx.amount)}',
                    valueColor: tx.type == 'deposit' ? RevolutColors.income : null,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

// --- Saved ---

class SavedListScreen extends StatelessWidget {
  const SavedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.calculations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('saved.title'),
          subtitle: app.tr('saved.count', {'n': '${list.length}'}),
        ),
        if (list.isEmpty)
          LoanEmpty(
            icon: const Icon(LucideIcons.bookmark, size: 40, color: RevolutColors.brandSolid),
            message: app.tr('saved.empty'),
            action: LoanPrimaryButton(
              label: app.tr('saved.goCalc'),
              onPressed: () => app.goTab(0),
            ),
          )
        else
          ...list.map((c) {
            final inCompare = app.compareIds.contains(c.id);
            return LoanCard(
              onTap: () {
                app.setPendingResult(c.result, savedId: c.id);
                app.push(AppRoute.savedDetail, id: c.id);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.note.isNotEmpty ? c.note : categoryLabel(c.result.input.category, app.locale),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (c.favorite) const Icon(LucideIcons.star, size: 16, color: RevolutColors.brandSolid),
                      if (inCompare) ...[
                        const SizedBox(width: 6),
                        LoanChip(app.tr('saved.inCompare')),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  LoanMuted(
                    app.tr('saved.meta', {
                      'principal': app.money(c.result.input.principal),
                      'rate': '${c.result.input.annualRatePercent}',
                      'months': '${c.result.input.termMonths}',
                    }),
                    fontSize: 12,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app.tr('compare.perMonth', {'amount': app.money(c.result.monthlyPayment)}),
                    style: monoStyle(context, size: 16, w: FontWeight.w700)
                        .copyWith(color: RevolutColors.brandSolid),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      LoanLedgerInlineAction(
                        label: c.favorite ? app.tr('saved.unfav') : app.tr('saved.fav'),
                        danger: false,
                        onPressed: () {
                          app.persistCalculations(
                            app.calculations
                                .map((x) => x.id == c.id ? x.copyWith(favorite: !x.favorite) : x)
                                .toList(),
                          );
                        },
                      ),
                      LoanLedgerInlineAction(
                        label: app.tr('saved.compare'),
                        danger: false,
                        onPressed: () => app.addToCompare(c.id),
                      ),
                      LoanLedgerInlineAction(
                        label: app.tr('saved.delete'),
                        onPressed: () async {
                          await app.persistCalculations(app.calculations.where((x) => x.id != c.id).toList());
                          app.showToast(app.tr('saved.deleted'));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class SavedDetailScreen extends StatelessWidget {
  const SavedDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = app.calculations.where((c) => c.id == app.detailId).firstOrNull;
    if (item == null) {
      return EmptyRedirectScreen(
        message: app.tr('common.missing'),
        onGo: () => app.replaceRoute(AppRoute.savedList),
      );
    }
    // Ensure pending mirrors saved item (idempotent if already set by list tap).
    if (app.pendingSavedId != item.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<AppState>().setPendingResult(item.result, savedId: item.id);
        }
      });
    }
    return const CalcResultScreen();
  }
}

// --- Profile ---

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(title: app.tr('profile.title'), subtitle: app.tr('profile.subtitle')),
        LoanCard(
          child: Row(
            children: [
              Text(app.profile.avatar, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.displayNickname(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    LoanMuted(app.tr('profile.localOnly'), fontSize: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        LoanStatRow(
          children: [
            LoanStatBox(label: app.tr('profile.savedCount'), value: '${app.calculations.length}'),
            LoanStatBox(label: app.tr('profile.savingsCount'), value: '${app.savingsGoals.length}'),
          ],
        ),
        LoanMenuItem(
          label: app.tr('profile.saved'),
          onTap: () => app.push(AppRoute.savedList),
        ),
        LoanMenuItem(
          label: app.tr('profile.settings'),
          onTap: () => app.push(AppRoute.profileSettings),
        ),
        LoanMenuItem(
          label: app.tr('profile.data'),
          onTap: () => app.push(AppRoute.profileData),
        ),
        LoanMenuItem(
          label: app.tr('profile.about'),
          onTap: () => app.push(AppRoute.profileAbout),
        ),
      ],
    );
  }
}

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _nick;
  late TextEditingController _avatar;
  late int _decimals;
  late AppLocale _locale;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _nick = TextEditingController(text: app.profile.nickname);
    _avatar = TextEditingController(text: app.profile.avatar);
    _decimals = app.settings.decimals;
    _locale = app.settings.locale;
    _currency = app.settings.currencyCode;
  }

  @override
  void dispose() {
    _nick.dispose();
    _avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('settings.title')),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('settings.nickname')),
              LoanInput(controller: _nick, onChanged: (_) {}),
              LoanLabel(app.tr('settings.avatar'), marginTop: 12),
              LoanInput(controller: _avatar, onChanged: (_) {}),
              LoanLabel(app.tr('settings.decimals'), marginTop: 12),
              LoanSegment(
                options: const [('0', '0'), ('2', '2')],
                selected: '$_decimals',
                onSelect: (v) => setState(() => _decimals = int.parse(v)),
              ),
              LoanLabel(app.tr('settings.language'), marginTop: 12),
              LoanSegment(
                options: appLocales.map((e) => (e.$1.id, e.$2)).toList(),
                selected: _locale.id,
                onSelect: (v) => setState(() => _locale = AppLocaleX.fromId(v)),
              ),
              LoanLabel(app.tr('currency.label'), marginTop: 12),
              CurrencyPicker(
                currencyCode: _currency,
                onChange: (c) => setState(() => _currency = c),
              ),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: app.tr('settings.save'),
          onPressed: () async {
            await app.updateProfile(UserProfile(
              nickname: _nick.text.trim(),
              avatar: _avatar.text.trim().isEmpty ? '🧑‍💼' : _avatar.text.trim(),
              createdAt: app.profile.createdAt,
            ));
            await app.updateSettings(app.settings.copyWith(
              decimals: _decimals,
              locale: _locale,
              currencyCode: _currency,
            ));
            app.showToast(app.tr('toast.savedProfile'));
            app.pop();
          },
        ),
      ],
    );
  }
}

class ProfileDataScreen extends StatelessWidget {
  const ProfileDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('data.title')),
        LoanPrimaryButton(label: app.tr('data.export'), onPressed: app.exportData),
        const SizedBox(height: 8),
        LoanSecondaryButton(
          label: app.tr('data.clear'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(app.tr('data.clear')),
                content: Text(app.tr('data.confirm')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('common.back'))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('data.clear'))),
                ],
              ),
            );
            if (ok == true) {
              await app.clearBusiness();
              app.showToast(app.tr('data.cleared'));
            }
          },
        ),
        const SizedBox(height: 12),
        LoanMuted(app.tr('data.hint'), fontSize: 12),
      ],
    );
  }
}

class ProfileAboutScreen extends StatelessWidget {
  const ProfileAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('about.title')),
        LoanCard(child: LoanMuted(app.tr('about.body'), fontSize: 14)),
      ],
    );
  }
}

class RedirectCalcScreen extends StatelessWidget {
  const RedirectCalcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return EmptyRedirectScreen(
      message: app.tr('home.fillFirst'),
      onGo: () => app.goTab(0),
    );
  }
}

class EmptyRedirectScreen extends StatelessWidget {
  const EmptyRedirectScreen({super.key, required this.message, required this.onGo});
  final String message;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      children: [
        LoanEmpty(
          icon: const Icon(LucideIcons.circleAlert, size: 40, color: RevolutColors.brandSolid),
          message: message,
          action: LoanPrimaryButton(label: app.tr('common.back'), onPressed: onGo),
        ),
      ],
    );
  }
}
