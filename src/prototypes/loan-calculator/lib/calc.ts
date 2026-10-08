import type { AmortizationRow, CalcInput, CalcResult, RepaymentMode } from './types';

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export function computeLoan(input: CalcInput): CalcResult {
  const { principal: P, annualRatePercent, termMonths: n } = input;
  const r = annualRatePercent / 100 / 12;

  if (P <= 0 || n <= 0) {
    throw new Error('invalid');
  }

  if (input.mode === 'equal-payment') {
    return computeEqualPayment(P, r, n, input);
  }
  return computeEqualPrincipal(P, r, n, input);
}

function computeEqualPayment(P: number, r: number, n: number, input: CalcInput): CalcResult {
  let monthly = 0;
  if (r === 0) {
    monthly = P / n;
  } else {
    const pow = (1 + r) ** n;
    monthly = (P * r * pow) / (pow - 1);
  }
  monthly = round2(monthly);

  const schedule: AmortizationRow[] = [];
  let balance = P;
  let totalInterest = 0;

  for (let period = 1; period <= n; period += 1) {
    const interest = r === 0 ? 0 : round2(balance * r);
    let principalPart = round2(monthly - interest);
    if (period === n) {
      principalPart = round2(balance);
    }
    const payment = round2(principalPart + interest);
    balance = round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    schedule.push({
      period,
      payment,
      principal: principalPart,
      interest,
      balance,
    });
  }

  return {
    input,
    monthlyPayment: monthly,
    firstMonthPayment: schedule[0]?.payment ?? monthly,
    lastMonthPayment: schedule[schedule.length - 1]?.payment ?? monthly,
    totalInterest: round2(totalInterest),
    totalPayment: round2(P + totalInterest),
    schedule,
  };
}

function computeEqualPrincipal(P: number, r: number, n: number, input: CalcInput): CalcResult {
  const monthlyPrincipal = P / n;
  const schedule: AmortizationRow[] = [];
  let balance = P;
  let totalInterest = 0;

  for (let period = 1; period <= n; period += 1) {
    const interest = r === 0 ? 0 : round2(balance * r);
    const principalPart = round2(period === n ? balance : monthlyPrincipal);
    const payment = round2(principalPart + interest);
    balance = round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    schedule.push({
      period,
      payment,
      principal: principalPart,
      interest,
      balance,
    });
  }

  const first = schedule[0]?.payment ?? 0;
  const last = schedule[schedule.length - 1]?.payment ?? 0;

  return {
    input,
    monthlyPayment: first,
    firstMonthPayment: first,
    lastMonthPayment: last,
    totalInterest: round2(totalInterest),
    totalPayment: round2(P + totalInterest),
    schedule,
  };
}

export function modeLabel(mode: RepaymentMode): string {
  return mode === 'equal-payment' ? '等额本息' : '等额本金';
}
