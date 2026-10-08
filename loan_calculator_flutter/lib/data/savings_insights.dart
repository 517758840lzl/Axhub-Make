import 'models.dart';

String savingsEtaLine(SavingsGoal goal, String Function(double) money) {
  final remaining = goal.target - goal.current;
  if (remaining <= 0.01) {
    return '已达成目标，继续保持即可。';
  }

  final deposits = goal.transactions
      .where((t) => t.type == 'deposit')
      .toList()
    ..sort((a, b) => a.at.compareTo(b.at));

  if (deposits.isEmpty) {
    return '还差 ${money(remaining)}；开始存入后，将根据你的节奏估算达标时间。';
  }

  final totalDep = deposits.fold<double>(0, (s, t) => s + t.amount);
  final firstAt = DateTime.parse(deposits.first.at);
  final monthsElapsed =
      ((DateTime.now().difference(firstAt).inDays) / 30).clamp(1.0, double.infinity);
  final monthlyRate = totalDep / monthsElapsed;

  if (monthlyRate <= 0) {
    return '还差 ${money(remaining)}；继续存入即可更新预测。';
  }

  final monthsLeft = remaining / monthlyRate;
  if (monthsLeft > 120) {
    return '还差 ${money(remaining)}；按当前节奏耗时较长，可适当提高存入频率。';
  }
  if (monthsLeft < 1) {
    return '还差 ${money(remaining)}；按近期节奏，约 1 个月内有望达标。';
  }
  return '还差 ${money(remaining)}；按近期存入节奏，约 ${monthsLeft.ceil()} 个月后有望达标。';
}

String savingsBufferLine(
  SavingsGoal goal,
  List<SavedCalculation> calculations,
  String Function(double) money,
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
  const intro = '主流建议预留 3～6 个月月供作应急缓冲。';

  if (monthly == null || monthly <= 0) {
    return '$intro 在计算页保存方案并关联后，可查看相当于几个月月供。';
  }

  final monthsCovered = goal.current / monthly;
  final m = monthsCovered.toStringAsFixed(1);

  if (monthsCovered >= 6) {
    return '$intro 当前已存约 $m 个月月供（方案月供 ${money(monthly)}），高于 6 个月建议。';
  }
  if (monthsCovered >= 3) {
    return '$intro 当前已存约 $m 个月月供（方案月供 ${money(monthly)}），处于建议区间内。';
  }
  final gap = (3 - monthsCovered) * monthly;
  return '$intro 当前约 $m 个月月供；距 3 个月下限还差 ${money(gap)}（月供 ${money(monthly)}）。';
}
