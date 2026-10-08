import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/calc.dart';
import '../data/savings_insights.dart';
import '../data/currencies.dart';
import '../data/format.dart';
import '../data/intl_init.dart';
import '../data/models.dart';
import '../data/tags.dart';
import '../state/app_state.dart';
import '../theme/revolut_theme.dart';
import '../widgets/currency_picker.dart';
import '../widgets/donut_chart.dart';
import '../widgets/loan_widgets.dart';
import '../widgets/tag_picker.dart';

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
  final _errors = <String, bool>{};

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _years.dispose();
    _months.dispose();
    super.dispose();
  }

  CalcResult? _preview(AppState app) {
    final p = double.tryParse(_principal.text);
    final r = double.tryParse(_rate.text);
    final termMonths = (int.tryParse(_years.text) ?? 0) * 12 + (int.tryParse(_months.text) ?? 0);
    if (p == null || p <= 0 || r == null || r < 0 || termMonths <= 0) return null;
    try {
      return computeLoan(CalcInput(
        principal: p,
        annualRatePercent: r,
        termMonths: termMonths,
        mode: _mode,
        category: _category,
      ));
    } catch (_) {
      return null;
    }
  }

  void _submit(AppState app) {
    final p = double.tryParse(_principal.text);
    final r = double.tryParse(_rate.text);
    final termMonths = (int.tryParse(_years.text) ?? 0) * 12 + (int.tryParse(_months.text) ?? 0);
    _errors.clear();
    if (p == null || p <= 0) _errors['principal'] = true;
    if (r == null || r < 0) _errors['rate'] = true;
    if (termMonths <= 0) _errors['term'] = true;
    setState(() {});
    if (_errors.isNotEmpty) return;
    try {
      final result = computeLoan(CalcInput(
        principal: p!,
        annualRatePercent: r!,
        termMonths: termMonths,
        mode: _mode,
        category: _category,
      ));
      app.setPendingResult(result);
      app.push(AppRoute.calcResult);
    } catch (_) {
      _errors['principal'] = true;
      _errors['term'] = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final preview = _preview(app);
    final previewPayment = preview == null
        ? null
        : (_mode == RepaymentMode.equalPrincipal ? preview.firstMonthPayment : preview.monthlyPayment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanHeroBanner(
          badges: [
            const LoanHeroBadge(icon: LucideIcons.wifiOff, label: '纯离线'),
            const LoanHeroBadge(icon: LucideIcons.shield, label: '数据在本地'),
            if (app.calculations.isNotEmpty)
              LoanHeroBadge(icon: LucideIcons.clock3, label: '已存 ${app.calculations.length} 条方案'),
          ],
        ),
        const LoanFeatureRow(),
        if (preview != null && previewPayment != null)
          LoanPreviewCard(
            modeLabelText: modeLabel(_mode),
            payment: app.money(previewPayment),
            totalInterest: app.money(preview.totalInterest),
            totalPayment: app.money(preview.totalPayment),
          ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanSectionHead(icon: LucideIcons.landmark, title: '还款方式'),
              LoanSegment(
                options: const [('equal-payment', '等额本息'), ('equal-principal', '等额本金')],
                selected: _mode == RepaymentMode.equalPayment ? 'equal-payment' : 'equal-principal',
                onSelect: (v) => setState(() => _mode = v == 'equal-principal' ? RepaymentMode.equalPrincipal : RepaymentMode.equalPayment),
              ),
              const SizedBox(height: 10),
              LoanMuted(
                _mode == RepaymentMode.equalPayment ? '每月还款额固定，前期利息占比较高。' : '每月本金固定，月供逐月递减。',
                fontSize: 12,
              ),
            ],
          ),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanSectionHead(icon: LucideIcons.wallet, title: '贷款类型'),
              Row(
                children: LoanCategory.values.map((k) {
                  final meta = _loanTypeMeta(k);
                  final active = _category == k;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: k != LoanCategory.other ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: active ? RevolutColors.brandStart.withValues(alpha: 0.12) : RevolutColors.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: active ? RevolutColors.brandStart.withValues(alpha: 0.25) : RevolutColors.divider),
                          ),
                          child: Column(
                            children: [
                              Icon(meta.$1, size: 20, color: active ? RevolutColors.brandSolid : RevolutColors.textSecondary),
                              const SizedBox(height: 6),
                              Text(meta.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? RevolutColors.brandSolid : RevolutColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanSectionHead(icon: LucideIcons.calculator, title: '贷款参数'),
              const LoanLabel('贷款本金'),
              LoanInput(controller: _principal, suffix: '元', error: _errors['principal'] == true, onChanged: (_) => setState(() {})),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [500000, 1000000, 1500000, 2000000].map((v) {
                  return LoanQuickChip(
                    label: v >= 1000000 ? '${v ~/ 1000000} 百万' : '${v ~/ 10000} 万',
                    onTap: () {
                      _principal.text = '$v';
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const LoanLabel('年利率', marginTop: 14),
              LoanInput(controller: _rate, suffix: '%', error: _errors['rate'] == true, onChanged: (_) => setState(() {})),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['3.1', '3.85', '4.2', '4.9'].map((v) => LoanQuickChip(label: '$v%', onTap: () { _rate.text = v; setState(() {}); })).toList(),
              ),
              const LoanLabel('贷款期限', marginTop: 14),
              Row(
                children: [
                  Expanded(child: LoanInput(controller: _years, suffix: '年', error: _errors['term'] == true, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(child: LoanInput(controller: _months, suffix: '月', error: _errors['term'] == true, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['30', '20', '10', '5'].map((y) => LoanQuickChip(label: '$y 年', onTap: () { _years.text = y; _months.text = '0'; setState(() {}); })).toList(),
              ),
            ],
          ),
        ),
        LoanPrimaryButton(label: '开始计算', onPressed: () => _submit(app)),
        const Padding(padding: EdgeInsets.only(top: 12), child: LoanMuted('试算结果仅供参考，不构成任何放贷承诺', center: true, fontSize: 12)),
      ],
    );
  }

  (IconData, String) _loanTypeMeta(LoanCategory k) => switch (k) {
        LoanCategory.mortgage => (LucideIcons.home, '房贷'),
        LoanCategory.auto => (LucideIcons.car, '车贷'),
        LoanCategory.personal => (LucideIcons.shoppingBag, '消费'),
        LoanCategory.other => (LucideIcons.moreHorizontal, '其他'),
      };
}

class CalcResultScreen extends StatelessWidget {
  const CalcResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final result = app.pendingResult;
    if (result == null) return const RedirectCalcScreen();

    final isEqPrincipal = result.input.mode == RepaymentMode.equalPrincipal;
    final hero = isEqPrincipal
        ? '${app.money(result.firstMonthPayment)} → ${app.money(result.lastMonthPayment)}'
        : app.money(result.monthlyPayment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: '计算结果',
          subtitle: modeLabel(result.input.mode),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(isEqPrincipal ? '首月 → 末月还款' : '月供'),
              LoanHeroAmount(hero),
              DonutChart(
                segments: [
                  DonutSegment(value: result.input.principal, color: RevolutColors.brandStart, label: '本金'),
                  DonutSegment(value: result.totalInterest, color: RevolutColors.brandEnd, label: '利息'),
                ],
                centerLabel: app.money(result.totalPayment),
                centerSub: '还款总额',
              ),
              LoanRow(label: '总利息', value: app.money(result.totalInterest), valueColor: RevolutColors.spend),
              LoanRow(label: '贷款本金', value: app.money(result.input.principal)),
            ],
          ),
        ),
        LoanPrimaryButton(label: '查看摊还明细', onPressed: () => app.push(AppRoute.amortization)),
        const SizedBox(height: 8),
        LoanSecondaryButton(
          label: '保存到记账',
          onPressed: () async {
            if (app.pendingResult != null) await app.saveCalcToLedger(app.pendingResult!);
          },
        ),
        const SizedBox(height: 8),
        LoanSecondaryButton(
          label: '为月供设储蓄目标',
          onPressed: () {
            final monthly = result.monthlyPayment;
            app.push(AppRoute.savingsNew, prefill: '${(monthly * 3).round()}');
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
  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final result = app.pendingResult;
    if (result == null) return const RedirectCalcScreen();

    final rows = _yearly ? _yearlyRows(result) : result.schedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: '摊还明细',
          subtitle: '共 ${result.schedule.length} 期',
        ),
        LoanCard(
          child: Column(
            children: [
              LoanSegment(
                options: const [('month', '按月'), ('year', '按年')],
                selected: _yearly ? 'year' : 'month',
                onSelect: (v) => setState(() => _yearly = v == 'year'),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RevolutColors.textSecondary),
                  dataTextStyle: monoStyle(context, size: 11),
                  columns: [
                    DataColumn(label: Text(_yearly ? '年' : '期')),
                    const DataColumn(label: Text('还款')),
                    const DataColumn(label: Text('本金')),
                    const DataColumn(label: Text('利息')),
                    const DataColumn(label: Text('余额')),
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

// --- Savings ---

class _SavingsInsightLine extends StatelessWidget {
  const _SavingsInsightLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.muted,
    this.marginBottom = 10,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool muted;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      height: 1.55,
      color: muted ? RevolutColors.textSecondary : RevolutColors.text,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: style)),
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
          const LoanTopBar(title: '储蓄目标', subtitle: '为月供或缓冲金攒一笔'),
          LoanEmpty(
            icon: const Icon(LucideIcons.piggyBank, size: 40, color: RevolutColors.brandSolid),
            message: '还没有储蓄目标。可从计算结果一键创建，或手动新建。',
            action: LoanPrimaryButton(label: '新建目标', onPressed: () => app.push(AppRoute.savingsNew)),
          ),
        ],
      );
    }

    final totalSaved = goals.fold<double>(0, (s, g) => s + g.current);
    final totalTarget = goals.fold<double>(0, (s, g) => s + g.target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(title: '储蓄目标', subtitle: '${goals.length} 个进行中'),
        LoanStatRow(
          children: [
            LoanStatBox(label: '已存合计', value: app.money(totalSaved)),
            LoanStatBox(label: '目标合计', value: app.money(totalTarget)),
          ],
        ),
        if (app.calculations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LoanMuted('已关联 ${app.calculations.length} 条贷款方案，可在计算结果页快速创建目标', fontSize: 12),
          ),
        ...goals.map((g) {
          final pct = g.target > 0 ? (g.current / g.target * 100).clamp(0, 100) : 0.0;
          return LoanCard(
            onTap: () => app.push(AppRoute.savingsDetail, id: g.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    LoanChip('${pct.toStringAsFixed(0)}%'),
                  ],
                ),
                Center(
                  child: DonutChart(
                    size: 120,
                    stroke: 10,
                    animate: false,
                    segments: [
                      DonutSegment(value: g.current, color: RevolutColors.brandStart, label: '已存'),
                      DonutSegment(value: (g.target - g.current).clamp(0, double.infinity), color: RevolutColors.donutTrack, label: '待存'),
                    ],
                    centerLabel: app.money(g.current),
                    centerSub: '目标 ${app.money(g.target)}',
                  ),
                ),
              ],
            ),
          );
        }),
        ...goals.map(
          (g) => LoanCard(
            backgroundGradient: LoanCard.savingsInsightGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoanLabel('智能提示', marginBottom: 10),
                _SavingsInsightLine(
                  icon: LucideIcons.clock3,
                  iconColor: RevolutColors.text,
                  text: savingsEtaLine(g, app.money),
                  muted: false,
                ),
                _SavingsInsightLine(
                  icon: LucideIcons.shield,
                  iconColor: RevolutColors.textSecondary,
                  text: savingsBufferLine(g, app.calculations, app.money),
                  muted: true,
                  marginBottom: 0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
    _name = TextEditingController(text: '月供缓冲金');
    _target = TextEditingController(text: app.savingsPrefill?.isNotEmpty == true ? app.savingsPrefill : '15000');
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
        LoanTopBar(onBack: () => app.pop(), title: '新建目标'),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanLabel('名称'),
              LoanInput(controller: _name, onChanged: (_) {}),
              const LoanLabel('目标金额', marginTop: 12),
              LoanInput(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) {}),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: '创建',
          onPressed: () async {
            final t = double.tryParse(_target.text);
            if (_name.text.trim().isEmpty || t == null || t <= 0) return;
            final goal = SavingsGoal(
              id: uid('goal'),
              name: _name.text.trim(),
              target: t,
              current: 0,
              deadline: null,
              linkedCalcId: null,
              transactions: [],
              createdAt: DateTime.now().toIso8601String(),
            );
            await app.persistSavings([goal, ...app.savingsGoals]);
            app.showToast('目标已创建');
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
      return EmptyRedirectScreen(message: '目标不存在', onGo: () => app.replaceRoute(AppRoute.savings));
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
        note: type == 'deposit' ? '存入' : '取出',
        at: DateTime.now().toIso8601String(),
      );
      app.persistSavings(app.savingsGoals.map((x) => x.id == goal2.id ? x.copyWith(current: next.toDouble(), transactions: [tx, ...x.transactions]) : x).toList());
      _amount.clear();
      setState(() {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: goal2.name,
          subtitle: '${app.money(goal2.current)} / ${app.money(goal2.target)}',
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanLabel('存入 / 取出'),
              LoanInput(controller: _amount, placeholder: '金额', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) {}),
              const SizedBox(height: 12),
              Row(
                children: [
                  LoanPrimaryButton(label: '存入', flex: true, onPressed: () => addTx('deposit')),
                  const SizedBox(width: 8),
                  LoanSecondaryButton(label: '取出', flex: true, onPressed: () => addTx('withdraw')),
                ],
              ),
            ],
          ),
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanLabel('流水'),
              if (goal2.transactions.isEmpty)
                const LoanMuted('暂无记录', fontSize: 14)
              else
                ...goal2.transactions.map((tx) {
                  return LoanRow(
                    label: '${tx.type == 'deposit' ? '存入' : '取出'} · ${formatShortDate(DateTime.parse(tx.at))}',
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

// --- Ledger ---

class LedgerHomeScreen extends StatefulWidget {
  const LedgerHomeScreen({super.key});

  @override
  State<LedgerHomeScreen> createState() => _LedgerHomeScreenState();
}

class _LedgerHomeScreenState extends State<LedgerHomeScreen> {
  final _q = TextEditingController();
  String? _activeTag;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final allTags = collectAllTags(
      app.calculations.map((c) => c.tags).toList(),
      app.ledgerEntries.map((e) => e.tags).toList(),
    );
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month);
    final monthManual = app.ledgerEntries.where((e) => DateTime.parse(e.createdAt).isAfter(monthStart)).length;
    final favCount = app.calculations.where((c) => c.favorite).length;

    bool matchTag(List<String> tags) => _activeTag == null || tags.contains(_activeTag);
    bool matchQ(String text) => _q.text.trim().isEmpty || text.toLowerCase().contains(_q.text.trim().toLowerCase());

    final filteredCalcs = app.calculations.where((c) => matchTag(c.tags) && (matchQ(c.note) || matchQ(modeLabel(c.result.input.mode)))).toList();
    final filteredManual = app.ledgerEntries.where((e) => matchTag(e.tags) && (matchQ(e.title) || matchQ(e.note))).toList();
    final empty = app.calculations.isEmpty && app.ledgerEntries.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoanTopBar(title: '记账', subtitle: '贷款方案与收支，用标签归类'),
        LoanStatRow(
          triple: true,
          children: [
            LoanStatBox(label: '贷款方案', value: '${app.calculations.length}'),
            LoanStatBox(label: '收支笔数', value: '${app.ledgerEntries.length}'),
            LoanStatBox(label: '本月收支', value: '$monthManual'),
          ],
        ),
        LoanPrimaryButton(label: '记一笔', onPressed: () => app.push(AppRoute.ledgerNew)),
        LoanSecondaryButton(label: '去试算并保存方案', marginTop: 8, onPressed: () => app.goTab(0)),
        if (allTags.isNotEmpty) LoanTagFilter(tags: allTags, activeTag: _activeTag, onSelect: (t) => setState(() => _activeTag = t)),
        LoanInput(controller: _q, placeholder: '搜索标题、备注或还款方式', marginBottom: 12, onChanged: (_) => setState(() {})),
        if (empty)
          LoanEmpty(
            icon: const Icon(LucideIcons.clipboardList, size: 40, color: RevolutColors.brandSolid),
            message: '记一笔日常收支，或在计算页保存贷款方案，都会出现在这里。',
          )
        else ...[
          LoanSectionHead(
            title: '贷款试算',
            trailing: favCount > 0 ? LoanChip('$favCount 个收藏') : null,
          ),
          LoanCard(
            dense: true,
            child: filteredCalcs.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoanMuted('当前筛选下暂无贷款方案', fontSize: 13))
                : Column(
                    children: filteredCalcs.asMap().entries.map((entry) {
                      return _calcListItem(context, app, entry.value, showDivider: entry.key < filteredCalcs.length - 1);
                    }).toList(),
                  ),
          ),
          LoanSectionHead(title: '收支明细', marginTop: 16),
          LoanCard(
            dense: true,
            child: filteredManual.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoanMuted('当前筛选下暂无收支，点上方「记一笔」添加', fontSize: 13))
                : Column(
                    children: filteredManual.asMap().entries.map((entry) {
                      return _manualListItem(context, app, entry.value, showDivider: entry.key < filteredManual.length - 1);
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _calcListItem(BuildContext context, AppState app, SavedCalculation c, {required bool showDivider}) {
    return LoanListItemStack(
      showDivider: showDivider,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => app.push(AppRoute.ledgerCalcDetail, id: c.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanListItemTitle(title: c.note, trailing: const LoanBadgeCalc()),
              const SizedBox(height: 6),
              Text(
                '${modeLabel(c.result.input.mode)} · ${app.money(c.result.monthlyPayment)}/月',
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.textSecondary),
              ),
              TagRow(tags: c.tags),
            ],
          ),
        ),
        LoanListItemActions(
          children: [
            LoanLedgerInlineAction(
              label: c.favorite ? '★' : '☆',
              danger: false,
              onPressed: () => app.persistCalculations(
                app.calculations.map((x) => x.id == c.id ? x.copyWith(favorite: !x.favorite) : x).toList(),
              ),
            ),
            LoanLedgerInlineAction(
              label: '删除',
              onPressed: () {
                app.persistCalculations(app.calculations.where((x) => x.id != c.id).toList());
                app.showToast('已删除');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _manualListItem(BuildContext context, AppState app, ManualLedgerEntry e, {required bool showDivider}) {
    final amountColor = e.direction == LedgerDirection.income ? RevolutColors.income : RevolutColors.spend;
    return LoanListItemStack(
      showDivider: showDivider,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => app.push(AppRoute.ledgerManualDetail, id: e.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanListItemTitle(
                title: e.title,
                trailing: Text(
                  '${e.direction == LedgerDirection.income ? '+' : '−'}${app.money(e.amount)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: amountColor, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatShortDate(DateTime.parse(e.createdAt))}${e.note.isNotEmpty ? ' · ${e.note}' : ''}',
                style: const TextStyle(fontSize: 12, height: 1.5, color: RevolutColors.textSecondary),
              ),
              TagRow(tags: e.tags),
            ],
          ),
        ),
        LoanListItemActions(
          children: [
            LoanLedgerInlineAction(
              label: '删除',
              onPressed: () {
                app.persistLedger(app.ledgerEntries.where((x) => x.id != e.id).toList());
                app.showToast('已删除');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class LedgerNewScreen extends StatefulWidget {
  const LedgerNewScreen({super.key});

  @override
  State<LedgerNewScreen> createState() => _LedgerNewScreenState();
}

class _LedgerNewScreenState extends State<LedgerNewScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  LedgerDirection _direction = LedgerDirection.expense;
  List<String> _tags = const ['日常'];

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: '记一笔', subtitle: '记录与贷款相关的收支'),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanSegment(
                options: const [('expense', '支出'), ('income', '收入')],
                selected: _direction == LedgerDirection.expense ? 'expense' : 'income',
                onSelect: (v) => setState(() => _direction = v == 'income' ? LedgerDirection.income : LedgerDirection.expense),
              ),
              const LoanLabel('标题'),
              LoanInput(controller: _title, placeholder: '如 本月房贷、保险缴费', onChanged: (_) {}),
              const LoanLabel('金额', marginTop: 12),
              LoanInput(controller: _amount, placeholder: '0.00', amountStyle: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {})),
              LoanMuted(
                '预览：${_direction == LedgerDirection.income ? '+' : '−'}${app.money(double.tryParse(_amount.text) ?? 0)}',
                fontSize: 12,
              ),
            ],
          ),
        ),
        TagPicker(value: _tags, onChange: (t) => setState(() => _tags = t)),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanLabel('备注（可选）'),
              LoanInput(controller: _note, onChanged: (_) {}),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: '保存',
          onPressed: () async {
            final n = double.tryParse(_amount.text);
            if (_title.text.trim().isEmpty || n == null || n <= 0 || _tags.isEmpty) return;
            final entry = ManualLedgerEntry(
              id: uid('ledger'),
              createdAt: DateTime.now().toIso8601String(),
              title: _title.text.trim(),
              amount: n,
              direction: _direction,
              tags: _tags,
              note: _note.text.trim(),
            );
            await app.persistLedger([entry, ...app.ledgerEntries]);
            app.showToast('已记账');
            app.replaceRoute(AppRoute.ledger);
          },
        ),
      ],
    );
  }
}

class LedgerCalcDetailScreen extends StatefulWidget {
  const LedgerCalcDetailScreen({super.key});

  @override
  State<LedgerCalcDetailScreen> createState() => _LedgerCalcDetailScreenState();
}

class _LedgerCalcDetailScreenState extends State<LedgerCalcDetailScreen> {
  List<String>? _tags;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = app.calculations.where((c) => c.id == app.detailId).firstOrNull;
    if (item == null) return EmptyRedirectScreen(message: '记录不存在', onGo: () => app.replaceRoute(AppRoute.ledger));

    _tags ??= List<String>.from(item.tags);
    final tags = _tags!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: item.note,
          subtitle: formatShortDateTime(DateTime.parse(item.createdAt)),
        ),
        LoanCard(
          child: Column(
            children: [
              LoanRow(label: '月供', value: app.money(item.result.monthlyPayment)),
              LoanRow(label: '总利息', value: app.money(item.result.totalInterest)),
              LoanRow(label: '还款总额', value: app.money(item.result.totalPayment)),
            ],
          ),
        ),
        TagPicker(
          value: tags,
          onChange: (next) {
            setState(() => _tags = next);
            app.persistCalculations(app.calculations.map((c) => c.id == item.id ? c.copyWith(tags: next) : c).toList());
          },
        ),
        LoanPrimaryButton(
          label: '打开完整结果',
          onPressed: () {
            app.setPendingResult(item.result);
            app.push(AppRoute.calcResult);
          },
        ),
      ],
    );
  }
}

class LedgerManualDetailScreen extends StatefulWidget {
  const LedgerManualDetailScreen({super.key});

  @override
  State<LedgerManualDetailScreen> createState() => _LedgerManualDetailScreenState();
}

class _LedgerManualDetailScreenState extends State<LedgerManualDetailScreen> {
  List<String>? _tags;
  TextEditingController? _note;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final entry = app.ledgerEntries.where((e) => e.id == app.detailId).firstOrNull;
    if (entry == null) return EmptyRedirectScreen(message: '记录不存在', onGo: () => app.replaceRoute(AppRoute.ledger));

    _tags ??= List<String>.from(entry.tags);
    _note ??= TextEditingController(text: entry.note);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(
          onBack: () => app.pop(),
          title: entry.title,
          subtitle: '${entry.direction == LedgerDirection.income ? '收入' : '支出'} · ${formatShortDateTime(DateTime.parse(entry.createdAt))}',
        ),
        LoanCard(
          child: LoanHeroAmount(
            '${entry.direction == LedgerDirection.income ? '+' : '−'}${app.money(entry.amount)}',
            fontSize: 28,
          ),
        ),
        TagPicker(
          value: _tags!,
          onChange: (next) {
            setState(() => _tags = next);
            app.persistLedger(app.ledgerEntries.map((e) => e.id == entry.id ? e.copyWith(tags: next) : e).toList());
          },
        ),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanLabel('备注'),
              LoanInput(
                controller: _note!,
                onChanged: (v) => app.persistLedger(app.ledgerEntries.map((e) => e.id == entry.id ? e.copyWith(tags: _tags!, note: v) : e).toList()),
              ),
            ],
          ),
        ),
        LoanSecondaryButton(
          label: '删除此笔',
          onPressed: () async {
            await app.persistLedger(app.ledgerEntries.where((e) => e.id != entry.id).toList());
            app.showToast('已删除');
            app.replaceRoute(AppRoute.ledger);
          },
        ),
      ],
    );
  }
}

// --- Profile ---

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ledgerCount = app.calculations.length + app.ledgerEntries.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LoanTopBar(title: '我的', subtitle: '本地资料与偏好'),
        LoanCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: RevolutColors.surface2, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(app.profile.avatar, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.profile.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const LoanMuted('数据仅保存在本设备', fontSize: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
        LoanStatRow(
          children: [
            LoanStatBox(label: '记账条目', value: '$ledgerCount'),
            LoanStatBox(label: '储蓄目标', value: '${app.savingsGoals.length}'),
          ],
        ),
        LoanCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              LoanMenuItem(label: '偏好设置', onTap: () => app.push(AppRoute.profileSettings)),
              LoanMenuItem(label: '数据管理', onTap: () => app.push(AppRoute.profileData)),
              LoanMenuItem(label: '关于与隐私', onTap: () => app.push(AppRoute.profileAbout)),
            ],
          ),
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
  late String _currencyCode;
  late TextEditingController _decimals;
  late TextEditingController _nickname;
  late TextEditingController _avatar;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _currencyCode = app.settings.currencyCode;
    _decimals = TextEditingController(text: '${app.settings.decimals}');
    _nickname = TextEditingController(text: app.profile.nickname);
    _avatar = TextEditingController(text: app.profile.avatar);
  }

  @override
  void dispose() {
    _decimals.dispose();
    _nickname.dispose();
    _avatar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: '偏好设置'),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoanLabel('昵称'),
              LoanInput(controller: _nickname, onChanged: (_) {}),
              const LoanLabel('头像（emoji）', marginTop: 12),
              LoanInput(controller: _avatar, onChanged: (_) {}),
              const LoanLabel('小数位', marginTop: 12),
              LoanInput(controller: _decimals, keyboardType: TextInputType.number, onChanged: (_) {}),
            ],
          ),
        ),
        CurrencyPicker(
          compact: true,
          currencyCode: _currencyCode,
          onChange: (code) => setState(() {
            _currencyCode = code;
            _decimals.text = '${getCurrency(code).defaultDecimals}';
          }),
        ),
        LoanPrimaryButton(
          label: '保存',
          onPressed: () async {
            final dec = int.tryParse(_decimals.text.replaceAll(RegExp(r'\D'), '')) ?? 2;
            await app.updateProfile(app.profile.copyWith(nickname: _nickname.text.trim().isEmpty ? '借款人' : _nickname.text.trim(), avatar: _avatar.text));
            await app.updateSettings(AppSettings(currencyCode: _currencyCode, decimals: dec.clamp(0, 4), theme: 'light'));
            app.pop();
          },
        ),
      ],
    );
  }
}

extension on UserProfile {
  UserProfile copyWith({String? nickname, String? avatar}) => UserProfile(
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        createdAt: createdAt,
      );
}

class ProfileDataScreen extends StatelessWidget {
  const ProfileDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: '数据管理'),
        LoanCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              LoanMenuItem(label: '导出 JSON 备份', trailing: const Text('↓'), onTap: () => app.exportData()),
              LoanMenuItem(
                label: '清空计算与储蓄数据',
                trailing: const Text('!'),
                danger: true,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('确认清空'),
                      content: const Text('确定清空所有计算与储蓄数据？偏好设置将保留。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await app.clearBusiness();
                    app.showToast('业务数据已清空');
                  }
                },
              ),
            ],
          ),
        ),
        const LoanMuted('清空仅删除贷款方案、收支记账与储蓄目标，不会重置昵称、货币等偏好。', fontSize: 13),
      ],
    );
  }
}

class ProfileAboutScreen extends StatelessWidget {
  const ProfileAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => context.read<AppState>().pop(), title: '关于与隐私'),
        const LoanCard(
          child: LoanMuted(
            '本原型为离线贷款计算器演示：所有计算在浏览器内完成，数据写入 localStorage，不连接任何服务器，不上传个人信息。'
            '导出文件仅由您自行保存。设计参考 Revolut Mobile 视觉规范，仅供产品原型与后续 App 开发参考。',
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class RedirectCalcScreen extends StatelessWidget {
  const RedirectCalcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().replaceRoute(AppRoute.calc);
    });
    return const SizedBox.shrink();
  }
}

class EmptyRedirectScreen extends StatelessWidget {
  const EmptyRedirectScreen({super.key, required this.message, required this.onGo});

  final String message;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return LoanEmpty(
      message: message,
      action: LoanPrimaryButton(label: '返回', onPressed: onGo),
    );
  }
}
