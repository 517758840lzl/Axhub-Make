import { computeLoan } from './calc';
import { resolveCurrencyCode } from './currencies';
import type {
  AppMeta,
  AppSettings,
  SavedCalculation,
  SavingsGoal,
  UserProfile,
} from './types';

const PREFIX = 'loan-calc:';

const KEYS = {
  profile: `${PREFIX}profile`,
  settings: `${PREFIX}settings`,
  calculations: `${PREFIX}calculations`,
  savings: `${PREFIX}savings-goals`,
  meta: `${PREFIX}meta`,
} as const;

function readJson<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;
  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function writeJson(key: string, value: unknown) {
  window.localStorage.setItem(key, JSON.stringify(value));
}

export function getMeta(): AppMeta {
  return readJson<AppMeta>(KEYS.meta, { schemaVersion: 1, seeded: false });
}

export function setMeta(meta: AppMeta) {
  writeJson(KEYS.meta, meta);
}

export function getProfile(): UserProfile {
  return readJson<UserProfile>(KEYS.profile, {
    nickname: '借款人',
    avatar: '🧑‍💼',
    createdAt: new Date().toISOString(),
  });
}

export function saveProfile(profile: UserProfile) {
  writeJson(KEYS.profile, profile);
}

export function getSettings(): AppSettings {
  const raw = readJson<AppSettings & { currency?: string }>(KEYS.settings, {
    currencyCode: 'CNY',
    decimals: 2,
    theme: 'light',
  });
  const currencyCode = resolveCurrencyCode(raw);
  const decimals =
    typeof raw.decimals === 'number' ? raw.decimals : 2;
  return {
    currencyCode,
    decimals,
    theme: raw.theme === 'dark' || raw.theme === 'system' ? raw.theme : 'light',
  };
}

export function saveSettings(settings: AppSettings) {
  writeJson(KEYS.settings, settings);
}

export function getCalculations(): SavedCalculation[] {
  return readJson<SavedCalculation[]>(KEYS.calculations, []);
}

export function saveCalculations(list: SavedCalculation[]) {
  writeJson(KEYS.calculations, list);
}

export function getSavingsGoals(): SavingsGoal[] {
  return readJson<SavingsGoal[]>(KEYS.savings, []);
}

export function saveSavingsGoals(list: SavingsGoal[]) {
  writeJson(KEYS.savings, list);
}

export function clearBusinessData() {
  writeJson(KEYS.calculations, []);
  writeJson(KEYS.savings, []);
}

export function exportAllData(): string {
  return JSON.stringify(
    {
      exportedAt: new Date().toISOString(),
      profile: getProfile(),
      settings: getSettings(),
      calculations: getCalculations(),
      savingsGoals: getSavingsGoals(),
    },
    null,
    2,
  );
}

export function seedIfNeeded() {
  const meta = getMeta();
  if (meta.seeded) return;

  const sample = computeLoan({
    principal: 1_000_000,
    annualRatePercent: 4.2,
    termMonths: 360,
    mode: 'equal-payment',
    category: 'mortgage',
    label: '示例房贷',
  });

  saveCalculations([
    {
      id: 'seed-calc-1',
      createdAt: new Date().toISOString(),
      favorite: true,
      note: '示例房贷方案',
      result: sample,
    },
  ]);

  saveSavingsGoals([
    {
      id: 'seed-goal-1',
      name: '月供缓冲金',
      target: 15000,
      current: 5200,
      deadline: null,
      linkedCalcId: 'seed-calc-1',
      createdAt: new Date().toISOString(),
      transactions: [
        {
          id: 'seed-tx-1',
          amount: 5200,
          type: 'deposit',
          note: '初始存入',
          at: new Date().toISOString(),
        },
      ],
    },
  ]);

  setMeta({ schemaVersion: 1, seeded: true });
}
