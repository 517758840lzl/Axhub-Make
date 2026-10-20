/**
 * @name LoanCalcMate
 */

import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  ArrowLeft,
  Bookmark,
  Calculator,
  Car,
  ChevronRight,
  Clock3,
  Columns2,
  Home,
  Landmark,
  Layers2,
  PieChart,
  PiggyBank,
  Shield,
  ShoppingBag,
  Sparkles,
  Star,
  TableProperties,
  UserRound,
  Wallet,
  type LucideIcon,
} from 'lucide-react';
import { defineHashPageRoute, useHashPage } from '../../common/useHashPage';
import { CurrencyPicker } from './components/CurrencyPicker';
import { CompareCharts, COMPARE_PLAN_COLORS } from './components/CompareCharts';
import { Donut } from './components/Donut';
import { AppProvider, useApp } from './context';
import { computeLoan, summarizeLoan } from './lib/calc';
import { savingsBufferLine, savingsEtaLine } from './lib/savings_insights';
import { getCurrency } from './lib/currencies';
import { formatMoney, parseHashParams, setHashPage, uid } from './lib/format';
import {
  APP_LOCALES,
  categoryMessageKey,
  displayKnownCopy,
  displayNickname,
  displaySavingsName,
  htmlLang,
  isDefaultNickname,
  modeMessageKey,
  translate,
  type TranslateFn,
} from './lib/i18n';
import { defaultAvatar, isDefaultAvatar, resolvedAvatar } from './lib/avatar';
import { privacyPolicyUrl } from './lib/privacy';
import { defaultTagsForCategory } from './lib/tags';
import type {
  AppLocale,
  CalcInput,
  CalcResult,
  DualLoanPart,
  LoanCategory,
  RepaymentMode,
  SavedCalculation,
  SavingsGoal,
} from './lib/types';
import './style.css';

const pageTitle = (key: Parameters<TranslateFn>[0]) => translate('zh-CN', key);

const ROUTE = defineHashPageRoute(
  [
    { id: 'calc', title: pageTitle('tab.calc') },
    { id: 'calc-result', title: pageTitle('result.title') },
    { id: 'amortization', title: pageTitle('amort.title') },
    { id: 'compare', title: pageTitle('compare.title') },
    { id: 'savings', title: pageTitle('tab.savings') },
    { id: 'savings-detail', title: pageTitle('savings.detailTitle') },
    { id: 'savings-new', title: pageTitle('savings.newTitle') },
    { id: 'profile', title: pageTitle('profile.title') },
    { id: 'profile-edit', title: pageTitle('profile.editTitle') },
    { id: 'profile-saved', title: pageTitle('saved.title') },
    { id: 'profile-settings', title: pageTitle('settings.title') },
    { id: 'profile-data', title: pageTitle('data.title') },
    { id: 'profile-about-us', title: pageTitle('aboutUs.title') },
    { id: 'profile-about', title: pageTitle('about.title') },
  ],
  { defaultPageId: 'calc' },
);

const TAB_ROOTS = ['calc', 'savings', 'profile'] as const;

const TAB_NAV: {
  id: (typeof TAB_ROOTS)[number];
  labelKey: 'tab.calc' | 'tab.savings' | 'tab.profile';
  Icon: LucideIcon;
}[] = [
  { id: 'calc', labelKey: 'tab.calc', Icon: Calculator },
  { id: 'savings', labelKey: 'tab.savings', Icon: PiggyBank },
  { id: 'profile', labelKey: 'tab.profile', Icon: UserRound },
];

const LOAN_TYPE_META: Record<
  Exclude<LoanCategory, 'other'>,
  { Icon: LucideIcon }
> = {
  mortgage: { Icon: Home },
  auto: { Icon: Car },
  personal: { Icon: ShoppingBag },
  dual: { Icon: Layers2 },
};

const CATEGORY_PRESETS: Record<
  Exclude<LoanCategory, 'other'>,
  { principal: string; rate: string; years: string; months: string; vehicle?: string; downPct?: string }
> = {
  mortgage: { principal: '1000000', rate: '3.6', years: '30', months: '0' },
  auto: { principal: '126000', rate: '4.5', years: '3', months: '0', vehicle: '180000', downPct: '30' },
  personal: { principal: '50000', rate: '8.5', years: '3', months: '0' },
  dual: { principal: '0', rate: '0', years: '0', months: '0' },
};

const DEFAULT_DUAL_A = {
  principal: '600000',
  rate: '3.1',
  years: '30',
  months: '0',
  mode: 'equal-payment' as RepaymentMode,
};
const DEFAULT_DUAL_B = {
  principal: '400000',
  rate: '4.2',
  years: '25',
  months: '0',
  mode: 'equal-payment' as RepaymentMode,
};

function categoryLabel(c: LoanCategory, t: TranslateFn) {
  return t(categoryMessageKey(c));
}

function modeLabel(mode: RepaymentMode, t: TranslateFn) {
  return t(modeMessageKey(mode));
}

function sameDualPart(a: DualLoanPart, b: DualLoanPart): boolean {
  return (
    a.principal === b.principal &&
    a.annualRatePercent === b.annualRatePercent &&
    a.termMonths === b.termMonths &&
    a.mode === b.mode
  );
}

function sameLoanInput(a: CalcInput, b: CalcInput): boolean {
  if (a.category === 'dual' || b.category === 'dual') {
    if (a.category !== b.category) return false;
    const ap = a.parts;
    const bp = b.parts;
    if (!ap || !bp || ap.length !== 2 || bp.length !== 2) return false;
    return sameDualPart(ap[0], bp[0]) && sameDualPart(ap[1], bp[1]);
  }
  return (
    a.category === b.category &&
    a.mode === b.mode &&
    a.principal === b.principal &&
    a.annualRatePercent === b.annualRatePercent &&
    a.termMonths === b.termMonths &&
    (a.vehiclePrice ?? null) === (b.vehiclePrice ?? null) &&
    (a.downPayment ?? null) === (b.downPayment ?? null)
  );
}

function findSavedByInput(
  list: SavedCalculation[],
  input: CalcInput,
): SavedCalculation | undefined {
  return list.find((c) => sameLoanInput(c.result.input, input));
}

function tabForPage(page: string): (typeof TAB_ROOTS)[number] {
  if (page.startsWith('calc') || page === 'compare') return 'calc';
  if (page.startsWith('savings')) return 'savings';
  return 'profile';
}

function showTabBar(page: string) {
  return (TAB_ROOTS as readonly string[]).includes(page);
}

function insightLines(result: CalcResult, t: TranslateFn): string[] {
  const { input, monthlyPayment, totalInterest, totalPayment } = result;
  if (input.category === 'dual' && result.partsResults?.length === 2) {
    return [
      t('dual.insight', {
        monthly: monthlyPayment.toFixed(0),
        interest: totalInterest.toFixed(0),
        total: totalPayment.toFixed(0),
      }),
      t('result.insight.3', {
        principal: input.principal.toFixed(0),
        rate: `${input.parts?.[0]?.annualRatePercent ?? '-'} / ${input.parts?.[1]?.annualRatePercent ?? '-'}`,
      }),
    ];
  }
  const interestShare = totalPayment > 0 ? (totalInterest / totalPayment) * 100 : 0;
  const years = (input.termMonths / 12).toFixed(input.termMonths % 12 === 0 ? 0 : 1);
  const lines = [
    t('result.insight.1', {
      mode: modeLabel(input.mode, t),
      years,
      share: interestShare.toFixed(0),
    }),
    t('result.insight.2', {
      monthly: monthlyPayment.toFixed(0),
      interest: totalInterest.toFixed(0),
    }),
  ];
  if (input.category === 'auto' && input.vehiclePrice != null && input.downPayment != null) {
    const pct = input.vehiclePrice > 0 ? (input.downPayment / input.vehiclePrice) * 100 : 0;
    lines.unshift(
      t('result.insight.auto', {
        vehicle: input.vehiclePrice.toFixed(0),
        pct: pct.toFixed(0),
        down: input.downPayment.toFixed(0),
        principal: input.principal.toFixed(0),
      }),
    );
  } else {
    lines.push(
      t('result.insight.3', {
        principal: input.principal.toFixed(0),
        rate: input.annualRatePercent,
      }),
    );
  }
  return lines.slice(0, 3);
}

function LoanCalculatorApp() {
  const { page, setPage } = useHashPage(ROUTE);
  const app = useApp();
  const { t } = app;
  const params = parseHashParams();
  const entityId = params.get('id') ?? '';

  const money = (n: number) => formatMoney(n, app.settings);

  useEffect(() => {
    if (
      page === 'ledger' ||
      page === 'ledger-new' ||
      page === 'ledger-detail' ||
      page === 'ledger-manual-detail' ||
      page === 'history' ||
      page === 'history-detail'
    ) {
      setPage('profile-saved');
    }
  }, [page, setPage]);

  const goTab = (tab: (typeof TAB_ROOTS)[number]) => setPage(tab);

  const savePending = (opts?: { quietIfExists?: boolean }) => {
    if (!app.pendingResult) return '';
    const input = app.pendingResult.input;
    const existing = findSavedByInput(app.calculations, input);
    if (existing) {
      if (!opts?.quietIfExists) app.showToast(t('toast.alreadySaved'));
      return existing.id;
    }
    const item: SavedCalculation = {
      id: uid('calc'),
      createdAt: new Date().toISOString(),
      favorite: false,
      note: input.label?.trim() || modeLabel(input.mode, t),
      tags: defaultTagsForCategory(input.category),
      result: app.pendingResult,
    };
    app.persistCalculations([item, ...app.calculations]);
    app.showToast(t('toast.savedProfile'));
    return item.id;
  };

  let content: React.ReactNode = null;

  if (page === 'calc') {
    content = (
      <CalcHome
        onResult={(r) => {
          app.setPendingResult(r);
          setPage('calc-result');
        }}
        money={money}
      />
    );
  } else if (page === 'calc-result' && app.pendingResult) {
    const resultFrom = params.get('from') || 'calc';
    const showSave = !findSavedByInput(app.calculations, app.pendingResult.input);
    content = (
      <CalcResultView
        result={app.pendingResult}
        money={money}
        showSave={showSave}
        onAmortization={() => setHashPage('amortization', { from: 'calc-result' })}
        onSave={() => {
          savePending();
        }}
        onCompare={() => {
          const id = savePending({ quietIfExists: true });
          if (!id) return;
          const already = app.compareIds.includes(id);
          const nextLen = already ? app.compareIds.length : app.compareIds.length + 1;
          const ok = app.addToCompare(id);
          if (!ok) {
            app.showToast(t('compare.max'));
            return;
          }
          if (nextLen < 2) app.showToast(t('compare.addedNeedOne'));
          setHashPage('compare', { from: 'calc-result' });
        }}
        onSavings={() => {
          const monthly = app.pendingResult!.monthlyPayment;
          setHashPage('savings-new', {
            prefill: String(Math.round(monthly * 3)),
          });
        }}
        back={() => setPage(resultFrom)}
      />
    );
  } else if (page === 'calc-result') {
    content = <RedirectCalc />;
  } else if (page === 'amortization' && app.pendingResult) {
    const from = params.get('from') || 'calc-result';
    content = (
      <AmortizationView
        result={app.pendingResult}
        money={money}
        back={() => setPage(from)}
      />
    );
  } else if (page === 'amortization') {
    content = <RedirectCalc />;
  } else if (page === 'compare') {
    const from = params.get('from') || 'calc';
    content = (
      <CompareView
        money={money}
        calculations={app.calculations}
        compareIds={app.compareIds}
        onBack={() => setPage(from)}
        onRemove={(id) => app.persistCompareIds(app.compareIds.filter((x) => x !== id))}
        onAdd={(id) => {
          const already = app.compareIds.includes(id);
          const nextLen = already ? app.compareIds.length : app.compareIds.length + 1;
          const ok = app.addToCompare(id);
          if (!ok) app.showToast(t('compare.max'));
          else if (nextLen < 2) app.showToast(t('compare.addedNeedOne'));
        }}
        onOpenSaved={() => setHashPage('profile-saved', { from: 'compare' })}
      />
    );
  } else if (page === 'savings') {
    content = (
      <SavingsList
        goals={app.savingsGoals}
        calculations={app.calculations}
        money={money}
        calcCount={app.calculations.length}
        onOpen={(id) => setHashPage('savings-detail', { id })}
        onNew={() => setPage('savings-new')}
      />
    );
  } else if (page === 'savings-new') {
    const prefill = params.get('prefill') ?? '';
    content = (
      <SavingsNew
        prefillTarget={prefill}
        onDone={() => setPage('savings')}
        onSave={(goal) => {
          app.persistSavings([goal, ...app.savingsGoals]);
          app.showToast(t('savings.created'));
          setPage('savings');
        }}
      />
    );
  } else if (page === 'savings-detail') {
    const goal = app.savingsGoals.find((g) => g.id === entityId);
    content = goal ? (
      <SavingsDetail
        goal={goal}
        money={money}
        onBack={() => setPage('savings')}
        onUpdate={(g) => {
          app.persistSavings(
            app.savingsGoals.map((x) => (x.id === g.id ? g : x)),
          );
        }}
        onDelete={() => {
          app.persistSavings(app.savingsGoals.filter((x) => x.id !== goal.id));
          app.showToast(t('saved.deleted'));
          setPage('savings');
        }}
      />
    ) : (
      <EmptyRedirect message={t('savings.missing')} onGo={() => setPage('savings')} />
    );
  } else if (page === 'profile') {
    content = (
      <ProfileHome
        profile={app.profile}
        setPage={(p) => {
          if (p === 'profile-saved') setHashPage('profile-saved', { from: 'profile' });
          else setPage(p);
        }}
        savedCount={app.calculations.length}
        savingsCount={app.savingsGoals.length}
      />
    );
  } else if (page === 'profile-saved') {
    const savedFrom = params.get('from') || 'profile';
    content = (
      <SavedList
        calculations={app.calculations}
        money={money}
        compareIds={app.compareIds}
        onBack={() => setPage(savedFrom)}
        onOpen={(item) => {
          app.setPendingResult(item.result);
          setHashPage('calc-result', { from: 'profile-saved' });
        }}
        onDelete={(id) => {
          app.persistCalculations(app.calculations.filter((c) => c.id !== id));
          app.persistCompareIds(app.compareIds.filter((x) => x !== id));
          app.showToast(t('saved.deleted'));
        }}
        onToggleFav={(id) => {
          app.persistCalculations(
            app.calculations.map((c) =>
              c.id === id ? { ...c, favorite: !c.favorite } : c,
            ),
          );
        }}
        onCompare={(id) => {
          const already = app.compareIds.includes(id);
          const nextLen = already ? app.compareIds.length : app.compareIds.length + 1;
          const ok = app.addToCompare(id);
          if (!ok) {
            app.showToast(t('compare.max'));
            return;
          }
          if (nextLen < 2) app.showToast(t('compare.addedNeedOne'));
          setHashPage('compare', { from: 'profile-saved' });
        }}
        onLeaveCompare={(id) => app.persistCompareIds(app.compareIds.filter((x) => x !== id))}
        onOpenCompare={() => setHashPage('compare', { from: 'profile-saved' })}
        onGoCalc={() => setPage('calc')}
      />
    );
  } else if (page === 'profile-edit') {
    content = (
      <ProfileEdit
        profile={app.profile}
        onBack={() => setPage('profile')}
        onSave={app.updateProfile}
      />
    );
  } else if (page === 'profile-settings') {
    content = (
      <ProfileSettings
        settings={app.settings}
        onBack={() => setPage('profile')}
        onSaveSettings={app.updateSettings}
      />
    );
  } else if (page === 'profile-data') {
    content = (
      <ProfileData
        onBack={() => setPage('profile')}
        onExport={app.exportData}
        onClear={() => {
          if (window.confirm(t('data.confirm'))) {
            app.clearBusiness();
            app.showToast(t('data.cleared'));
          }
        }}
      />
    );
  } else if (page === 'profile-about-us') {
    content = (
      <ProfileTextPage
        titleKey="aboutUs.title"
        bodyKey="aboutUs.body"
        onBack={() => setPage('profile')}
      />
    );
  } else if (page === 'profile-about') {
    content = <ProfilePrivacyPage onBack={() => setPage('profile')} />;
  } else {
    content = <RedirectCalc />;
  }

  const activeTab = tabForPage(page);

  return (
    <div className="loan-app" lang={htmlLang(app.settings.locale)}>
      <div className="loan-shell">
        {app.toast ? <div className="loan-toast">{app.toast}</div> : null}
        <main
          className="loan-main"
          onScroll={() => {
            const el = document.activeElement;
            if (el instanceof HTMLElement && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
              el.blur();
            }
          }}
        >
          {content}
        </main>
        {showTabBar(page) ? (
          <nav className="loan-tabbar" aria-label={t('nav.main')}>
            {TAB_NAV.map(({ id, labelKey, Icon }) => (
              <button
                key={id}
                type="button"
                className="loan-tab"
                data-active={activeTab === id}
                onClick={() => goTab(id)}
              >
                <span className="loan-tab-icon" aria-hidden>
                  <Icon size={18} />
                </span>
                <span className="loan-tab-label">{t(labelKey)}</span>
              </button>
            ))}
          </nav>
        ) : null}
      </div>
    </div>
  );
}

function RedirectCalc() {
  const { setPage } = useHashPage(ROUTE);
  useEffect(() => {
    setPage('calc');
  }, [setPage]);
  return null;
}

function EmptyRedirect({ message, onGo }: { message: string; onGo: () => void }) {
  const { t } = useApp();
  return (
    <div className="loan-empty">
      <p>{message}</p>
      <button type="button" className="loan-btn-primary" onClick={onGo}>
        {t('common.back')}
      </button>
    </div>
  );
}

function CalcHome({
  onResult,
  money,
}: {
  onResult: (r: CalcResult) => void;
  money: (n: number) => string;
}) {
  const app = useApp();
  const { t } = app;
  const { setPage } = useHashPage(ROUTE);
  const [category, setCategory] = useState<Exclude<LoanCategory, 'other'>>('mortgage');
  const [mode, setMode] = useState<RepaymentMode>('equal-payment');
  const [principal, setPrincipal] = useState('1000000');
  const [rate, setRate] = useState('3.6');
  const [years, setYears] = useState('30');
  const [months, setMonths] = useState('0');
  const [vehiclePrice, setVehiclePrice] = useState('180000');
  const [downPct, setDownPct] = useState('30');
  const [downPayment, setDownPayment] = useState('54000');
  const [loanManual, setLoanManual] = useState(false);
  const [aPrincipal, setAPrincipal] = useState(DEFAULT_DUAL_A.principal);
  const [aRate, setARate] = useState(DEFAULT_DUAL_A.rate);
  const [aYears, setAYears] = useState(DEFAULT_DUAL_A.years);
  const [aMonths, setAMonths] = useState(DEFAULT_DUAL_A.months);
  const [aMode, setAMode] = useState<RepaymentMode>(DEFAULT_DUAL_A.mode);
  const [bPrincipal, setBPrincipal] = useState(DEFAULT_DUAL_B.principal);
  const [bRate, setBRate] = useState(DEFAULT_DUAL_B.rate);
  const [bYears, setBYears] = useState(DEFAULT_DUAL_B.years);
  const [bMonths, setBMonths] = useState(DEFAULT_DUAL_B.months);
  const [bMode, setBMode] = useState<RepaymentMode>(DEFAULT_DUAL_B.mode);
  const [errors, setErrors] = useState<Record<string, boolean>>({});

  const applyCategory = (next: Exclude<LoanCategory, 'other'>) => {
    setCategory(next);
    setErrors({});
    if (next === 'dual') {
      setAPrincipal(DEFAULT_DUAL_A.principal);
      setARate(DEFAULT_DUAL_A.rate);
      setAYears(DEFAULT_DUAL_A.years);
      setAMonths(DEFAULT_DUAL_A.months);
      setAMode(DEFAULT_DUAL_A.mode);
      setBPrincipal(DEFAULT_DUAL_B.principal);
      setBRate(DEFAULT_DUAL_B.rate);
      setBYears(DEFAULT_DUAL_B.years);
      setBMonths(DEFAULT_DUAL_B.months);
      setBMode(DEFAULT_DUAL_B.mode);
      return;
    }
    const p = CATEGORY_PRESETS[next];
    setPrincipal(p.principal);
    setRate(p.rate);
    setYears(p.years);
    setMonths(p.months);
    if (next === 'auto') {
      setVehiclePrice(p.vehicle || '180000');
      setDownPct(p.downPct || '30');
      const vp = Number(p.vehicle || 180000);
      const pct = Number(p.downPct || 30);
      const dp = Math.round((vp * pct) / 100);
      setDownPayment(String(dp));
      setPrincipal(String(Math.max(0, vp - dp)));
      setLoanManual(false);
    }
  };

  const syncAutoLoan = (vpStr: string, dpStr: string) => {
    if (loanManual) return;
    const vp = Number(vpStr);
    const dp = Number(dpStr);
    if (vp > 0 && dp >= 0 && dp < vp) {
      setPrincipal(String(Math.round(vp - dp)));
    }
  };

  const buildDualParts = (): DualLoanPart[] | null => {
    const aTerm = Number(aYears) * 12 + Number(aMonths);
    const bTerm = Number(bYears) * 12 + Number(bMonths);
    const aP = Number(aPrincipal);
    const bP = Number(bPrincipal);
    const aR = Number(aRate);
    const bR = Number(bRate);
    if (
      !aP ||
      aP <= 0 ||
      !bP ||
      bP <= 0 ||
      Number.isNaN(aR) ||
      aR < 0 ||
      Number.isNaN(bR) ||
      bR < 0 ||
      !aTerm ||
      !bTerm
    ) {
      return null;
    }
    return [
      {
        principal: aP,
        annualRatePercent: aR,
        termMonths: aTerm,
        mode: aMode,
        label: 'A',
      },
      {
        principal: bP,
        annualRatePercent: bR,
        termMonths: bTerm,
        mode: bMode,
        label: 'B',
      },
    ];
  };

  const preview = useMemo(() => {
    try {
      if (category === 'dual') {
        const parts = buildDualParts();
        if (!parts) return null;
        return summarizeLoan({
          principal: parts[0].principal + parts[1].principal,
          annualRatePercent: parts[0].annualRatePercent,
          termMonths: Math.max(parts[0].termMonths, parts[1].termMonths),
          mode: parts[0].mode,
          category: 'dual',
          parts,
          label: categoryLabel('dual', t),
        });
      }
      const P = Number(principal);
      const r = Number(rate);
      const termMonths = Number(years) * 12 + Number(months);
      if (!P || P <= 0 || Number.isNaN(r) || r < 0 || !termMonths) return null;
      const input: CalcInput = {
        principal: P,
        annualRatePercent: r,
        termMonths,
        mode,
        category,
      };
      if (category === 'auto') {
        input.vehiclePrice = Number(vehiclePrice) || undefined;
        input.downPayment = Number(downPayment) || undefined;
      }
      return summarizeLoan(input);
    } catch {
      return null;
    }
  }, [
    principal,
    rate,
    years,
    months,
    mode,
    category,
    vehiclePrice,
    downPayment,
    aPrincipal,
    aRate,
    aYears,
    aMonths,
    aMode,
    bPrincipal,
    bRate,
    bYears,
    bMonths,
    bMode,
    t,
  ]);

  const buildResult = (): CalcResult | null => {
    if (category === 'dual') {
      const parts = buildDualParts();
      const err: Record<string, boolean> = {};
      if (!parts) {
        err.dual = true;
        setErrors(err);
        return null;
      }
      setErrors({});
      try {
        return computeLoan({
          principal: parts[0].principal + parts[1].principal,
          annualRatePercent: parts[0].annualRatePercent,
          termMonths: Math.max(parts[0].termMonths, parts[1].termMonths),
          mode: parts[0].mode,
          category: 'dual',
          parts,
          label: categoryLabel('dual', t),
        });
      } catch {
        setErrors({ dual: true });
        return null;
      }
    }

    const P = Number(principal);
    const r = Number(rate);
    const termMonths = Number(years) * 12 + Number(months);
    const err: Record<string, boolean> = {};
    if (category === 'auto') {
      const vp = Number(vehiclePrice);
      const dp = Number(downPayment);
      if (!vp || vp <= 0) err.vehicle = true;
      if (Number.isNaN(dp) || dp < 0 || dp >= vp) err.down = true;
    }
    if (!P || P <= 0) err.principal = true;
    if (Number.isNaN(r) || r < 0) err.rate = true;
    if (!termMonths || termMonths <= 0) err.term = true;
    setErrors(err);
    if (Object.keys(err).length) return null;

    try {
      return computeLoan({
        principal: P,
        annualRatePercent: r,
        termMonths,
        mode,
        category,
        label: categoryLabel(category, t),
        ...(category === 'auto'
          ? { vehiclePrice: Number(vehiclePrice), downPayment: Number(downPayment) }
          : {}),
      });
    } catch {
      setErrors({ principal: true, term: true });
      return null;
    }
  };

  const submit = () => {
    const result = buildResult();
    if (result) onResult(result);
  };

  const goFeature = (target: 'result' | 'amortization' | 'compare') => {
    if (target === 'compare') {
      setHashPage('compare', { from: 'calc' });
      return;
    }
    const result = buildResult();
    if (!result) {
      app.showToast(t('home.fillFirst'));
      return;
    }
    app.setPendingResult(result);
    if (target === 'result') {
      setHashPage('calc-result', { from: 'calc' });
    } else {
      setHashPage('amortization', { from: 'calc' });
    }
  };

  const previewPayment =
    preview &&
    (category === 'dual' ||
    mode === 'equal-principal' ||
    preview.input.parts?.some((p) => p.mode === 'equal-principal')
      ? preview.firstMonthPayment
      : preview.monthlyPayment);

  const downRatio =
    Number(vehiclePrice) > 0 && Number(downPayment) >= 0
      ? (Number(downPayment) / Number(vehiclePrice)) * 100
      : 0;

  return (
    <>
      <div className="loan-hero-banner loan-hero-compact">
        <h2>{t('home.title')}</h2>
        <p>{t('home.subtitle')}</p>
        <div className="loan-hero-badges">
          <span className="loan-hero-badge">
            <Shield aria-hidden />
            {t('home.badge.local')}
          </span>
          {app.calculations.length > 0 ? (
            <span className="loan-hero-badge">
              <Clock3 aria-hidden />
              {t('home.badge.saved', { count: app.calculations.length })}
            </span>
          ) : null}
        </div>
      </div>

      <div className="loan-card">
        <div className="loan-section-head">
          <Wallet aria-hidden />
          <span>{t('home.loanType')}</span>
        </div>
        <div className="loan-type-grid loan-type-grid-4">
          {(Object.keys(LOAN_TYPE_META) as Exclude<LoanCategory, 'other'>[]).map((k) => {
            const { Icon } = LOAN_TYPE_META[k];
            return (
              <button
                key={k}
                type="button"
                className="loan-type-tile"
                data-active={category === k}
                onClick={() => applyCategory(k)}
              >
                <Icon size={20} />
                {categoryLabel(k, t)}
              </button>
            );
          })}
        </div>
      </div>

      {preview && previewPayment != null ? (
        <div className="loan-preview-card loan-preview-sticky">
          <div className="loan-preview-label">
            <Sparkles size={14} style={{ verticalAlign: -2, marginRight: 4 }} />
            {t('home.preview', {
              mode:
                category === 'dual' ? categoryLabel('dual', t) : modeLabel(mode, t),
            })}
            {category === 'auto'
              ? t('home.previewDown', { pct: downRatio.toFixed(0) })
              : ''}
          </div>
          <div className="loan-preview-amount">{money(previewPayment)}</div>
          <div className="loan-preview-meta">
            <div>
              {t('home.totalInterest')}
              <strong>{money(preview.totalInterest)}</strong>
            </div>
            <div>
              {t('home.totalPayment')}
              <strong>{money(preview.totalPayment)}</strong>
            </div>
          </div>
        </div>
      ) : null}

      {category !== 'dual' ? (
      <div className="loan-card">
        <div className="loan-section-head">
          <Landmark aria-hidden />
          <span>{t('home.repayMode')}</span>
        </div>
        <div className="loan-segment">
          <button
            type="button"
            data-active={mode === 'equal-payment'}
            onClick={() => setMode('equal-payment')}
          >
            {t('mode.equalPayment')}
          </button>
          <button
            type="button"
            data-active={mode === 'equal-principal'}
            onClick={() => setMode('equal-principal')}
          >
            {t('mode.equalPrincipal')}
          </button>
        </div>
      </div>
      ) : null}

      {category === 'dual' ? (
      <div className="loan-card">
        <div className="loan-section-head">
          <Layers2 aria-hidden />
          <span>{t('dual.params')}</span>
        </div>
        {[
          {
            key: 'a',
            title: t('dual.partA'),
            principal: aPrincipal,
            setPrincipal: setAPrincipal,
            rate: aRate,
            setRate: setARate,
            years: aYears,
            setYears: setAYears,
            months: aMonths,
            setMonths: setAMonths,
            partMode: aMode,
            setPartMode: setAMode,
          },
          {
            key: 'b',
            title: t('dual.partB'),
            principal: bPrincipal,
            setPrincipal: setBPrincipal,
            rate: bRate,
            setRate: setBRate,
            years: bYears,
            setYears: setBYears,
            months: bMonths,
            setMonths: setBMonths,
            partMode: bMode,
            setPartMode: setBMode,
          },
        ].map((part) => (
          <div key={part.key} className="loan-dual-part">
            <div className="loan-dual-part-title">{part.title}</div>
            <div className="loan-segment" style={{ marginBottom: 10 }}>
              <button
                type="button"
                data-active={part.partMode === 'equal-payment'}
                onClick={() => part.setPartMode('equal-payment')}
              >
                {t('mode.equalPayment')}
              </button>
              <button
                type="button"
                data-active={part.partMode === 'equal-principal'}
                onClick={() => part.setPartMode('equal-principal')}
              >
                {t('mode.equalPrincipal')}
              </button>
            </div>
            <div className="loan-label">{t('home.principal')}</div>
            <div className="loan-input-wrap">
              <input
                className={`loan-input ${errors.dual ? 'loan-input-error' : ''}`}
                inputMode="decimal"
                value={part.principal}
                onChange={(e) => part.setPrincipal(e.target.value.replace(/[^\d.]/g, ''))}
              />
              <span className="loan-input-suffix">{t('home.unit.yuan')}</span>
            </div>
            <div className="loan-label" style={{ marginTop: 10 }}>
              {t('home.rate')}
            </div>
            <div className="loan-input-wrap">
              <input
                className={`loan-input ${errors.dual ? 'loan-input-error' : ''}`}
                inputMode="decimal"
                value={part.rate}
                onChange={(e) => part.setRate(e.target.value.replace(/[^\d.]/g, ''))}
              />
              <span className="loan-input-suffix">%</span>
            </div>
            <div className="loan-label" style={{ marginTop: 10 }}>
              {t('home.term')}
            </div>
            <div className="loan-term-grid">
              <div className="loan-input-wrap">
                <input
                  className={`loan-input ${errors.dual ? 'loan-input-error' : ''}`}
                  inputMode="numeric"
                  value={part.years}
                  onChange={(e) => part.setYears(e.target.value.replace(/\D/g, ''))}
                />
                <span className="loan-input-suffix">{t('home.year')}</span>
              </div>
              <div className="loan-input-wrap">
                <input
                  className={`loan-input ${errors.dual ? 'loan-input-error' : ''}`}
                  inputMode="numeric"
                  value={part.months}
                  onChange={(e) => part.setMonths(e.target.value.replace(/\D/g, ''))}
                />
                <span className="loan-input-suffix">{t('home.month')}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
      ) : (
      <div className="loan-card">
        <div className="loan-section-head">
          <Calculator aria-hidden />
          <span>{category === 'auto' ? t('home.paramsAuto') : t('home.params')}</span>
        </div>

        {category === 'auto' ? (
          <>
            <div className="loan-label">{t('home.vehiclePrice')}</div>
            <div className="loan-input-wrap">
              <input
                className={`loan-input ${errors.vehicle ? 'loan-input-error' : ''}`}
                inputMode="decimal"
                value={vehiclePrice}
                onChange={(e) => {
                  const v = e.target.value.replace(/[^\d.]/g, '');
                  setVehiclePrice(v);
                  const vp = Number(v);
                  const pct = Number(downPct) || 0;
                  if (vp > 0) {
                    const dp = Math.round((vp * pct) / 100);
                    setDownPayment(String(dp));
                    syncAutoLoan(v, String(dp));
                  }
                }}
              />
              <span className="loan-input-suffix">{t('home.unit.yuan')}</span>
            </div>
            <div className="loan-chip-row">
              {[150_000, 180_000, 250_000, 350_000].map((v) => (
                <button
                  key={v}
                  type="button"
                  className="loan-quick-chip"
                  onClick={() => {
                    setVehiclePrice(String(v));
                    const dp = Math.round((v * (Number(downPct) || 30)) / 100);
                    setDownPayment(String(dp));
                    syncAutoLoan(String(v), String(dp));
                  }}
                >
                  {t('home.wan', { n: v / 10_000 })}
                </button>
              ))}
            </div>

            <div className="loan-label" style={{ marginTop: 14 }}>
              {t('home.downPct')}
            </div>
            <div className="loan-chip-row">
              {['20', '30', '40', '50'].map((pct) => (
                <button
                  key={pct}
                  type="button"
                  className="loan-quick-chip"
                  data-active={downPct === pct}
                  onClick={() => {
                    setDownPct(pct);
                    const vp = Number(vehiclePrice) || 0;
                    const dp = Math.round((vp * Number(pct)) / 100);
                    setDownPayment(String(dp));
                    setLoanManual(false);
                    syncAutoLoan(vehiclePrice, String(dp));
                  }}
                >
                  {pct}%
                </button>
              ))}
            </div>
            <div className="loan-label" style={{ marginTop: 10 }}>
              {t('home.downAmount')}
            </div>
            <div className="loan-input-wrap">
              <input
                className={`loan-input ${errors.down ? 'loan-input-error' : ''}`}
                inputMode="decimal"
                value={downPayment}
                onChange={(e) => {
                  const v = e.target.value.replace(/[^\d.]/g, '');
                  setDownPayment(v);
                  const vp = Number(vehiclePrice) || 0;
                  const dp = Number(v) || 0;
                  if (vp > 0) setDownPct(String(Math.round((dp / vp) * 100)));
                  setLoanManual(false);
                  syncAutoLoan(vehiclePrice, v);
                }}
              />
              <span className="loan-input-suffix">{t('home.unit.yuan')}</span>
            </div>

            <div className="loan-label" style={{ marginTop: 14 }}>
              {t('home.loanAmount')}
            </div>
            <div className="loan-input-wrap">
              <input
                className={`loan-input ${errors.principal ? 'loan-input-error' : ''}`}
                inputMode="decimal"
                value={principal}
                onChange={(e) => {
                  setPrincipal(e.target.value.replace(/[^\d.]/g, ''));
                  setLoanManual(true);
                }}
              />
              <span className="loan-input-suffix">{t('home.unit.yuan')}</span>
            </div>
            <p className="loan-muted" style={{ fontSize: 12, margin: '8px 0 0' }}>
              {t('home.loanHint')}
            </p>
          </>
        ) : (
          <>
            <div className="loan-label">{t('home.principal')}</div>
            <div className="loan-input-wrap">
              <input
                className={`loan-input ${errors.principal ? 'loan-input-error' : ''}`}
                inputMode="decimal"
                value={principal}
                onChange={(e) => setPrincipal(e.target.value.replace(/[^\d.]/g, ''))}
              />
              <span className="loan-input-suffix">{t('home.unit.yuan')}</span>
            </div>
            <div className="loan-chip-row">
              {(category === 'mortgage'
                ? [500_000, 1_000_000, 1_500_000, 2_000_000]
                : [20_000, 50_000, 100_000, 200_000]
              ).map((v) => (
                <button
                  key={v}
                  type="button"
                  className="loan-quick-chip"
                  onClick={() => setPrincipal(String(v))}
                >
                  {v >= 1_000_000
                    ? t('home.million', { n: v / 1_000_000 })
                    : t('home.wan', { n: v / 10_000 })}
                </button>
              ))}
            </div>
          </>
        )}

        <div className="loan-label" style={{ marginTop: 14 }}>
          {t('home.rate')}
        </div>
        <div className="loan-input-wrap">
          <input
            className={`loan-input ${errors.rate ? 'loan-input-error' : ''}`}
            inputMode="decimal"
            value={rate}
            onChange={(e) => setRate(e.target.value.replace(/[^\d.]/g, ''))}
          />
          <span className="loan-input-suffix">%</span>
        </div>
        <div className="loan-chip-row">
          {(category === 'personal' ? ['6.5', '8.5', '12', '15'] : ['3.1', '3.6', '4.2', '4.9']).map(
            (v) => (
              <button
                key={v}
                type="button"
                className="loan-quick-chip"
                onClick={() => setRate(v)}
              >
                {v}%
              </button>
            ),
          )}
        </div>
        <div className="loan-label" style={{ marginTop: 14 }}>
          {t('home.term')}
        </div>
        <div className="loan-term-grid">
          <div className="loan-input-wrap">
            <input
              className={`loan-input ${errors.term ? 'loan-input-error' : ''}`}
              inputMode="numeric"
              value={years}
              placeholder="0"
              onChange={(e) => setYears(e.target.value.replace(/\D/g, ''))}
            />
            <span className="loan-input-suffix">{t('home.year')}</span>
          </div>
          <div className="loan-input-wrap">
            <input
              className={`loan-input ${errors.term ? 'loan-input-error' : ''}`}
              inputMode="numeric"
              value={months}
              placeholder="0"
              onChange={(e) => setMonths(e.target.value.replace(/\D/g, ''))}
            />
            <span className="loan-input-suffix">{t('home.month')}</span>
          </div>
        </div>
        <div className="loan-chip-row">
          {(category === 'mortgage'
            ? [
                ['30', '0'],
                ['20', '0'],
                ['10', '0'],
                ['5', '0'],
              ]
            : [
                ['5', '0'],
                ['3', '0'],
                ['2', '0'],
                ['1', '0'],
              ]
          ).map(([y, m]) => (
            <button
              key={`${y}-${m}`}
              type="button"
              className="loan-quick-chip"
              onClick={() => {
                setYears(y);
                setMonths(m);
              }}
            >
              {t('home.yearsN', { n: y })}
            </button>
          ))}
        </div>
      </div>
      )}

      <div className="loan-feature-row">
        <button
          type="button"
          className="loan-feature-item"
          onClick={() => goFeature('result')}
        >
          <PieChart aria-hidden />
          <div>{t('home.feature.ratio')}</div>
        </button>
        <button
          type="button"
          className="loan-feature-item"
          onClick={() => goFeature('amortization')}
        >
          <TableProperties aria-hidden />
          <div>{t('home.feature.amort')}</div>
        </button>
        <button
          type="button"
          className="loan-feature-item"
          onClick={() => goFeature('compare')}
        >
          <Columns2 aria-hidden />
          <div>{t('home.feature.compare')}</div>
        </button>
      </div>

      <button type="button" className="loan-btn-primary" onClick={submit}>
        {t('home.cta')}
      </button>
      <p className="loan-muted" style={{ fontSize: 12, marginTop: 8, marginBottom: 0, textAlign: 'center' }}>
        {t('home.disclaimer')}
      </p>
    </>
  );
}


function CalcResultView({
  result,
  money,
  showSave,
  onAmortization,
  onSave,
  onCompare,
  onSavings,
  back,
}: {
  result: CalcResult;
  money: (n: number) => string;
  showSave: boolean;
  onAmortization: () => void;
  onSave: () => void;
  onCompare: () => void;
  onSavings: () => void;
  back: () => void;
}) {
  const { t } = useApp();
  const isDual = result.input.category === 'dual' && !!result.partsResults?.length;
  const isEqualPrincipal =
    !isDual && result.input.mode === 'equal-principal';
  const hero = isDual
    ? money(result.firstMonthPayment)
    : isEqualPrincipal
      ? `${money(result.firstMonthPayment)} → ${money(result.lastMonthPayment)}`
      : money(result.monthlyPayment);
  const insights = insightLines(result, t);
  const interestShare =
    result.totalPayment > 0
      ? ((result.totalInterest / result.totalPayment) * 100).toFixed(0)
      : '0';

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={back} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('result.title')}</h1>
      </header>

      <div className="loan-card">
        <p className="loan-muted" style={{ margin: '0 0 12px', fontSize: 13 }}>
          {categoryLabel(result.input.category, t)}
          {!isDual ? ` · ${modeLabel(result.input.mode, t)}` : ''}
        </p>
        <div className="loan-label">
          {isDual
            ? t('dual.combinedMonthly')
            : isEqualPrincipal
              ? t('result.firstLast')
              : t('result.monthly')}
        </div>
        <div className="loan-hero-amount">{hero}</div>
        <Donut
          segments={
            isDual && result.partsResults
              ? [
                  {
                    value: result.partsResults[0].firstMonthPayment,
                    color: '#5b6bff',
                    label: t('dual.partA'),
                    amountText: money(result.partsResults[0].firstMonthPayment),
                  },
                  {
                    value: result.partsResults[1].firstMonthPayment,
                    color: '#9c6bff',
                    label: t('dual.partB'),
                    amountText: money(result.partsResults[1].firstMonthPayment),
                  },
                ]
              : [
                  {
                    value: result.input.principal,
                    color: '#5b6bff',
                    label: t('result.principal'),
                    amountText: money(result.input.principal),
                  },
                  {
                    value: result.totalInterest,
                    color: '#9c6bff',
                    label: t('result.interest'),
                    amountText: money(result.totalInterest),
                  },
                ]
          }
          centerValue={
            isDual && result.partsResults && result.firstMonthPayment > 0
              ? `${((result.partsResults[0].firstMonthPayment / result.firstMonthPayment) * 100).toFixed(0)}%`
              : `${interestShare}%`
          }
          centerCaption={isDual ? t('dual.partA') : t('result.interestShare')}
        />
        <div className="loan-row">
          <span>{t('result.totalPayment')}</span>
          <strong>{money(result.totalPayment)}</strong>
        </div>
        <div className="loan-row">
          <span>{t('result.totalInterest')}</span>
          <span className="loan-text-spend">{money(result.totalInterest)}</span>
        </div>
        {isDual && result.partsResults ? (
          <div className="loan-dual-breakdown">
            <div className="loan-label" style={{ marginTop: 8 }}>
              {t('dual.partBreakdown')}
            </div>
            {result.partsResults.map((part, idx) => (
              <div key={idx} className="loan-dual-breakdown-card">
                <strong>{idx === 0 ? t('dual.partA') : t('dual.partB')}</strong>
                <div className="loan-row">
                  <span>{t('home.principal')}</span>
                  <span>{money(part.input.principal)}</span>
                </div>
                <div className="loan-row">
                  <span>{t('home.rate')}</span>
                  <span>{part.input.annualRatePercent}%</span>
                </div>
                <div className="loan-row">
                  <span>{t('result.monthly')}</span>
                  <span>{money(part.firstMonthPayment)}</span>
                </div>
                <div className="loan-row">
                  <span>{t('result.totalInterest')}</span>
                  <span className="loan-text-spend">{money(part.totalInterest)}</span>
                </div>
              </div>
            ))}
          </div>
        ) : null}
        {result.input.category === 'auto' &&
        result.input.vehiclePrice != null &&
        result.input.downPayment != null ? (
          <>
            <div className="loan-row">
              <span>{t('result.vehicle')}</span>
              <span>{money(result.input.vehiclePrice)}</span>
            </div>
            <div className="loan-row">
              <span>{t('result.downPayment')}</span>
              <span>
                {money(result.input.downPayment)}
                <span className="loan-muted" style={{ marginLeft: 6 }}>
                  (
                  {(
                    (result.input.downPayment / result.input.vehiclePrice) *
                    100
                  ).toFixed(0)}
                  %)
                </span>
              </span>
            </div>
          </>
        ) : null}
      </div>

      <div className="loan-card loan-insight-card">
        <div className="loan-section-head">
          <Sparkles aria-hidden />
          <span>{t('result.insights')}</span>
        </div>
        <ul className="loan-insight-list">
          {insights.map((line) => (
            <li key={line}>{line}</li>
          ))}
        </ul>
      </div>

      <button type="button" className="loan-btn-primary" onClick={onAmortization}>
        {t('result.amort')}
      </button>
      <div style={{ height: 8 }} />
      <button type="button" className="loan-btn-secondary" onClick={onCompare}>
        {t('result.compare')}
      </button>
      {showSave ? (
        <>
          <div style={{ height: 8 }} />
          <button type="button" className="loan-btn-secondary" onClick={onSave}>
            {t('result.save')}
          </button>
        </>
      ) : null}
      <div style={{ height: 8 }} />
      <button type="button" className="loan-btn-secondary" onClick={onSavings}>
        {t('result.savings')}
      </button>
    </>
  );
}

function AmortizationView({
  result,
  money,
  back,
}: {
  result: CalcResult;
  money: (n: number) => string;
  back: () => void;
}) {
  const { t } = useApp();
  const isDual = !!result.partsResults?.length;
  const [partIndex, setPartIndex] = useState(0);
  const activeResult =
    isDual && result.partsResults ? result.partsResults[partIndex] ?? result : result;
  const maxPeriod = activeResult.schedule.length;
  const [viewMode, setViewMode] = useState<'month' | 'year' | 'custom'>('month');
  const [fromPeriod, setFromPeriod] = useState('1');
  const [toPeriod, setToPeriod] = useState(String(Math.min(12, maxPeriod)));

  const clampedRange = useMemo(() => {
    let from = Number(fromPeriod) || 1;
    let to = Number(toPeriod) || maxPeriod;
    from = Math.min(maxPeriod, Math.max(1, Math.floor(from)));
    to = Math.min(maxPeriod, Math.max(1, Math.floor(to)));
    if (from > to) [from, to] = [to, from];
    return { from, to };
  }, [fromPeriod, toPeriod, maxPeriod]);

  const rows = useMemo(() => {
    const schedule = activeResult.schedule;
    if (viewMode === 'year') {
      const byYear: {
        period: number;
        payment: number;
        principal: number;
        interest: number;
        balance: number;
      }[] = [];
      for (let i = 0; i < schedule.length; i += 12) {
        const chunk = schedule.slice(i, i + 12);
        byYear.push({
          period: Math.floor(i / 12) + 1,
          payment: chunk.reduce((s, r) => s + r.payment, 0),
          principal: chunk.reduce((s, r) => s + r.principal, 0),
          interest: chunk.reduce((s, r) => s + r.interest, 0),
          balance: chunk[chunk.length - 1]?.balance ?? 0,
        });
      }
      return byYear;
    }

    if (viewMode === 'custom') {
      return schedule.filter(
        (row) => row.period >= clampedRange.from && row.period <= clampedRange.to,
      );
    }

    return schedule;
  }, [viewMode, activeResult.schedule, clampedRange]);

  const rangeTotals = useMemo(() => {
    if (viewMode !== 'custom' || !rows.length) return null;
    return {
      payment: rows.reduce((s, r) => s + r.payment, 0),
      principal: rows.reduce((s, r) => s + r.principal, 0),
      interest: rows.reduce((s, r) => s + r.interest, 0),
    };
  }, [viewMode, rows]);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={back} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('amort.title')}</h1>
      </header>
      <p className="loan-muted" style={{ fontSize: 13, margin: '0 0 12px' }}>
        {t('amort.periods', { n: maxPeriod })}
      </p>

      <div className="loan-card">
        {isDual ? (
          <div className="loan-segment" style={{ marginBottom: 12 }}>
            <button
              type="button"
              data-active={partIndex === 0}
              onClick={() => {
                setPartIndex(0);
                setFromPeriod('1');
                setToPeriod('12');
                setViewMode('month');
              }}
            >
              {t('dual.partA')}
            </button>
            <button
              type="button"
              data-active={partIndex === 1}
              onClick={() => {
                setPartIndex(1);
                setFromPeriod('1');
                setToPeriod('12');
                setViewMode('month');
              }}
            >
              {t('dual.partB')}
            </button>
          </div>
        ) : null}
        <div className="loan-segment loan-amort-segment">
          <button
            type="button"
            data-active={viewMode === 'month'}
            onClick={() => setViewMode('month')}
          >
            {t('amort.byMonth')}
          </button>
          <button
            type="button"
            data-active={viewMode === 'year'}
            onClick={() => setViewMode('year')}
          >
            {t('amort.byYear')}
          </button>
          <button
            type="button"
            data-active={viewMode === 'custom'}
            onClick={() => setViewMode('custom')}
          >
            {t('amort.byCustom')}
          </button>
        </div>

        {viewMode === 'custom' ? (
          <div className="loan-amort-filter">
            <p className="loan-muted" style={{ fontSize: 12, margin: '0 0 10px' }}>
              {t('amort.rangeHint', { max: maxPeriod })}
            </p>
            <div className="loan-term-grid">
              <div>
                <div className="loan-label">{t('amort.fromPeriod')}</div>
                <div className="loan-input-wrap">
                  <input
                    className="loan-input"
                    inputMode="numeric"
                    value={fromPeriod}
                    onChange={(e) => setFromPeriod(e.target.value.replace(/\D/g, ''))}
                    onBlur={() => setFromPeriod(String(clampedRange.from))}
                  />
                </div>
              </div>
              <div>
                <div className="loan-label">{t('amort.toPeriod')}</div>
                <div className="loan-input-wrap">
                  <input
                    className="loan-input"
                    inputMode="numeric"
                    value={toPeriod}
                    onChange={(e) => setToPeriod(e.target.value.replace(/\D/g, ''))}
                    onBlur={() => setToPeriod(String(clampedRange.to))}
                  />
                </div>
              </div>
            </div>
            <p className="loan-muted" style={{ fontSize: 12, margin: '10px 0 0' }}>
              {t('amort.showing', { n: rows.length })}
            </p>
          </div>
        ) : null}

        {rangeTotals ? (
          <div className="loan-amort-sum">
            <div className="loan-label">{t('amort.rangeSum')}</div>
            <div className="loan-row">
              <span>{t('amort.col.payment')}</span>
              <span>{money(rangeTotals.payment)}</span>
            </div>
            <div className="loan-row">
              <span>{t('amort.col.principal')}</span>
              <span>{money(rangeTotals.principal)}</span>
            </div>
            <div className="loan-row">
              <span>{t('amort.col.interest')}</span>
              <span className="loan-text-spend">{money(rangeTotals.interest)}</span>
            </div>
          </div>
        ) : null}

        <div className="loan-amort-scroll">
          <table className="loan-amort-table">
            <thead>
              <tr>
                <th>
                  {viewMode === 'year' ? t('amort.col.year') : t('amort.col.period')}
                </th>
                <th>{t('amort.col.payment')}</th>
                <th>{t('amort.col.principal')}</th>
                <th>{t('amort.col.interest')}</th>
                <th>{t('amort.col.balance')}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.period}>
                  <td>{row.period}</td>
                  <td>{money(row.payment)}</td>
                  <td>{money(row.principal)}</td>
                  <td>{money(row.interest)}</td>
                  <td>{money(row.balance)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}

function SavingsList({
  goals,
  calculations,
  money,
  calcCount,
  onOpen,
  onNew,
}: {
  goals: SavingsGoal[];
  calculations: SavedCalculation[];
  money: (n: number) => string;
  calcCount: number;
  onOpen: (id: string) => void;
  onNew: () => void;
}) {
  const { t } = useApp();
  const totalSaved = goals.reduce((s, g) => s + g.current, 0);
  const totalTarget = goals.reduce((s, g) => s + g.target, 0);

  if (!goals.length) {
    return (
      <>
        <header className="loan-topbar">
          <div>
            <h1 className="loan-title">{t('savings.title')}</h1>
            <p className="loan-subtitle">{t('savings.subtitle')}</p>
          </div>
        </header>
        <div className="loan-empty">
          <PiggyBank size={40} strokeWidth={1.6} color="#6b5bff" style={{ marginBottom: 12 }} />
          <p>{t('savings.empty')}</p>
          <button type="button" className="loan-btn-primary" onClick={onNew}>
            {t('savings.new')}
          </button>
        </div>
      </>
    );
  }

  return (
    <>
      <header className="loan-topbar">
        <div>
          <h1 className="loan-title">{t('savings.title')}</h1>
          <p className="loan-subtitle">{t('savings.inProgress', { n: goals.length })}</p>
        </div>
      </header>
      <div className="loan-stat-row">
        <div className="loan-stat-box">
          <div className="loan-label">{t('savings.savedTotal')}</div>
          <strong>{money(totalSaved)}</strong>
        </div>
        <div className="loan-stat-box">
          <div className="loan-label">{t('savings.targetTotal')}</div>
          <strong>{money(totalTarget)}</strong>
        </div>
      </div>
      {calcCount > 0 ? (
        <p className="loan-muted" style={{ fontSize: 12, margin: '-4px 0 12px' }}>
          {t('savings.linkedHint', { n: calcCount })}
        </p>
      ) : null}
      {goals.map((g) => {
        const pct = g.target > 0 ? Math.min(100, (g.current / g.target) * 100) : 0;
        const name = displaySavingsName(g.name, t);
        return (
          <div
            key={g.id}
            className="loan-card"
            role="button"
            tabIndex={0}
            onClick={() => onOpen(g.id)}
            onKeyDown={(e) => e.key === 'Enter' && onOpen(g.id)}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <strong>{name}</strong>
              <span className="loan-chip">{pct.toFixed(0)}%</span>
            </div>
            <Donut
              size={120}
              stroke={10}
              segments={[
                {
                  value: g.current,
                  color: '#5b6bff',
                  label: t('savings.done'),
                  amountText: money(g.current),
                },
                {
                  value: Math.max(0, g.target - g.current),
                  color: '#e2e5f0',
                  label: t('savings.todo'),
                  amountText: money(Math.max(0, g.target - g.current)),
                },
              ]}
              centerValue={`${pct.toFixed(0)}%`}
              centerCaption={t('savings.progress')}
              animate={false}
            />
            <div className="loan-savings-insight loan-savings-insight--inline">
              <div className="loan-label" style={{ marginBottom: 10 }}>
                {t('savings.insightsFor', { name })}
              </div>
              <p className="loan-savings-insight-line">
                <Clock3 size={14} style={{ verticalAlign: -2, marginRight: 6 }} aria-hidden />
                {savingsEtaLine(g, money, t)}
              </p>
              <p className="loan-savings-insight-line loan-muted" style={{ marginBottom: 0 }}>
                <Shield size={14} style={{ verticalAlign: -2, marginRight: 6 }} aria-hidden />
                {savingsBufferLine(g, calculations, money, t)}
              </p>
            </div>
          </div>
        );
      })}
      <button type="button" className="loan-fab" aria-label={t('savings.create')} onClick={onNew}>
        +
      </button>
    </>
  );
}

function SavingsNew({
  prefillTarget,
  onSave,
  onDone,
}: {
  prefillTarget: string;
  onSave: (g: SavingsGoal) => void;
  onDone: () => void;
}) {
  const { t } = useApp();
  const [name, setName] = useState(() => t('savings.defaultName'));
  const [target, setTarget] = useState(prefillTarget || '15000');

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onDone} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('savings.new')}</h1>
      </header>
      <div className="loan-card">
        <div className="loan-label">{t('savings.name')}</div>
        <input className="loan-input" value={name} onChange={(e) => setName(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          {t('savings.target')}
        </div>
        <input
          className="loan-input"
          inputMode="decimal"
          value={target}
          onChange={(e) => setTarget(e.target.value.replace(/[^\d.]/g, ''))}
        />
      </div>
      <button
        type="button"
        className="loan-btn-primary"
        onClick={() => {
          const tv = Number(target);
          if (!name.trim() || !tv || tv <= 0) return;
          onSave({
            id: uid('goal'),
            name: name.trim(),
            target: tv,
            current: 0,
            deadline: null,
            linkedCalcId: null,
            transactions: [],
            createdAt: new Date().toISOString(),
          });
        }}
      >
        {t('savings.createCta')}
      </button>
    </>
  );
}

function SavingsDetail({
  goal,
  money,
  onBack,
  onUpdate,
  onDelete,
}: {
  goal: SavingsGoal;
  money: (n: number) => string;
  onBack: () => void;
  onUpdate: (g: SavingsGoal) => void;
  onDelete: () => void;
}) {
  const { t, showToast } = useApp();
  const [amount, setAmount] = useState('');
  const [confirmDelete, setConfirmDelete] = useState(false);
  const amountRef = useRef<HTMLInputElement>(null);

  const addTx = (type: 'deposit' | 'withdraw') => {
    const v = Number(amount);
    if (!v || v <= 0) return;
    amountRef.current?.blur();
    if (type === 'withdraw' && v > goal.current) {
      showToast(t('savings.insufficient'));
      return;
    }
    const delta = type === 'deposit' ? v : -v;
    const next = Math.max(0, goal.current + delta);
    const tx = {
      id: uid('tx'),
      amount: v,
      type,
      note: type === 'deposit' ? t('savings.deposit') : t('savings.withdraw'),
      at: new Date().toISOString(),
    };
    onUpdate({
      ...goal,
      current: next,
      transactions: [tx, ...goal.transactions],
    });
    setAmount('');
  };

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{displaySavingsName(goal.name, t)}</h1>
      </header>
      <div className="loan-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div className="loan-label">{t('savings.progress')}</div>
          <strong>
            {money(goal.current)} / {money(goal.target)}
          </strong>
        </div>
        <span className="loan-chip">
          {goal.target > 0 ? Math.min(100, (goal.current / goal.target) * 100).toFixed(0) : '0'}%
        </span>
      </div>
      <div className="loan-card">
        <div className="loan-label">{t('savings.depositWithdraw')}</div>
        <input
          ref={amountRef}
          className="loan-input"
          inputMode="decimal"
          placeholder={t('savings.amount')}
          value={amount}
          onChange={(e) => setAmount(e.target.value.replace(/[^\d.]/g, ''))}
        />
        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
          <button type="button" className="loan-btn-primary" style={{ flex: 1 }} onClick={() => addTx('deposit')}>
            {t('savings.deposit')}
          </button>
          <button type="button" className="loan-btn-secondary" style={{ flex: 1 }} onClick={() => addTx('withdraw')}>
            {t('savings.withdraw')}
          </button>
        </div>
      </div>
      <div className="loan-card">
        <div className="loan-label">{t('savings.flow')}</div>
        {goal.transactions.length === 0 ? (
          <p className="loan-muted" style={{ fontSize: 14 }}>{t('savings.noTx')}</p>
        ) : (
          goal.transactions.map((tx) => (
            <div key={tx.id} className="loan-row">
              <span>
                {tx.type === 'deposit' ? t('savings.deposit') : t('savings.withdraw')} ·{' '}
                {new Date(tx.at).toLocaleDateString()}
              </span>
              <span className={tx.type === 'deposit' ? 'loan-text-income' : ''}>
                {tx.type === 'deposit' ? '+' : '-'}
                {money(tx.amount)}
              </span>
            </div>
          ))
        )}
      </div>
      <button type="button" className="loan-btn-secondary" onClick={() => setConfirmDelete(true)}>
        {t('saved.delete')}
      </button>
      {confirmDelete ? (
        <div className="loan-dialog-backdrop" role="presentation" onClick={() => setConfirmDelete(false)}>
          <div
            className="loan-dialog"
            role="dialog"
            aria-labelledby="savings-delete-title"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="savings-delete-title">{t('savings.deleteTitle')}</h2>
            <p>{t('savings.deleteConfirm')}</p>
            <div className="loan-dialog-actions">
              <button type="button" onClick={() => setConfirmDelete(false)}>
                {t('common.back')}
              </button>
              <button
                type="button"
                onClick={() => {
                  setConfirmDelete(false);
                  onDelete();
                }}
              >
                {t('saved.delete')}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}

function CompareView({
  money,
  calculations,
  compareIds,
  onBack,
  onRemove,
  onAdd,
  onOpenSaved,
}: {
  money: (n: number) => string;
  calculations: SavedCalculation[];
  compareIds: string[];
  onBack: () => void;
  onRemove: (id: string) => void;
  onAdd: (id: string) => void;
  onOpenSaved: () => void;
}) {
  const { t } = useApp();
  const items = compareIds
    .map((id) => calculations.find((c) => c.id === id))
    .filter(Boolean) as SavedCalculation[];

  const monthlyValues = items.map((c) =>
    c.result.input.mode === 'equal-principal'
      ? c.result.firstMonthPayment
      : c.result.monthlyPayment,
  );

  const metrics: {
    key: string;
    label: string;
    values: number[];
    lowerBetter: boolean;
    format: 'money' | 'pct' | 'text';
    texts?: string[];
  }[] = [
    {
      key: 'monthly',
      label: t('compare.monthly'),
      values: monthlyValues,
      lowerBetter: true,
      format: 'money',
    },
    {
      key: 'first',
      label: t('compare.firstMonth'),
      values: items.map((c) => c.result.firstMonthPayment),
      lowerBetter: true,
      format: 'money',
    },
    {
      key: 'last',
      label: t('compare.lastMonth'),
      values: items.map((c) => c.result.lastMonthPayment),
      lowerBetter: true,
      format: 'money',
    },
    {
      key: 'interest',
      label: t('home.totalInterest'),
      values: items.map((c) => c.result.totalInterest),
      lowerBetter: true,
      format: 'money',
    },
    {
      key: 'total',
      label: t('home.totalPayment'),
      values: items.map((c) => c.result.totalPayment),
      lowerBetter: true,
      format: 'money',
    },
    {
      key: 'share',
      label: t('compare.interestShare'),
      values: items.map((c) =>
        c.result.totalPayment > 0 ? (c.result.totalInterest / c.result.totalPayment) * 100 : 0,
      ),
      lowerBetter: true,
      format: 'pct',
    },
    {
      key: 'daily',
      label: t('compare.dailyInterest'),
      values: items.map((c) => {
        const days = Math.max(1, c.result.input.termMonths * 30);
        return c.result.totalInterest / days;
      }),
      lowerBetter: true,
      format: 'money',
    },
  ];

  const bestIndex = (values: number[], lowerBetter: boolean) => {
    if (!values.length) return -1;
    let best = 0;
    for (let i = 1; i < values.length; i += 1) {
      if (lowerBetter ? values[i] < values[best] : values[i] > values[best]) best = i;
    }
    return best;
  };

  const interestVals = items.map((c) => c.result.totalInterest);
  const totalVals = items.map((c) => c.result.totalPayment);
  const rateText = (rate: number) => `${rate.toFixed(2).replace(/\.?0+$/, '')}%`;
  const rawNames = items.map((c) => {
    const cat = categoryLabel(c.result.input.category, t);
    const rate = rateText(c.result.input.annualRatePercent);
    return `${cat} ${rate}`;
  });
  const planNames = rawNames;
  const winInterest = bestIndex(interestVals, true);
  const winMonthly = bestIndex(monthlyValues, true);
  const lowInterest = winInterest < 0 ? 0 : winInterest;
  const highInterest = interestVals.reduce(
    (best, v, i) => (v > interestVals[best]! ? i : best),
    0,
  );
  const lowMonthly = winMonthly < 0 ? 0 : winMonthly;
  const interestGap = Math.abs(interestVals[highInterest]! - interestVals[lowInterest]!);
  const detailName = (i: number) => {
    const c = items[i];
    if (!c) return planNames[i] ?? '';
    return `${planNames[i]} · ${t('compare.termMonths', { n: c.result.input.termMonths })}`;
  };
  const summary =
    items.length === 2
      ? lowInterest === lowMonthly
        ? t('compare.summaryTwoSame', {
            low: detailName(lowInterest),
            high: detailName(lowInterest === 0 ? 1 : 0),
            lowInterestAmt: money(interestVals[lowInterest] ?? 0),
            interestDiff: money(interestGap),
            monthlyAmt: money(monthlyValues[lowMonthly] ?? 0),
          })
        : t('compare.summaryTwo', {
            low: detailName(lowInterest),
            high: detailName(lowInterest === 0 ? 1 : 0),
            lowInterestAmt: money(interestVals[lowInterest] ?? 0),
            interestDiff: money(interestGap),
            monthly: detailName(lowMonthly),
            monthlyAmt: money(monthlyValues[lowMonthly] ?? 0),
          })
      : lowInterest === lowMonthly
        ? t('compare.summaryManySame', {
            n: items.length,
            low: detailName(lowInterest),
            high: detailName(highInterest),
            lowInterestAmt: money(interestVals[lowInterest] ?? 0),
            interestDiff: money(interestGap),
            monthlyAmt: money(monthlyValues[lowMonthly] ?? 0),
          })
        : t('compare.summaryMany', {
            n: items.length,
            low: detailName(lowInterest),
            high: detailName(highInterest),
            lowInterestAmt: money(interestVals[lowInterest] ?? 0),
            interestDiff: money(interestGap),
            monthly: detailName(lowMonthly),
            monthlyAmt: money(monthlyValues[lowMonthly] ?? 0),
          });

  const chartPlans = items.map((c, i) => ({
    id: c.id,
    label: planNames[i] ?? categoryLabel(c.result.input.category, t),
    color: COMPARE_PLAN_COLORS[i % COMPARE_PLAN_COLORS.length]!,
    result: c.result,
  }));

  const showDownRow = items.some((c) => c.result.input.downPayment != null);

  const formatMetric = (m: (typeof metrics)[number], v: number) => {
    if (m.format === 'pct') return `${v.toFixed(1)}%`;
    return money(v);
  };

  const extras = compareIds.length >= 3
    ? []
    : calculations.filter((c) => !compareIds.includes(c.id));

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('compare.title')}</h1>
      </header>

      {items.length < 2 ? (
        <div className="loan-card">
          <p className="loan-muted" style={{ margin: 0, fontSize: 14, lineHeight: 1.6 }}>
            {t('compare.needTwo')}
          </p>
          <button
            type="button"
            className="loan-btn-secondary"
            style={{ marginTop: 12 }}
            onClick={onOpenSaved}
          >
            {t('compare.goSaved')}
          </button>
        </div>
      ) : (
        <>
          <div className="loan-card loan-compare-summary">
            <div className="loan-label">{t('compare.summaryTitle')}</div>
            <p className="loan-compare-summary-body">
              {summary}
            </p>
          </div>

          <div className="loan-card loan-compare-card">
            <div className="loan-compare-grid" style={{ ['--cols' as string]: items.length }}>
              <div className="loan-compare-cell loan-compare-head">{t('compare.metric')}</div>
              {items.map((c) => (
                <div key={c.id} className="loan-compare-cell loan-compare-head">
                  <div className="loan-compare-plan">{planNames[items.indexOf(c)]}</div>
                  <button type="button" className="loan-compare-remove" onClick={() => onRemove(c.id)}>
                    {t('compare.remove')}
                  </button>
                </div>
              ))}

              <div className="loan-compare-cell">{t('compare.category')}</div>
              {items.map((c) => (
                <div key={`${c.id}-cat`} className="loan-compare-cell">
                  {categoryLabel(c.result.input.category, t)}
                </div>
              ))}

              <div className="loan-compare-cell">{t('compare.mode')}</div>
              {items.map((c) => (
                <div key={`${c.id}-mode`} className="loan-compare-cell">
                  {modeLabel(c.result.input.mode, t)}
                </div>
              ))}

              <div className="loan-compare-cell">{t('compare.principal')}</div>
              {items.map((c) => (
                <div key={`${c.id}-p`} className="loan-compare-cell">
                  {money(c.result.input.principal)}
                </div>
              ))}

              {showDownRow ? (
                <>
                  <div className="loan-compare-cell">{t('compare.downPayment')}</div>
                  {items.map((c) => (
                    <div key={`${c.id}-dp`} className="loan-compare-cell">
                      {c.result.input.downPayment != null ? money(c.result.input.downPayment) : '—'}
                    </div>
                  ))}
                </>
              ) : null}

              <div className="loan-compare-cell">{t('compare.rate')}</div>
              {items.map((c) => (
                <div key={`${c.id}-r`} className="loan-compare-cell">
                  {c.result.input.annualRatePercent}%
                </div>
              ))}

              <div className="loan-compare-cell">{t('compare.term')}</div>
              {items.map((c) => (
                <div key={`${c.id}-t`} className="loan-compare-cell">
                  {t('compare.termMonths', { n: c.result.input.termMonths })}
                </div>
              ))}

              {metrics.map((m) => {
                const bi = bestIndex(m.values, m.lowerBetter);
                return (
                  <React.Fragment key={m.key}>
                    <div className="loan-compare-cell">{m.label}</div>
                    {m.values.map((v, i) => (
                      <div
                        key={`${m.key}-${i}`}
                        className={`loan-compare-cell ${i === bi ? 'loan-compare-best' : ''}`}
                      >
                        {formatMetric(m, v)}
                      </div>
                    ))}
                  </React.Fragment>
                );
              })}
            </div>
          </div>

          <CompareCharts
            plans={chartPlans}
            money={money}
            barTitle={t('compare.chartBar')}
            barLabels={{
              monthly: t('compare.monthly'),
              interest: t('home.totalInterest'),
              total: t('home.totalPayment'),
            }}
          />
        </>
      )}
      {extras.length > 0 ? (
        <div className="loan-card">
          <div className="loan-label">{t('compare.addSaved')}</div>
          {extras.map((c) => {
            const pay =
              c.result.input.mode === 'equal-principal'
                ? c.result.firstMonthPayment
                : c.result.monthlyPayment;
            const title = c.note.trim()
              ? displayKnownCopy(c.note.trim(), t)
              : categoryLabel(c.result.input.category, t);
            return (
              <div key={c.id} className="loan-row" style={{ alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 700 }}>{title}</div>
                  <div className="loan-muted" style={{ fontSize: 12, marginTop: 2 }}>
                    {t('compare.perMonth', { amount: money(pay) })}
                  </div>
                </div>
                <button type="button" className="loan-quick-chip" onClick={() => onAdd(c.id)}>
                  {t('compare.addOne')}
                </button>
              </div>
            );
          })}
        </div>
      ) : null}
    </>
  );
}

function SavedList({
  calculations,
  money,
  compareIds,
  onBack,
  onOpen,
  onDelete,
  onToggleFav,
  onCompare,
  onLeaveCompare,
  onOpenCompare,
  onGoCalc,
}: {
  calculations: SavedCalculation[];
  money: (n: number) => string;
  compareIds: string[];
  onBack: () => void;
  onOpen: (item: SavedCalculation) => void;
  onDelete: (id: string) => void;
  onToggleFav: (id: string) => void;
  onCompare: (id: string) => void;
  onLeaveCompare: (id: string) => void;
  onOpenCompare: () => void;
  onGoCalc: () => void;
}) {
  const { t } = useApp();
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);
  if (!calculations.length) {
    return (
      <>
        <header className="loan-topbar">
          <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
            <ArrowLeft size={22} strokeWidth={2} aria-hidden />
          </button>
          <h1 className="loan-title">{t('saved.title')}</h1>
        </header>
        <div className="loan-empty">
          <Bookmark size={40} strokeWidth={1.6} color="#6b5bff" style={{ marginBottom: 12 }} />
          <p>{t('saved.empty')}</p>
          <button type="button" className="loan-btn-primary" onClick={onGoCalc}>
            {t('saved.goCalc')}
          </button>
        </div>
      </>
    );
  }

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
          <h1 className="loan-title">{t('saved.title')}</h1>
      </header>
      {calculations.map((c) => {
        return (
          <div key={c.id} className="loan-card">
            <div className="loan-saved-body" onClick={() => onOpen(c)} role="presentation">
              <div className="loan-saved-head">
                <div className="loan-saved-title">
                  {c.note.trim()
                    ? displayKnownCopy(c.note.trim(), t)
                    : categoryLabel(c.result.input.category, t)}
                </div>
                {compareIds.includes(c.id) ? (
                  <button
                    type="button"
                    className="loan-chip"
                    onClick={(e) => {
                      e.stopPropagation();
                      onOpenCompare();
                    }}
                  >
                    {t('saved.inCompare')}
                  </button>
                ) : null}
                {c.favorite ? <Star className="loan-saved-star" size={16} fill="currentColor" /> : null}
              </div>
              <div className="loan-muted loan-saved-meta">
                {t('saved.meta', {
                  principal: money(c.result.input.principal),
                  rate: c.result.input.annualRatePercent,
                  months: c.result.input.termMonths,
                })}
              </div>
              <div className="loan-saved-pay">{t('compare.perMonth', { amount: money(c.result.monthlyPayment) })}</div>
            </div>
            <div className="loan-saved-actions">
              <button type="button" className="loan-quick-chip" onClick={() => onToggleFav(c.id)}>
                {c.favorite ? t('saved.unfav') : t('saved.fav')}
              </button>
              <button
                type="button"
                className="loan-quick-chip"
                onClick={() => (compareIds.includes(c.id) ? onLeaveCompare(c.id) : onCompare(c.id))}
              >
                {compareIds.includes(c.id) ? t('saved.leaveCompare') : t('saved.compare')}
              </button>
              <button type="button" className="loan-quick-chip" onClick={() => setPendingDeleteId(c.id)}>
                {t('saved.delete')}
              </button>
            </div>
          </div>
        );
      })}
      {pendingDeleteId ? (
        <div className="loan-dialog-backdrop" role="presentation" onClick={() => setPendingDeleteId(null)}>
          <div
            className="loan-dialog"
            role="dialog"
            aria-labelledby="saved-delete-title"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="saved-delete-title">{t('saved.deleteTitle')}</h2>
            <p>{t('saved.deleteConfirm')}</p>
            <div className="loan-dialog-actions">
              <button type="button" onClick={() => setPendingDeleteId(null)}>
                {t('common.back')}
              </button>
              <button
                type="button"
                onClick={() => {
                  const id = pendingDeleteId;
                  setPendingDeleteId(null);
                  onDelete(id);
                }}
              >
                {t('saved.delete')}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}

function ProfileHome({
  profile,
  setPage,
  savedCount,
  savingsCount,
}: {
  profile: { nickname: string; avatar: string };
  setPage: (p: string) => void;
  savedCount: number;
  savingsCount: number;
}) {
  const { t } = useApp();
  return (
    <>
      <header className="loan-topbar">
        <div>
          <h1 className="loan-title">{t('profile.title')}</h1>
          <p className="loan-subtitle">{t('profile.subtitle')}</p>
        </div>
      </header>
      <button
        type="button"
        className="loan-card loan-profile-entry"
        onClick={() => setPage('profile-edit')}
      >
        <div className="loan-profile-avatar">{resolvedAvatar(profile.avatar, profile.gender ?? 'private')}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 20, fontWeight: 700 }}>
            {displayNickname(profile.nickname, t)}
          </div>
          <div className="loan-muted" style={{ fontSize: 13 }}>
            {t('profile.localOnly')}
          </div>
        </div>
        <ChevronRight size={18} aria-hidden />
      </button>
      <div className="loan-stat-row">
        <button type="button" className="loan-stat-box loan-stat-box--btn" onClick={() => setPage('profile-saved')}>
          <div className="loan-label">{t('profile.savedCount')}</div>
          <strong>{savedCount}</strong>
        </button>
        <button type="button" className="loan-stat-box loan-stat-box--btn" onClick={() => setPage('savings')}>
          <div className="loan-label">{t('profile.savingsCount')}</div>
          <strong>{savingsCount}</strong>
        </button>
      </div>
      <div className="loan-card" style={{ padding: '0 16px' }}>
        <button
          type="button"
          className="loan-menu-item"
          onClick={() => setPage('profile-settings')}
        >
          {t('profile.settings')} <ChevronRight size={18} aria-hidden />
        </button>
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-data')}>
          {t('profile.data')} <ChevronRight size={18} aria-hidden />
        </button>
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-about-us')}>
          {t('profile.aboutUs')} <ChevronRight size={18} aria-hidden />
        </button>
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-about')}>
          {t('profile.about')} <ChevronRight size={18} aria-hidden />
        </button>
      </div>
    </>
  );
}

function ProfileEdit({
  profile,
  onBack,
  onSave,
}: {
  profile: { nickname: string; avatar: string; createdAt: string; gender?: 'male' | 'female' | 'private' };
  onBack: () => void;
  onSave: (p: { nickname: string; avatar: string; createdAt: string; gender: 'male' | 'female' | 'private' }) => void;
}) {
  const { t } = useApp();
  const [nickname, setNickname] = useState(() =>
    isDefaultNickname(profile.nickname) ? t('settings.defaultNick') : profile.nickname,
  );
  const [gender, setGender] = useState<'male' | 'female' | 'private'>(profile.gender ?? 'private');
  const [avatar, setAvatar] = useState(() => resolvedAvatar(profile.avatar, profile.gender ?? 'private'));

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('profile.editTitle')}</h1>
      </header>
      <div className="loan-card">
        <div className="loan-label">{t('settings.nickname')}</div>
        <input className="loan-input" value={nickname} onChange={(e) => setNickname(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          {t('settings.avatar')}
        </div>
        <input className="loan-input" value={avatar} onChange={(e) => setAvatar(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          {t('profile.gender')}
        </div>
        <div className="loan-segment">
          {(
            [
              ['male', 'profile.gender.male'],
              ['female', 'profile.gender.female'],
              ['private', 'profile.gender.private'],
            ] as const
          ).map(([id, key]) => (
            <button
              key={id}
              type="button"
              data-active={gender === id}
              onClick={() => {
                setGender(id);
                setAvatar((current) => (isDefaultAvatar(current) ? defaultAvatar(id) : current));
              }}
            >
              {t(key)}
            </button>
          ))}
        </div>
      </div>
      <button
        type="button"
        className="loan-btn-primary"
        onClick={() => {
          onSave({
            ...profile,
            nickname: nickname.trim() || t('settings.defaultNick'),
            avatar: resolvedAvatar(avatar, gender),
            gender,
          });
          onBack();
        }}
      >
        {t('settings.save')}
      </button>
    </>
  );
}

function ProfileSettings({
  settings,
  onBack,
  onSaveSettings,
}: {
  settings: {
    currencyCode: string;
    decimals: number;
    theme: string;
    locale: AppLocale;
  };
  onBack: () => void;
  onSaveSettings: (s: typeof settings & { theme: 'dark' | 'light' | 'system'; locale: AppLocale }) => void;
}) {
  const { t } = useApp();
  const [currencyCode, setCurrencyCode] = useState(settings.currencyCode);
  const [decimals, setDecimals] = useState(String(settings.decimals));
  const [locale, setLocale] = useState<AppLocale>(settings.locale);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('settings.title')}</h1>
      </header>
      <div className="loan-card">
        <div className="loan-label">{t('settings.language')}</div>
        <div className="loan-segment loan-lang-segment">
          {APP_LOCALES.map((loc) => (
            <button
              key={loc.id}
              type="button"
              data-active={locale === loc.id}
              onClick={() => {
                setLocale(loc.id);
                onSaveSettings({
                  ...settings,
                  currencyCode,
                  decimals: Math.min(4, Math.max(0, Number(decimals) || 2)),
                  theme: 'light',
                  locale: loc.id,
                });
              }}
            >
              {loc.nativeLabel}
            </button>
          ))}
        </div>
        <div className="loan-label" style={{ marginTop: 12 }}>
          {t('settings.decimals')}
        </div>
        <input
          className="loan-input"
          inputMode="numeric"
          value={decimals}
          onChange={(e) => setDecimals(e.target.value.replace(/\D/g, '').slice(0, 1))}
        />
      </div>
      <CurrencyPicker
        currencyCode={currencyCode}
        t={t}
        onChange={(code) => {
          setCurrencyCode(code);
          setDecimals(String(getCurrency(code).defaultDecimals));
        }}
      />
      <button
        type="button"
        className="loan-btn-primary"
        onClick={() => {
          onSaveSettings({
            ...settings,
            currencyCode,
            decimals: Math.min(4, Math.max(0, Number(decimals) || 2)),
            theme: 'light',
            locale,
          });
          onBack();
        }}
      >
        {t('settings.save')}
      </button>
    </>
  );
}

function ProfileData({
  onBack,
  onExport,
  onClear,
}: {
  onBack: () => void;
  onExport: () => void;
  onClear: () => void;
}) {
  const { t } = useApp();
  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('data.title')}</h1>
      </header>
      <div className="loan-card" style={{ padding: 0 }}>
        <button type="button" className="loan-menu-item" style={{ padding: '16px' }} onClick={onExport}>
          {t('data.export')} <span>↓</span>
        </button>
        <button
          type="button"
          className="loan-menu-item loan-danger"
          style={{ padding: '16px' }}
          onClick={onClear}
        >
          {t('data.clear')} <span>!</span>
        </button>
      </div>
      <p className="loan-muted" style={{ fontSize: 13, lineHeight: 1.6 }}>
        {t('data.hint')}
      </p>
    </>
  );
}

function ProfilePrivacyPage({ onBack }: { onBack: () => void }) {
  const { t } = useApp();
  return (
    <div className="loan-privacy">
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t('about.title')}</h1>
      </header>
      <iframe className="loan-privacy-frame" title={t('about.title')} src={privacyPolicyUrl} />
    </div>
  );
}

function ProfileTextPage({
  titleKey,
  bodyKey,
  onBack,
}: {
  titleKey: 'aboutUs.title';
  bodyKey: 'aboutUs.body';
  onBack: () => void;
}) {
  const { t } = useApp();
  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          <ArrowLeft size={22} strokeWidth={2} aria-hidden />
        </button>
        <h1 className="loan-title">{t(titleKey)}</h1>
      </header>
      <div className="loan-card">
        {t(bodyKey)
          .split(/\n\s*\n/)
          .filter((paragraph) => paragraph.trim())
          .map((paragraph, index) => (
            <p
              key={paragraph.slice(0, 24)}
              className="loan-muted"
              style={{ fontSize: 15, lineHeight: 1.7, margin: index === 0 ? 0 : '12px 0 0' }}
            >
              {paragraph}
            </p>
          ))}
      </div>
    </>
  );
}

export default function LoanCalculatorRoot() {
  return (
    <AppProvider>
      <LoanCalculatorApp />
    </AppProvider>
  );
}
