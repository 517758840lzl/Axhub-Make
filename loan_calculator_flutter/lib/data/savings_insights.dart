import 'models.dart';

bool goalReached(SavingsGoal goal) => goal.target > 0 && goal.current + 0.01 >= goal.target;

String savingsEtaLine(
  SavingsGoal goal,
  String Function(double) money,
  String Function(String key, [Map<String, String>? vars]) t,
) {
  final remaining = goal.target - goal.current;
  if (goalReached(goal)) {
    return t('savings.eta.done');
  }

  final deposits = goal.transactions.where((tx) => tx.type == 'deposit').toList()
    ..sort((a, b) => a.at.compareTo(b.at));

  if (deposits.isEmpty) {
    return t('savings.eta.start', {'amount': money(remaining)});
  }

  final totalDep = deposits.fold<double>(0, (s, tx) => s + tx.amount);
  final firstAt = DateTime.parse(deposits.first.at);
  final monthsElapsed =
      ((DateTime.now().difference(firstAt).inDays) / 30).clamp(1.0, double.infinity);
  final monthlyRate = totalDep / monthsElapsed;

  if (monthlyRate <= 0) {
    return t('savings.eta.continue', {'amount': money(remaining)});
  }

  final monthsLeft = remaining / monthlyRate;
  if (monthsLeft > 120) {
    return t('savings.eta.long', {'amount': money(remaining)});
  }
  if (monthsLeft < 1) {
    return t('savings.eta.soon', {'amount': money(remaining)});
  }
  return t('savings.eta.months', {
    'amount': money(remaining),
    'months': '${monthsLeft.ceil()}',
  });
}

String savingsBufferLine(
  SavingsGoal goal,
  List<SavedCalculation> calculations,
  String Function(double) money,
  String Function(String key, [Map<String, String>? vars]) t,
) {
  SavedCalculation? linked;
  if (goal.linkedCalcId != null) {
    for (final c in calculations) {
      if (c.id == goal.linkedCalcId) {
        linked = c;
        break;
      }
    }
  }
  final monthly = linked?.result.monthlyPayment;

  if (monthly == null || monthly <= 0) {
    return t('savings.buffer.noLink');
  }

  final monthsCovered = goal.current / monthly;
  final m = monthsCovered.toStringAsFixed(1);

  if (monthsCovered >= 6) {
    return t('savings.buffer.high', {'months': m});
  }
  if (monthsCovered >= 3) {
    return t('savings.buffer.ok', {'months': m});
  }
  final gap = (monthly * 3 - goal.current).clamp(0, double.infinity);
  return t('savings.buffer.low', {
    'months': m,
    'gap': money(gap.toDouble()),
  });
}
