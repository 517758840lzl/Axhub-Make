import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
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
  getLedgerEntries,
  getProfile,
  getSettings,
  getSavingsGoals,
  saveCalculations,
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
  pendingResult: CalcResult | null;
  setPendingResult: (r: CalcResult | null) => void;
  toast: string | null;
  showToast: (msg: string) => void;
  refresh: () => void;
  updateProfile: (p: UserProfile) => void;
  updateSettings: (s: AppSettings) => void;
  persistCalculations: (list: SavedCalculation[]) => void;
  persistLedger: (list: ManualLedgerEntry[]) => void;
  persistSavings: (list: SavingsGoal[]) => void;
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
  const [pendingResult, setPendingResult] = useState<CalcResult | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const refresh = useCallback(() => {
    setProfileState(getProfile());
    setSettingsState(getSettings());
    setCalculations(getCalculations());
    setLedgerEntries(getLedgerEntries());
    setSavingsGoals(getSavingsGoals());
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

  const clearBusiness = useCallback(() => {
    clearBusinessData();
    setCalculations([]);
    setLedgerEntries([]);
    setSavingsGoals([]);
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
      pendingResult,
      setPendingResult,
      toast,
      showToast,
      refresh,
      updateProfile,
      updateSettings,
      persistCalculations,
      persistLedger,
      persistSavings,
      clearBusiness,
      exportData,
    }),
    [
      profile,
      settings,
      calculations,
      ledgerEntries,
      savingsGoals,
      pendingResult,
      toast,
      showToast,
      refresh,
      updateProfile,
      updateSettings,
      persistCalculations,
      persistLedger,
      persistSavings,
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
