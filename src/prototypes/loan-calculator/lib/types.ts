export type RepaymentMode = 'equal-payment' | 'equal-principal';

export type LoanCategory = 'mortgage' | 'auto' | 'personal' | 'other';

export interface CalcInput {
  principal: number;
  annualRatePercent: number;
  termMonths: number;
  mode: RepaymentMode;
  category: LoanCategory;
  label?: string;
}

export interface AmortizationRow {
  period: number;
  payment: number;
  principal: number;
  interest: number;
  balance: number;
}

export interface CalcResult {
  input: CalcInput;
  monthlyPayment: number;
  firstMonthPayment: number;
  lastMonthPayment: number;
  totalInterest: number;
  totalPayment: number;
  schedule: AmortizationRow[];
}

export interface SavedCalculation {
  id: string;
  createdAt: string;
  favorite: boolean;
  note: string;
  /** 记账标签，如 房贷、月供 */
  tags: string[];
  result: CalcResult;
}

export type LedgerDirection = 'expense' | 'income';

/** 手动手收支条目（与贷款方案并列展示在记账 Tab） */
export interface ManualLedgerEntry {
  id: string;
  createdAt: string;
  title: string;
  amount: number;
  direction: LedgerDirection;
  tags: string[];
  note: string;
}

export interface SavingsTransaction {
  id: string;
  amount: number;
  type: 'deposit' | 'withdraw';
  note: string;
  at: string;
}

export interface SavingsGoal {
  id: string;
  name: string;
  target: number;
  current: number;
  deadline: string | null;
  linkedCalcId: string | null;
  transactions: SavingsTransaction[];
  createdAt: string;
}

export interface UserProfile {
  nickname: string;
  avatar: string;
  createdAt: string;
}

export interface AppSettings {
  /** ISO 4217，如 CNY、USD */
  currencyCode: string;
  decimals: number;
  theme: 'dark' | 'light' | 'system';
}

export interface AppMeta {
  schemaVersion: number;
  seeded: boolean;
}
