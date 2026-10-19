import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/i18n.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';
import '../../widgets/loan_widgets.dart';
import '../screen_shared.dart';

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
  static const _flexPeriod = 40;
  static const _flexMoney = 100;

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
    final result = context.select<AppState, CalcResult?>((s) => s.pendingResult);
    final locale = context.select<AppState, AppLocale>((s) => s.locale);
    final currencyCode = context.select<AppState, String>((s) => s.settings.currencyCode);
    final decimals = context.select<AppState, int>((s) => s.settings.decimals);
    if (result == null) return const RedirectCalcScreen();

    final app = context.read<AppState>();
    final max = result.schedule.length;
    final rows = _rowsFor(result);
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

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: LoanTopBar(
                  onBack: () => app.pop(),
                  title: app.tr('amort.title'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LoanMuted(app.tr('amort.periods', {'n': '$max'}), fontSize: 13),
                ),
              ),
              DecoratedSliver(
                decoration: BoxDecoration(
                  color: RevolutColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RevolutColors.divider),
                  boxShadow: [RevolutColors.softShadow],
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            _AmortHeaderRow(
                              periodLabel: _view == 'year' ? app.tr('amort.col.year') : app.tr('amort.col.period'),
                              payment: app.tr('amort.col.payment'),
                              principal: app.tr('amort.col.principal'),
                              interest: app.tr('amort.col.interest'),
                              balance: app.tr('amort.col.balance'),
                              style: headStyle,
                            ),
                            const Divider(height: 1, color: RevolutColors.divider),
                          ],
                        ),
                      ),
                    ),
                    SliverFixedExtentList.builder(
                      key: ValueKey('${locale.name}|$currencyCode|$decimals'),
                      itemExtent: _rowH,
                      itemCount: rows.length,
                      addAutomaticKeepAlives: false,
                      itemBuilder: (context, i) {
                        final r = rows[i];
                        return _AmortDataRow(
                          line: _AmortLine(
                            '${r.period}',
                            app.money(r.payment),
                            app.money(r.principal),
                            app.money(r.interest),
                            app.money(r.balance),
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
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
          _cell(periodLabel, _AmortizationScreenState._flexPeriod, style),
          _cell(payment, _AmortizationScreenState._flexMoney, style),
          _cell(principal, _AmortizationScreenState._flexMoney, style),
          _cell(interest, _AmortizationScreenState._flexMoney, style),
          _cell(balance, _AmortizationScreenState._flexMoney, style),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: _deco,
        child: SizedBox(
          height: _AmortizationScreenState._rowH,
          child: Row(
            children: [
              _num(line.period, _AmortizationScreenState._flexPeriod),
              _num(line.payment, _AmortizationScreenState._flexMoney),
              _num(line.principal, _AmortizationScreenState._flexMoney),
              _num(line.interest, _AmortizationScreenState._flexMoney),
              _num(line.balance, _AmortizationScreenState._flexMoney),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _num(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, style: _style, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

Widget _cell(String text, int flex, TextStyle style) {
  return Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: style, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}
