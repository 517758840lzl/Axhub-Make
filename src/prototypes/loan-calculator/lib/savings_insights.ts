import type { TranslateFn } from './i18n';
import type { SavedCalculation, SavingsGoal } from './types';

export function savingsEtaLine(
  goal: SavingsGoal,
  money: (n: number) => string,
  t: TranslateFn,
): string {
  const remaining = goal.target - goal.current;
  if (remaining <= 0.01) {
    return t('savings.eta.done');
  }

  const deposits = goal.transactions
    .filter((tx) => tx.type === 'deposit')
    .sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());

  if (deposits.length === 0) {
    return t('savings.eta.start', { amount: money(remaining) });
  }

  const totalDep = deposits.reduce((s, tx) => s + tx.amount, 0);
  const firstAt = new Date(deposits[0].at).getTime();
  const monthsElapsed = Math.max(
    1,
    (Date.now() - firstAt) / (30 * 24 * 60 * 60 * 1000),
  );
  const monthlyRate = totalDep / monthsElapsed;

  if (monthlyRate <= 0) {
    return t('savings.eta.continue', { amount: money(remaining) });
  }

  const monthsLeft = remaining / monthlyRate;
  if (monthsLeft > 120) {
    return t('savings.eta.long', { amount: money(remaining) });
  }
  if (monthsLeft < 1) {
    return t('savings.eta.soon', { amount: money(remaining) });
  }
  const rounded = Math.ceil(monthsLeft);
  return t('savings.eta.months', {
    amount: money(remaining),
    months: rounded,
  });
}

export function savingsBufferLine(
  goal: SavingsGoal,
  calculations: SavedCalculation[],
  money: (n: number) => string,
  t: TranslateFn,
): string {
  const linked = goal.linkedCalcId
    ? calculations.find((c) => c.id === goal.linkedCalcId)
    : undefined;
  const monthly = linked?.result.monthlyPayment;

  if (!monthly || monthly <= 0) {
    return t('savings.buffer.noLink');
  }

  const monthsCovered = goal.current / monthly;
  const m = monthsCovered.toFixed(1);

  if (monthsCovered >= 6) {
    return t('savings.buffer.high', { months: m });
  }
  if (monthsCovered >= 3) {
    return t('savings.buffer.ok', { months: m });
  }
  const gap = (3 - monthsCovered) * monthly;
  return t('savings.buffer.low', {
    months: m,
    gap: money(gap),
  });
}
