import type { SavedCalculation, SavingsGoal } from './types';

export function savingsEtaLine(
  goal: SavingsGoal,
  money: (n: number) => string,
): string {
  const remaining = goal.target - goal.current;
  if (remaining <= 0.01) {
    return '已达成目标，继续保持即可。';
  }

  const deposits = goal.transactions
    .filter((t) => t.type === 'deposit')
    .sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());

  if (deposits.length === 0) {
    return `还差 ${money(remaining)}；开始存入后，将根据你的节奏估算达标时间。`;
  }

  const totalDep = deposits.reduce((s, t) => s + t.amount, 0);
  const firstAt = new Date(deposits[0].at).getTime();
  const monthsElapsed = Math.max(
    1,
    (Date.now() - firstAt) / (30 * 24 * 60 * 60 * 1000),
  );
  const monthlyRate = totalDep / monthsElapsed;

  if (monthlyRate <= 0) {
    return `还差 ${money(remaining)}；继续存入即可更新预测。`;
  }

  const monthsLeft = remaining / monthlyRate;
  if (monthsLeft > 120) {
    return `还差 ${money(remaining)}；按当前节奏耗时较长，可适当提高存入频率。`;
  }
  if (monthsLeft < 1) {
    return `还差 ${money(remaining)}；按近期节奏，约 1 个月内有望达标。`;
  }
  const rounded = Math.ceil(monthsLeft);
  return `还差 ${money(remaining)}；按近期存入节奏，约 ${rounded} 个月后有望达标。`;
}

export function savingsBufferLine(
  goal: SavingsGoal,
  calculations: SavedCalculation[],
  money: (n: number) => string,
): string {
  const linked = goal.linkedCalcId
    ? calculations.find((c) => c.id === goal.linkedCalcId)
    : undefined;
  const monthly = linked?.result.monthlyPayment;

  const intro = '主流建议预留 3～6 个月月供作应急缓冲。';

  if (!monthly || monthly <= 0) {
    return `${intro} 在计算页保存方案并关联后，可查看相当于几个月月供。`;
  }

  const monthsCovered = goal.current / monthly;
  const m = monthsCovered.toFixed(1);

  if (monthsCovered >= 6) {
    return `${intro} 当前已存约 ${m} 个月月供（方案月供 ${money(monthly)}），高于 6 个月建议。`;
  }
  if (monthsCovered >= 3) {
    return `${intro} 当前已存约 ${m} 个月月供（方案月供 ${money(monthly)}），处于建议区间内。`;
  }
  const gap = (3 - monthsCovered) * monthly;
  return `${intro} 当前约 ${m} 个月月供；距 3 个月下限还差 ${money(gap)}（月供 ${money(monthly)}）。`;
}
