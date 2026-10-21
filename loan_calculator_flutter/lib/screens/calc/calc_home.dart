import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../data/calc.dart';
import '../../data/input_utils.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';
import '../../widgets/loan_widgets.dart';

class CalcHomeScreen extends StatefulWidget {
  const CalcHomeScreen({super.key});

  @override
  State<CalcHomeScreen> createState() => _CalcHomeScreenState();
}

class _CalcHomeScreenState extends State<CalcHomeScreen> {
  RepaymentMode _mode = RepaymentMode.equalPayment;
  LoanCategory _category = LoanCategory.mortgage;
  final _principal = TextEditingController(text: formatGroupedAmount('1000000'));
  final _rate = TextEditingController(text: '4.2');
  final _years = TextEditingController(text: '30');
  final _months = TextEditingController(text: '0');
  final _vehicle = TextEditingController(text: formatGroupedAmount('200000'));
  final _down = TextEditingController(text: formatGroupedAmount('40000'));
  bool _loanManual = false;

  // Dual parts
  final _aPrincipal = TextEditingController(text: formatGroupedAmount('800000'));
  final _aRate = TextEditingController(text: '4.2');
  final _aYears = TextEditingController(text: '25');
  final _aMonths = TextEditingController(text: '0');
  RepaymentMode _aMode = RepaymentMode.equalPayment;
  final _bPrincipal = TextEditingController(text: formatGroupedAmount('300000'));
  final _bRate = TextEditingController(text: '3.1');
  final _bYears = TextEditingController(text: '20');
  final _bMonths = TextEditingController(text: '0');
  RepaymentMode _bMode = RepaymentMode.equalPayment;

  final _errors = <String, bool>{};

  void _applyGroupedAmounts() {
    for (final c in [_principal, _vehicle, _down, _aPrincipal, _bPrincipal]) {
      final next = formatGroupedAmount(c.text.replaceAll(',', ''));
      if (c.text == next) continue;
      c.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _applyGroupedAmounts();
  }

  @override
  void reassemble() {
    super.reassemble();
    _applyGroupedAmounts();
  }

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

  String? _overTotalKey() {
    if (_category != LoanCategory.auto) return null;
    final price = _amount(_vehicle);
    if (price == null || price <= 0) return null;
    final down = _amount(_down);
    if (down != null && down > price) return 'home.downOverPrice';
    final loan = _amount(_principal);
    if (loan != null && loan > price) return 'home.loanOverPrice';
    return null;
  }

  bool _rejectIfOver(AppState app) {
    final key = _overTotalKey();
    if (key == null) return false;
    _errors.clear();
    _errors[key == 'home.downOverPrice' ? 'down' : 'principal'] = true;
    setState(() {});
    app.showToast(app.tr(key));
    return true;
  }

  bool _rateNotPositive(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty || text == '.') return false;
    final n = double.tryParse(text);
    return n != null && n <= 0;
  }

  bool _rejectIfRate(AppState app) {
    if (_category == LoanCategory.dual) {
      final lowA = _rateNotPositive(_aRate);
      final lowB = _rateNotPositive(_bRate);
      if (!lowA && !lowB) return false;
      _errors.clear();
      if (lowA) _errors['aRate'] = true;
      if (lowB) _errors['bRate'] = true;
    } else {
      if (!_rateNotPositive(_rate)) return false;
      _errors.clear();
      _errors['rate'] = true;
    }
    setState(() {});
    app.showToast(app.tr('home.ratePositive'));
    return true;
  }

  void _syncAutoLoan() {
    if (_loanManual) return;
    final price = _amount(_vehicle);
    final down = _amount(_down);
    if (price == null || price <= 0 || down == null || down < 0 || down > price) return;
    final loan = price - down;
    final loanText = loan == loan.roundToDouble() ? '${loan.round()}' : loan.toStringAsFixed(2);
    _principal.text = formatGroupedAmount(loanText);
  }

  int _term(TextEditingController y, TextEditingController m) =>
      (int.tryParse(y.text) ?? 0) * 12 + (int.tryParse(m.text) ?? 0);

  double? _amount(TextEditingController c) => parseAmountString(c.text);

  bool _principalChipSelected(int value) {
    final p = _amount(_principal);
    return p != null && (p - value).abs() < 1;
  }

  bool _rateChipSelected(String value) => _rate.text.trim() == value;

  int _termMaxYears() =>
      _category == LoanCategory.auto || _category == LoanCategory.personal ? 5 : 30;

  LoanSummary? _preview() {
    try {
      return _summarizeInput();
    } catch (_) {
      return null;
    }
  }

  LoanSummary? _summarizeInput() {
    if (_category == LoanCategory.dual) {
      final ap = _amount(_aPrincipal);
      final ar = double.tryParse(_aRate.text);
      final at = _term(_aYears, _aMonths);
      final bp = _amount(_bPrincipal);
      final br = double.tryParse(_bRate.text);
      final bt = _term(_bYears, _bMonths);
      if (ap == null || ap <= 0 || ar == null || ar <= 0 || at <= 0) return null;
      if (bp == null || bp <= 0 || br == null || br <= 0 || bt <= 0) return null;
      return summarizeLoan(CalcInput(
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
    if (_overTotalKey() != null) return null;
    final p = _amount(_principal);
    final r = double.tryParse(_rate.text);
    final termMonths = _term(_years, _months);
    if (p == null || p <= 0 || r == null || r <= 0 || termMonths <= 0) return null;

    double? vehicle;
    double? down;
    if (_category == LoanCategory.auto) {
      vehicle = _amount(_vehicle);
      down = _amount(_down);
    }

    return summarizeLoan(CalcInput(
      principal: p,
      annualRatePercent: r,
      termMonths: termMonths,
      mode: _mode,
      category: _category,
      vehiclePrice: vehicle,
      downPayment: down,
    ));
  }

  CalcResult? _buildResult() {
    if (_overTotalKey() != null) return null;
    if (_category == LoanCategory.dual) {
      final ap = _amount(_aPrincipal);
      final ar = double.tryParse(_aRate.text);
      final at = _term(_aYears, _aMonths);
      final bp = _amount(_bPrincipal);
      final br = double.tryParse(_bRate.text);
      final bt = _term(_bYears, _bMonths);
      if (ap == null || ap <= 0 || ar == null || ar <= 0 || at <= 0) return null;
      if (bp == null || bp <= 0 || br == null || br <= 0 || bt <= 0) return null;
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
    final p = _amount(_principal);
    final r = double.tryParse(_rate.text);
    final termMonths = _term(_years, _months);
    if (p == null || p <= 0 || r == null || r <= 0 || termMonths <= 0) return null;

    double? vehicle;
    double? down;
    if (_category == LoanCategory.auto) {
      vehicle = _amount(_vehicle);
      down = _amount(_down);
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
    if (_rejectIfOver(app)) return;
    if (_rejectIfRate(app)) return;
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
    if (_rejectIfOver(app)) return;
    if (_rejectIfRate(app)) return;
    final result = _buildResult();
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
      final price = _amount(_vehicle) ?? 0;
      final down = _amount(_down) ?? 0;
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
        LoanPrimaryButton(label: app.tr('home.cta'), onPressed: () => _submit(app)),
        const SizedBox(height: 8),
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
        LoanPreviewCard(
          previewTitle: app.tr('home.preview', {
                'mode': modeLabel(_category == LoanCategory.dual ? _aMode : _mode, app.locale),
              }) +
              (downPct != null ? app.tr('home.previewDown', {'pct': downPct}) : ''),
          payment: preview != null && previewPayment != null ? app.money(previewPayment) : '—',
          totalInterest: preview != null ? app.money(preview.totalInterest) : '—',
          totalPayment: preview != null ? app.money(preview.totalPayment) : '—',
          interestLabel: app.tr('home.totalInterest'),
          totalLabel: app.tr('home.totalPayment'),
        ),
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
            suffix: app.amountUnit,
            error: _errors[errKey] == true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: groupedDecimalInputFormatters,
            amountStyle: true,
            onChanged: (_) => setState(() {}),
          ),
          LoanLabel(app.tr('home.rate'), marginTop: 12),
          LoanInput(controller: rate, suffix: '%', error: _errors['${errKey}Rate'] == true || _rateNotPositive(rate), onChanged: (_) => setState(() {})),
          if (_rateNotPositive(rate))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.tr('home.ratePositive'),
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.spend),
              ),
            ),
          LoanLabel(app.tr('home.term'), marginTop: 12),
          LoanTermSelect(
            value: years.text.trim().isEmpty ? '1' : years.text.trim(),
            maxYears: 30,
            title: app.tr('home.term'),
            error: _errors[errKey] == true,
            labelBuilder: (y) => app.tr('home.yearsN', {'n': y}),
            onChanged: (y) {
              years.text = y;
              months.text = '0';
              setState(() {});
            },
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
            suffix: app.amountUnit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: groupedDecimalInputFormatters,
            amountStyle: true,
            onChanged: (_) {
              _loanManual = false;
              _syncAutoLoan();
              setState(() {});
            },
          ),
          LoanLabel(app.tr('home.downAmount'), marginTop: 12),
          LoanInput(
            controller: _down,
            suffix: app.amountUnit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: groupedDecimalInputFormatters,
            amountStyle: true,
            error: _overTotalKey() == 'home.downOverPrice',
            onChanged: (_) {
              _loanManual = false;
              _syncAutoLoan();
              setState(() {});
            },
          ),
          if (_overTotalKey() == 'home.downOverPrice')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.tr('home.downOverPrice'),
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.spend),
              ),
            ),
          LoanLabel(app.tr('home.loanAmount'), marginTop: 12),
          LoanInput(
            controller: _principal,
            suffix: app.amountUnit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: groupedDecimalInputFormatters,
            amountStyle: true,
            error: _errors['principal'] == true || _overTotalKey() == 'home.loanOverPrice',
            onChanged: (_) {
              _loanManual = true;
              setState(() {});
            },
          ),
          if (_overTotalKey() == 'home.loanOverPrice')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.tr('home.loanOverPrice'),
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.spend),
              ),
            )
          else
            LoanMuted(app.tr('home.loanHint'), fontSize: 12),
          LoanLabel(app.tr('home.rate'), marginTop: 12),
          LoanInput(controller: _rate, suffix: '%', error: _errors['rate'] == true || _rateNotPositive(_rate), onChanged: (_) => setState(() {})),
          if (_rateNotPositive(_rate))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.tr('home.ratePositive'),
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.spend),
              ),
            ),
          LoanLabel(app.tr('home.term'), marginTop: 12),
          LoanTermSelect(
            value: _years.text.trim().isEmpty ? '1' : _years.text.trim(),
            maxYears: _termMaxYears(),
            title: app.tr('home.term'),
            error: _errors['term'] == true,
            labelBuilder: (y) => app.tr('home.yearsN', {'n': y}),
            onChanged: (y) {
              _years.text = y;
              _months.text = '0';
              setState(() {});
            },
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
            suffix: app.amountUnit,
            error: _errors['principal'] == true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: groupedDecimalInputFormatters,
            amountStyle: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [500000, 1000000, 1500000, 2000000].map((v) {
              final label = app.wanQuickLabel(v ~/ 10000);
              return LoanQuickChip(
                label: label,
                selected: _principalChipSelected(v),
                onTap: () {
                  _principal.text = formatGroupedAmount('$v');
                  setState(() {});
                },
              );
            }).toList(),
          ),
          LoanLabel(app.tr('home.rate'), marginTop: 14),
          LoanInput(controller: _rate, suffix: '%', error: _errors['rate'] == true || _rateNotPositive(_rate), onChanged: (_) => setState(() {})),
          if (_rateNotPositive(_rate))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.tr('home.ratePositive'),
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.spend),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['3.1', '3.85', '4.2', '4.9']
                .map(
                  (v) => LoanQuickChip(
                    label: '$v%',
                    selected: _rateChipSelected(v),
                    onTap: () {
                      _rate.text = v;
                      setState(() {});
                    },
                  ),
                )
                .toList(),
          ),
          LoanLabel(app.tr('home.term'), marginTop: 14),
          LoanTermSelect(
            value: _years.text.trim().isEmpty ? '1' : _years.text.trim(),
            maxYears: _termMaxYears(),
            title: app.tr('home.term'),
            error: _errors['term'] == true,
            labelBuilder: (y) => app.tr('home.yearsN', {'n': y}),
            onChanged: (y) {
              _years.text = y;
              _months.text = '0';
              setState(() {});
            },
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
