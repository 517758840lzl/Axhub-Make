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

/** 首页实时摘要。舍入与 computeLoan 相同，但不生成逐期明细。 */
export interface LoanSummary {
  input: CalcInput;
  monthlyPayment: number;
  firstMonthPayment: number;
  totalInterest: number;
  totalPayment: number;
}

type Walked = { first: number; last: number; interest: number };

export function summarizeLoan(input: CalcInput): LoanSummary {
  if (input.category === 'dual' && input.parts?.length === 2) {
    return summarizeDual(input);
  }
  const { principal: P, annualRatePercent, termMonths: n } = input;
  const r = annualRatePercent / 100 / 12;
  if (P <= 0 || n <= 0) throw new Error('invalid');
  if (input.mode === 'equal-payment') {
    const monthly = monthlyInstallment(P, r, n);
    const walked = walkEqualPayment(P, r, n, monthly, null);
    return {
      input,
      monthlyPayment: monthly,
      firstMonthPayment: walked.first,
      totalInterest: round2(walked.interest),
      totalPayment: round2(P + walked.interest),
    };
  }
  const walked = walkEqualPrincipal(P, r, n, null);
  return {
    input,
    monthlyPayment: walked.first,
    firstMonthPayment: walked.first,
    totalInterest: round2(walked.interest),
    totalPayment: round2(P + walked.interest),
  };
}

function summarizeDual(input: CalcInput): LoanSummary {
  const parts = input.parts;
  if (!parts || parts.length !== 2) throw new Error('invalid dual');
  const a = summarizeLoan(partToInput(parts[0], 0));
  const b = summarizeLoan(partToInput(parts[1], 1));
  const principal = round2(parts[0].principal + parts[1].principal);
  const totalInterest = round2(a.totalInterest + b.totalInterest);
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
    totalInterest,
    totalPayment: round2(principal + totalInterest),
  };
}

function walkEqualPayment(
  P: number,
  r: number,
  n: number,
  monthly: number,
  schedule: AmortizationRow[] | null,
): Walked {
  let balance = P;
  let totalInterest = 0;
  let first = monthly;
  let last = monthly;
  for (let period = 1; period <= n; period += 1) {
    const interest = r === 0 ? 0 : round2(balance * r);
    let principalPart = round2(monthly - interest);
    if (period === n) principalPart = round2(balance);
    const payment = round2(principalPart + interest);
    balance = round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    if (period === 1) first = payment;
    last = payment;
    schedule?.push({ period, payment, principal: principalPart, interest, balance });
  }
  return { first, last, interest: totalInterest };
}

function walkEqualPrincipal(
  P: number,
  r: number,
  n: number,
  schedule: AmortizationRow[] | null,
): Walked {
  const monthlyPrincipal = P / n;
  let balance = P;
  let totalInterest = 0;
  let first = 0;
  let last = 0;
  for (let period = 1; period <= n; period += 1) {
    const interest = r === 0 ? 0 : round2(balance * r);
    const principalPart = round2(period === n ? balance : monthlyPrincipal);
    const payment = round2(principalPart + interest);
    balance = round2(balance - principalPart);
    if (balance < 0) balance = 0;
    totalInterest += interest;
    if (period === 1) first = payment;
    last = payment;
    schedule?.push({ period, payment, principal: principalPart, interest, balance });
  }
  return { first, last, interest: totalInterest };
}

function monthlyInstallment(P: number, r: number, n: number): number {
  let monthly = 0;
  if (r === 0) monthly = P / n;
  else {
    const pow = (1 + r) ** n;
    monthly = (P * r * pow) / (pow - 1);
  }
  return round2(monthly);
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
  const monthly = monthlyInstallment(P, r, n);
  const schedule: AmortizationRow[] = [];
  const walked = walkEqualPayment(P, r, n, monthly, schedule);
  return {
    input,
    monthlyPayment: monthly,
    firstMonthPayment: walked.first,
    lastMonthPayment: walked.last,
    totalInterest: round2(walked.interest),
    totalPayment: round2(P + walked.interest),
    schedule,
  };
}

function computeEqualPrincipal(P: number, r: number, n: number, input: CalcInput): CalcResult {
  const schedule: AmortizationRow[] = [];
  const walked = walkEqualPrincipal(P, r, n, schedule);
  return {
    input,
    monthlyPayment: walked.first,
    firstMonthPayment: walked.first,
    lastMonthPayment: walked.last,
    totalInterest: round2(walked.interest),
    totalPayment: round2(P + walked.interest),
    schedule,
  };
}

/** @deprecated 界面请用 i18n modeMessageKey；保留给非 UI 调用 */
export function modeLabel(mode: RepaymentMode): string {
  return mode === 'equal-payment' ? 'equal-payment' : 'equal-principal';
}
