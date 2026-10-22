export type RepaymentMode = 'equal-payment' | 'equal-principal';

export type LoanCategory = 'mortgage' | 'auto' | 'personal' | 'dual' | 'other';

/** One part of a dual loan. */
export interface DualLoanPart {
  principal: number;
  annualRatePercent: number;
  termMonths: number;
  mode: RepaymentMode;
  label?: string;
}

export interface CalcInput {
  principal: number;
  annualRatePercent: number;
  termMonths: number;
  mode: RepaymentMode;
  category: LoanCategory;
  label?: string;
  /** Older auto plans may still store the vehicle price. */
  vehiclePrice?: number;
  /** Older auto plans may still store the down payment. */
  downPayment?: number;
  /** Dual loan: the two parts. */
  parts?: DualLoanPart[];
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
  /** Full result for each part of a dual loan. */
  partsResults?: CalcResult[];
}

export interface SavedCalculation {
  id: string;
  createdAt: string;
  favorite: boolean;
  note: string;
  /** Ledger tags, such as mortgage or payment. */
  tags: string[];
  result: CalcResult;
}

export type LedgerDirection = 'expense' | 'income';

/** A manual ledger entry. */
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

export type ProfileGender = 'male' | 'female' | 'private';

export interface UserProfile {
  nickname: string;
  avatar: string;
  createdAt: string;
  /** Older records without this field display as private. */
  gender?: ProfileGender;
}

export type AppLocale = 'en' | 'es';

export interface AppSettings {
  /** ISO 4217 code, such as USD. */
  currencyCode: string;
  decimals: number;
  theme: 'dark' | 'light' | 'system';
  /** Interface language. */
  locale: AppLocale;
}

export interface AppMeta {
  schemaVersion: number;
  seeded: boolean;
}
