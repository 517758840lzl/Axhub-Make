import type {
  AmortizationRow,
  CalcInput,
  CalcResult,
  DualLoanPart,
  RepaymentMode,
} from './types';

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export function computeLoan(input: CalcInput): CalcResult {
  if (input.category === 'dual' && input.parts?.length === 2) {
    return computeDualLoan(input);
  }

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

function partToInput(part: DualLoanPart, index: number): CalcInput {
  return {
    principal: part.principal,
    annualRatePercent: part.annualRatePercent,
    termMonths: part.termMonths,
    mode: part.mode,
    category: 'other',
    label: part.label || `Loan ${index + 1}`,
  };
}

export function computeDualLoan(input: CalcInput): CalcResult {
  const parts = input.parts;
  if (!parts || parts.length !== 2) {
    throw new Error('invalid dual');
  }
  const a = computeLoan(partToInput(parts[0], 0));
  const b = computeLoan(partToInput(parts[1], 1));
  const principal = round2(parts[0].principal + parts[1].principal);
  const totalInterest = round2(a.totalInterest + b.totalInterest);
  const longer = a.schedule.length >= b.schedule.length ? a : b;

  return {
    input: {
      ...input,
      principal,
      annualRatePercent: parts[0].annualRatePercent,
      termMonths: Math.max(parts[0].termMonths, parts[1].termMonths),
      mode: parts[0].mode,
      category: 'dual',
      parts,
    },
    monthlyPayment: round2(a.monthlyPayment + b.monthlyPayment),
    firstMonthPayment: round2(a.firstMonthPayment + b.firstMonthPayment),
    lastMonthPayment: round2(
      (a.schedule[a.schedule.length - 1]?.payment ?? 0) +
        (b.schedule[b.schedule.length - 1]?.payment ?? 0),
    ),
    totalInterest,
    totalPayment: round2(principal + totalInterest),
    schedule: longer.schedule,
    partsResults: [a, b],
  };
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

/** @deprecated 界面请用 i18n modeMessageKey；保留给非 UI 调用 */
export function modeLabel(mode: RepaymentMode): string {
  return mode === 'equal-payment' ? 'equal-payment' : 'equal-principal';
}
