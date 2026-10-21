import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/format.dart';
import '../../data/input_utils.dart';
import '../../data/models.dart';
import '../../data/savings_insights.dart';
import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';
import '../../widgets/loan_widgets.dart';
import '../screen_shared.dart';

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
      final v = parseAmountString(_amount.text);
      if (v == null || v <= 0) return;
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      if (type == 'withdraw' && v > goal2.current) {
        app.showToast(app.tr('savings.insufficient'));
        return;
      }
      final delta = type == 'deposit' ? v : -v;
      final next = goal2.current + delta;
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
          title: savingsName(goal2.name, app),
        ),
        LoanCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoanLabel(goalReached(goal2) ? app.tr('savings.eta.done') : app.tr('savings.progress')),
                    Text(
                      '${app.money(goal2.current)} / ${app.money(goal2.target)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              LoanChip(
                '${goal2.target > 0 ? (goal2.current / goal2.target * 100).clamp(0, 100).toStringAsFixed(0) : '0'}%',
              ),
            ],
          ),
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
                inputFormatters: groupedDecimalInputFormatters,
                amountStyle: true,
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
        LoanSecondaryButton(
          label: app.tr('saved.delete'),
          marginTop: 4,
          onPressed: () async {
            final id = goal2.id;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(app.tr('savings.deleteTitle')),
                content: Text(app.tr('savings.deleteConfirm')),
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
            if (ok != true || !context.mounted) return;
            final latest = context.read<AppState>();
            final next = latest.savingsGoals.where((x) => x.id != id).toList();
            latest.pop();
            await latest.persistSavings(next);
            latest.showToast(latest.tr('saved.deleted'));
          },
        ),
      ],
    );
  }
}
