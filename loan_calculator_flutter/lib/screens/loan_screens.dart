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
import '../widgets/compare_bar_chart.dart';
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
  bool _toSeeded = false;
  List<AmortizationRow>? _yearCache;
  int? _yearCacheLen;

  static const _rowH = 34.0;
  static const _colPeriod = 40.0;
  static const _colMoney = 100.0;
  static const _tableW = _colPeriod + _colMoney * 4;

  List<_AmortLine>? _lines;
  String? _lineKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_toSeeded) return;
    final len = context.read<AppState>().pendingResult?.schedule.length;
    if (len != null) {
      _to.text = '$len';
      _toSeeded = true;
    }
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  List<AmortizationRow> _rowsFor(CalcResult result) {
    final max = result.schedule.length;
    if (_view == 'year') {
      if (_yearCache == null || _yearCacheLen != max) {
        _yearCache = _yearlyRows(result);
        _yearCacheLen = max;
      }
      return _yearCache!;
    }
    if (_view == 'custom') {
      final from = (int.tryParse(_from.text) ?? 1).clamp(1, max);
      final to = (int.tryParse(_to.text) ?? max).clamp(from, max);
      // 按期切片，避免 where 全表扫描再 toList
      return result.schedule.sublist(from - 1, to);
    }
    return result.schedule;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final result = app.pendingResult;
    if (result == null) return const RedirectCalcScreen();

    final max = result.schedule.length;
    final rows = _rowsFor(result);
    final lines = _linesFor(app, result, rows);
    final headStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: RevolutColors.textSecondary,
    );

    double sumPay = 0, sumPrin = 0, sumInt = 0;
    if (_view == 'custom') {
      for (final r in rows) {
        sumPay += r.payment;
        sumPrin += r.principal;
        sumInt += r.interest;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: app.tr('amort.title'),
          subtitle: app.tr('amort.periods', {'n': '$max'}),
        ),
        Expanded(
          child: LoanCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
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
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth > _tableW ? constraints.maxWidth : _tableW;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: width,
                          child: Column(
                            children: [
                              _AmortHeaderRow(
                                periodLabel: _view == 'year' ? app.tr('amort.col.year') : app.tr('amort.col.period'),
                                payment: app.tr('amort.col.payment'),
                                principal: app.tr('amort.col.principal'),
                                interest: app.tr('amort.col.interest'),
                                balance: app.tr('amort.col.balance'),
                                style: headStyle,
                              ),
                              const Divider(height: 1, color: RevolutColors.divider),
                              Expanded(
                                child: ListView.builder(
                                  primary: false,
                                  itemExtent: _rowH,
                                  itemCount: lines.length,
                                  addAutomaticKeepAlives: false,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (context, i) => _AmortDataRow(line: lines[i]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<AmortizationRow> _yearlyRows(CalcResult result) {
    final out = <AmortizationRow>[];
    final schedule = result.schedule;
    for (var i = 0; i < schedule.length; i += 12) {
      final end = (i + 12).clamp(0, schedule.length);
      var payment = 0.0, principal = 0.0, interest = 0.0;
      for (var j = i; j < end; j++) {
        final r = schedule[j];
        payment += r.payment;
        principal += r.principal;
        interest += r.interest;
      }
      out.add(AmortizationRow(
        period: i ~/ 12 + 1,
        payment: payment,
        principal: principal,
        interest: interest,
        balance: schedule[end - 1].balance,
      ));
    }
    return out;
  }

  List<_AmortLine> _linesFor(AppState app, CalcResult result, List<AmortizationRow> rows) {
    final key =
        '${identityHashCode(result)}|$_view|${_from.text}|${_to.text}|${rows.length}|${app.settings.currencyCode}|${app.settings.decimals}';
    final cached = _lines;
    if (cached != null && _lineKey == key && cached.length == rows.length) return cached;
    final lines = List<_AmortLine>.generate(rows.length, (i) {
      final r = rows[i];
      return _AmortLine(
        '${r.period}',
        app.money(r.payment),
        app.money(r.principal),
        app.money(r.interest),
        app.money(r.balance),
      );
    }, growable: false);
    _lines = lines;
    _lineKey = key;
    return lines;
  }
}

class _AmortLine {
  const _AmortLine(this.period, this.payment, this.principal, this.interest, this.balance);

  final String period;
  final String payment;
  final String principal;
  final String interest;
  final String balance;
}

class _AmortHeaderRow extends StatelessWidget {
  const _AmortHeaderRow({
    required this.periodLabel,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.style,
  });

  final String periodLabel;
  final String payment;
  final String principal;
  final String interest;
  final String balance;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          _cell(periodLabel, _AmortizationScreenState._colPeriod, style),
          _cell(payment, _AmortizationScreenState._colMoney, style),
          _cell(principal, _AmortizationScreenState._colMoney, style),
          _cell(interest, _AmortizationScreenState._colMoney, style),
          _cell(balance, _AmortizationScreenState._colMoney, style),
        ],
      ),
    );
  }
}

class _AmortDataRow extends StatelessWidget {
  const _AmortDataRow({required this.line});

  final _AmortLine line;

  /// 不继承 Noto Sans SC，数字走系统字体，避免滑动时逐行做中文字形排版。
  static const _style = TextStyle(
    inherit: false,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: RevolutColors.text,
  );
  static const _deco = BoxDecoration(
    border: Border(bottom: BorderSide(color: RevolutColors.divider)),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _deco,
      child: SizedBox(
        height: _AmortizationScreenState._rowH,
        child: Row(
          children: [
            _num(line.period, _AmortizationScreenState._colPeriod),
            _num(line.payment, _AmortizationScreenState._colMoney),
            _num(line.principal, _AmortizationScreenState._colMoney),
            _num(line.interest, _AmortizationScreenState._colMoney),
            _num(line.balance, _AmortizationScreenState._colMoney),
          ],
        ),
      ),
    );
  }

  static Widget _num(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text, style: _style, textAlign: TextAlign.center, maxLines: 1),
    );
  }
}

Widget _cell(String text, double width, TextStyle style, {TextAlign align = TextAlign.center}) {
  return SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: style, textAlign: align, maxLines: 1, overflow: TextOverflow.clip),
    ),
  );
}

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
    final nameCount = <String, int>{};
    for (final name in planNames) {
      nameCount[name] = (nameCount[name] ?? 0) + 1;
    }
    for (var i = 0; i < planNames.length; i++) {
      if ((nameCount[planNames[i]] ?? 0) < 2) continue;
      final result = results[i].$2;
      planNames[i] =
          '${planNames[i]} · ${app.tr('compare.termMonths', {'n': '${result.input.termMonths}'})}';
    }

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
                        extras[i].note.isNotEmpty
                            ? extras[i].note
                            : categoryLabel(extras[i].result.input.category, app.locale),
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

/// Lucide star polygon, filled. The icon font only ships the outline.
class _FilledStar extends StatelessWidget {
  const _FilledStar({this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _FilledStarPainter(RevolutColors.brandSolid),
    );
  }
}

class _FilledStarPainter extends CustomPainter {
  const _FilledStarPainter(this.color);

  final Color color;

  static const _pts = <Offset>[
    Offset(12, 2),
    Offset(15.09, 8.26),
    Offset(22, 9.27),
    Offset(17, 14.14),
    Offset(18.18, 21.02),
    Offset(12, 17.77),
    Offset(5.82, 21.02),
    Offset(7, 14.14),
    Offset(2, 9.27),
    Offset(8.91, 8.26),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()..moveTo(_pts[0].dx * s, _pts[0].dy * s);
    for (var i = 1; i < _pts.length; i++) {
      path.lineTo(_pts[i].dx * s, _pts[i].dy * s);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FilledStarPainter oldDelegate) => oldDelegate.color != color;
}

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
                            if (c.favorite) const _FilledStar(size: 16),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      LoanQuickChip(
                        label: c.favorite ? app.tr('saved.unfav') : app.tr('saved.fav'),
                        onTap: () {
                          app.persistCalculations(
                            app.calculations
                                .map((x) => x.id == c.id ? x.copyWith(favorite: !x.favorite) : x)
                                .toList(),
                          );
                        },
                      ),
                      LoanQuickChip(
                        label: app.tr('saved.compare'),
                        onTap: () => app.addToCompare(c.id),
                      ),
                      LoanQuickChip(
                        label: app.tr('saved.delete'),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(app.tr('saved.deleteTitle')),
                              content: Text(app.tr('saved.deleteConfirm')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(app.tr('common.back')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(app.tr('saved.delete')),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          app.removeFromCompare(c.id);
                          await app.persistCalculations(
                            app.calculations.where((x) => x.id != c.id).toList(),
                          );
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
            LoanStatBox(
              label: app.tr('profile.savedCount'),
              value: '${app.calculations.length}',
              onTap: () => app.push(AppRoute.savedList),
            ),
            LoanStatBox(
              label: app.tr('profile.savingsCount'),
              value: '${app.savingsGoals.length}',
              onTap: () => app.goTab(1),
            ),
          ],
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
