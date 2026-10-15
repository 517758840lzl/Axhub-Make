import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  htmlLang,
  translate,
  type MessageKey,
  type TranslateFn,
} from './lib/i18n';
import type {
  AppSettings,
  CalcResult,
  ManualLedgerEntry,
  SavedCalculation,
  SavingsGoal,
  UserProfile,
} from './lib/types';
import {
  clearBusinessData,
  exportAllData,
  getCalculations,
  getCompareIds,
  getLedgerEntries,
  getProfile,
  getSettings,
  getSavingsGoals,
  saveCalculations,
  saveCompareIds,
  saveLedgerEntries,
  saveProfile,
  saveSettings,
  saveSavingsGoals,
  seedIfNeeded,
} from './lib/storage';

type AppContextValue = {
  profile: UserProfile;
  settings: AppSettings;
  calculations: SavedCalculation[];
  ledgerEntries: ManualLedgerEntry[];
  savingsGoals: SavingsGoal[];
  compareIds: string[];
  pendingResult: CalcResult | null;
  setPendingResult: (r: CalcResult | null) => void;
  toast: string | null;
  showToast: (msg: string) => void;
  t: TranslateFn;
  refresh: () => void;
  updateProfile: (p: UserProfile) => void;
  updateSettings: (s: AppSettings) => void;
  persistCalculations: (list: SavedCalculation[]) => void;
  persistLedger: (list: ManualLedgerEntry[]) => void;
  persistSavings: (list: SavingsGoal[]) => void;
  persistCompareIds: (ids: string[]) => void;
  addToCompare: (id: string) => boolean;
  clearBusiness: () => void;
  exportData: () => void;
};

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  seedIfNeeded();
  const [profile, setProfileState] = useState(getProfile);
  const [settings, setSettingsState] = useState(getSettings);
  const [calculations, setCalculations] = useState(getCalculations);
  const [ledgerEntries, setLedgerEntries] = useState(getLedgerEntries);
  const [savingsGoals, setSavingsGoals] = useState(getSavingsGoals);
  const [compareIds, setCompareIds] = useState(getCompareIds);
  const [pendingResult, setPendingResult] = useState<CalcResult | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    document.documentElement.lang = htmlLang(settings.locale);
  }, [settings.locale]);

  const t = useCallback<TranslateFn>(
    (key: MessageKey, vars?: Record<string, string | number>) =>
      translate(settings.locale, key, vars),
    [settings.locale],
  );

  const refresh = useCallback(() => {
    setProfileState(getProfile());
    setSettingsState(getSettings());
    setCalculations(getCalculations());
    setLedgerEntries(getLedgerEntries());
    setSavingsGoals(getSavingsGoals());
    setCompareIds(getCompareIds());
  }, []);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2200);
  }, []);

  const updateProfile = useCallback((p: UserProfile) => {
    saveProfile(p);
    setProfileState(p);
  }, []);

  const updateSettings = useCallback((s: AppSettings) => {
    saveSettings(s);
    setSettingsState(s);
  }, []);

  const persistCalculations = useCallback((list: SavedCalculation[]) => {
    saveCalculations(list);
    setCalculations(list);
  }, []);

  const persistLedger = useCallback((list: ManualLedgerEntry[]) => {
    saveLedgerEntries(list);
    setLedgerEntries(list);
  }, []);

  const persistSavings = useCallback((list: SavingsGoal[]) => {
    saveSavingsGoals(list);
    setSavingsGoals(list);
  }, []);

  const persistCompareIds = useCallback((ids: string[]) => {
    const next = ids.slice(0, 3);
    saveCompareIds(next);
    setCompareIds(next);
  }, []);

  const addToCompare = useCallback(
    (id: string) => {
      if (compareIds.includes(id)) return true;
      if (compareIds.length >= 3) return false;
      const next = [...compareIds, id];
      saveCompareIds(next);
      setCompareIds(next);
      return true;
    },
    [compareIds],
  );

  const clearBusiness = useCallback(() => {
    clearBusinessData();
    setCalculations([]);
    setLedgerEntries([]);
    setSavingsGoals([]);
    setCompareIds([]);
  }, []);

  const exportData = useCallback(() => {
    const blob = new Blob([exportAllData()], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `loan-calc-backup-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, []);

  const value = useMemo(
    () => ({
      profile,
      settings,
      calculations,
      ledgerEntries,
      savingsGoals,
      compareIds,
      pendingResult,
      setPendingResult,
      toast,
      showToast,
      t,
      refresh,
      updateProfile,
      updateSettings,
      persistCalculations,
      persistLedger,
      persistSavings,
      persistCompareIds,
      addToCompare,
      clearBusiness,
      exportData,
    }),
    [
      profile,
      settings,
      calculations,
      ledgerEntries,
      savingsGoals,
      compareIds,
      pendingResult,
      toast,
      showToast,
      t,
      refresh,
      updateProfile,
      updateSettings,
      persistCalculations,
      persistLedger,
      persistSavings,
      persistCompareIds,
      addToCompare,
      clearBusiness,
      exportData,
    ],
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp');
  return ctx;
}
