import { computeLoan } from './calc';
import { resolveCurrencyCode } from './currencies';
import { defaultTagsForCategory, normalizeTagList } from './tags';
import { isAppLocale } from './i18n';
import type {
  AppMeta,
  AppSettings,
  ManualLedgerEntry,
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
  ledger: `${PREFIX}ledger-entries`,
  compare: `${PREFIX}compare-ids`,
  meta: `${PREFIX}meta`,
} as const;

function normalizeCalculation(c: SavedCalculation): SavedCalculation {
  const tags =
    c.tags?.length
      ? normalizeTagList(c.tags)
      : defaultTagsForCategory(c.result.input.category);
  return { ...c, tags };
}

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
    locale: 'zh-CN',
  });
  const currencyCode = resolveCurrencyCode(raw);
  const decimals =
    typeof raw.decimals === 'number' ? raw.decimals : 2;
  return {
    currencyCode,
    decimals,
    theme: raw.theme === 'dark' || raw.theme === 'system' ? raw.theme : 'light',
    locale: isAppLocale(raw.locale) ? raw.locale : 'zh-CN',
  };
}

export function saveSettings(settings: AppSettings) {
  writeJson(KEYS.settings, settings);
}

export function getCalculations(): SavedCalculation[] {
  const raw = readJson<SavedCalculation[]>(KEYS.calculations, []);
  return raw.map(normalizeCalculation);
}

export function getLedgerEntries(): ManualLedgerEntry[] {
  const raw = readJson<ManualLedgerEntry[]>(KEYS.ledger, []);
  return raw.map((e) => ({
    ...e,
    tags: normalizeTagList(e.tags),
  }));
}

export function saveLedgerEntries(list: ManualLedgerEntry[]) {
  writeJson(KEYS.ledger, list);
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

export function getCompareIds(): string[] {
  const raw = readJson<string[]>(KEYS.compare, []);
  return Array.isArray(raw) ? raw.filter((id) => typeof id === 'string').slice(0, 3) : [];
}

export function saveCompareIds(ids: string[]) {
  writeJson(KEYS.compare, ids.slice(0, 3));
}

export function clearBusinessData() {
  writeJson(KEYS.calculations, []);
  writeJson(KEYS.savings, []);
  writeJson(KEYS.ledger, []);
  writeJson(KEYS.compare, []);
}

export function exportAllData(): string {
  return JSON.stringify(
    {
      exportedAt: new Date().toISOString(),
      profile: getProfile(),
      settings: getSettings(),
      calculations: getCalculations(),
      ledgerEntries: getLedgerEntries(),
      savingsGoals: getSavingsGoals(),
    },
    null,
    2,
  );
}

export function seedIfNeeded() {
  const meta = getMeta();
  if (meta.seeded) {
    if ((meta.schemaVersion ?? 1) < 2) {
      const calcs = getCalculations();
      const hasAuto = calcs.some((c) => c.result.input.category === 'auto');
      if (!hasAuto) {
        const auto = computeLoan({
          principal: 126_000,
          annualRatePercent: 4.5,
          termMonths: 36,
          mode: 'equal-payment',
          category: 'auto',
          label: '示例车贷',
          vehiclePrice: 180_000,
          downPayment: 54_000,
        });
        const next = [
          ...calcs,
          {
            id: 'seed-calc-2',
            createdAt: new Date().toISOString(),
            favorite: false,
            note: '示例车贷方案',
            tags: ['车贷'],
            result: auto,
          },
        ];
        saveCalculations(next);
        const ids = getCompareIds();
        if (ids.length < 2 && next.length >= 2) {
          saveCompareIds([next[0].id, next[next.length - 1].id].slice(0, 3));
        }
      }
      setMeta({ ...meta, schemaVersion: 2 });
    }
    return;
  }

  const mortgage = computeLoan({
    principal: 1_000_000,
    annualRatePercent: 3.6,
    termMonths: 360,
    mode: 'equal-payment',
    category: 'mortgage',
    label: '示例房贷',
  });

  const auto = computeLoan({
    principal: 126_000,
    annualRatePercent: 4.5,
    termMonths: 36,
    mode: 'equal-payment',
    category: 'auto',
    label: '示例车贷',
    vehiclePrice: 180_000,
    downPayment: 54_000,
  });

  saveCalculations([
    {
      id: 'seed-calc-1',
      createdAt: new Date().toISOString(),
      favorite: true,
      note: '示例房贷方案',
      tags: ['房贷', '月供'],
      result: mortgage,
    },
    {
      id: 'seed-calc-2',
      createdAt: new Date().toISOString(),
      favorite: false,
      note: '示例车贷方案',
      tags: ['车贷'],
      result: auto,
    },
  ]);

  saveCompareIds(['seed-calc-1', 'seed-calc-2']);

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

  setMeta({ schemaVersion: 2, seeded: true });
}
