export type RepaymentMode = 'equal-payment' | 'equal-principal';

export type LoanCategory = 'mortgage' | 'auto' | 'personal' | 'dual' | 'other';

/** 通用双贷款中的单笔 */
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
  /** 车贷：车辆成交价 */
  vehiclePrice?: number;
  /** 车贷：首付金额 */
  downPayment?: number;
  /** 双贷款：两笔明细 */
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
  /** 双贷款时各笔完整结果 */
  partsResults?: CalcResult[];
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

export type AppLocale = 'zh-CN' | 'en' | 'es';

export interface AppSettings {
  /** ISO 4217，如 CNY、USD */
  currencyCode: string;
  decimals: number;
  theme: 'dark' | 'light' | 'system';
  /** 界面语言 */
  locale: AppLocale;
}

export interface AppMeta {
  schemaVersion: number;
  seeded: boolean;
}
