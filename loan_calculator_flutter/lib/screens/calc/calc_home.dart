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
  LoanCategory _category = LoanCategory.auto;
  final _principal = TextEditingController(text: formatGroupedAmount('100000'));
  final _rate = TextEditingController(text: '4.5');
  final _years = TextEditingController(text: '0');
  final _months = TextEditingController(text: '12');

  // Dual parts
  final _aPrincipal = TextEditingController(text: formatGroupedAmount('12000'));
  final _aRate = TextEditingController(text: '6.5');
  final _aYears = TextEditingController(text: '5');
  final _aMonths = TextEditingController(text: '0');
  RepaymentMode _aMode = RepaymentMode.equalPayment;
  final _bPrincipal = TextEditingController(text: formatGroupedAmount('5000'));
  final _bRate = TextEditingController(text: '8.5');
  final _bYears = TextEditingController(text: '3');
  final _bMonths = TextEditingController(text: '0');
  RepaymentMode _bMode = RepaymentMode.equalPayment;

  final _errors = <String, bool>{};

  static const _loanTypeOrder = [
    LoanCategory.auto,
    LoanCategory.mortgage,
    LoanCategory.personal,
    LoanCategory.dual,
  ];

  /// 各类型自己的本金、利率和期限。车贷默认按月 12 个月，房贷仍是按年 30 年。
  final _formMemory = <LoanCategory, List<String>>{
    LoanCategory.auto: ['100000', '4.5', '0', '12'],
    LoanCategory.mortgage: ['100000', '3.5', '30', '0'],
    LoanCategory.personal: ['8000', '8.5', '3', '0'],
  };

  void _applyGroupedAmounts() {
    for (final c in [_principal, _aPrincipal, _bPrincipal]) {
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

  void _rememberStandard() {
    final slot = _formMemory[_category];
    if (slot == null) return;
    slot[0] = _principal.text.replaceAll(',', '');
    slot[1] = _rate.text;
    slot[2] = _years.text;
    slot[3] = _months.text;
  }

  void _applyStandard(LoanCategory category) {
    final slot = _formMemory[category];
    if (slot == null) return;
    _principal.text = formatGroupedAmount(slot[0]);
    _rate.text = slot[1];
    _years.text = slot[2];
    _months.text = slot[3];
  }

  void _selectCategory(LoanCategory next) {
    if (next == _category) return;
    _rememberStandard();
    _category = next;
    _applyStandard(next);
  }

  @override
  void reassemble() {
    super.reassemble();
    _applyGroupedAmounts();
  }

  @override
  void dispose() {
    for (final c in [
      _principal, _rate, _years, _months,
      _aPrincipal, _aRate, _aYears, _aMonths,
      _bPrincipal, _bRate, _bYears, _bMonths,
    ]) {
      c.dispose();
    }
    super.dispose();
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

  Widget _termField(
    AppState app,
    TextEditingController years,
    TextEditingController months, {
    required int maxYears,
    bool error = false,
  }) {
    return LoanTermSelect(
      years: int.tryParse(years.text) ?? 0,
      months: int.tryParse(months.text) ?? 0,
      maxYears: maxYears,
      title: app.tr('home.term'),
      error: error,
      onChanged: (y, m) {
        years.text = '$y';
        months.text = '$m';
        setState(() {});
      },
    );
  }

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

    final p = _amount(_principal);
    final r = double.tryParse(_rate.text);
    final termMonths = _term(_years, _months);
    if (p == null || p <= 0 || r == null || r <= 0 || termMonths <= 0) return null;

    return summarizeLoan(CalcInput(
      principal: p,
      annualRatePercent: r,
      termMonths: termMonths,
      mode: _mode,
      category: _category,
    ));
  }

  CalcResult? _buildResult() {
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

    final p = _amount(_principal);
    final r = double.tryParse(_rate.text);
    final termMonths = _term(_years, _months);
    if (p == null || p <= 0 || r == null || r <= 0 || termMonths <= 0) return null;

    return computeLoan(CalcInput(
      principal: p,
      annualRatePercent: r,
      termMonths: termMonths,
      mode: _mode,
      category: _category,
    ));
  }

  void _submit(AppState app) {
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
                  for (final (i, k) in _loanTypeOrder.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Builder(builder: (context) {
                        final meta = _loanTypeMeta(k, app);
                        final active = _category == k;
                        return GestureDetector(
                          onTap: () => setState(() => _selectCategory(k)),
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
              }),
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
          _termField(app, years, months, maxYears: 30, error: _errors[errKey] == true),
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
          LoanLabel(app.tr('home.principal')),
          LoanInput(
            controller: _principal,
            suffix: app.amountUnit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: groupedDecimalInputFormatters,
            amountStyle: true,
            error: _errors['principal'] == true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [50000, 100000, 250000, 500000].map((v) {
              return LoanQuickChip(
                label: '${app.amountUnit}${formatGroupedAmount('$v')}',
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
            children: ['3.5', '4.5', '5.5', '6.5']
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
          _termField(app, _years, _months, maxYears: _termMaxYears(), error: _errors['term'] == true),
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
          if (_category == LoanCategory.personal) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [2000, 5000, 8000, 15000].map((v) {
                return LoanQuickChip(
                  label: '${app.amountUnit}${formatGroupedAmount('$v')}',
                  selected: _principalChipSelected(v),
                  onTap: () {
                    _principal.text = formatGroupedAmount('$v');
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ],
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
          LoanLabel(app.tr('home.term'), marginTop: 14),
          _termField(app, _years, _months, maxYears: _termMaxYears(), error: _errors['term'] == true),
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
