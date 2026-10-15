/**
 * @name 贷款计算器
 */

import React, { useEffect, useMemo, useState } from 'react';
import {
  Calculator,
  Car,
  ChevronRight,
  Clock3,
  Columns2,
  Home,
  Landmark,
  PieChart,
  PiggyBank,
  Shield,
  ShoppingBag,
  Sparkles,
  TableProperties,
  UserRound,
  Wallet,
  type LucideIcon,
} from 'lucide-react';
import { defineHashPageRoute, useHashPage } from '../../common/useHashPage';
import { CurrencyPicker } from './components/CurrencyPicker';
import { Donut } from './components/Donut';
import { AppProvider, useApp } from './context';
import { computeLoan } from './lib/calc';
import { savingsBufferLine, savingsEtaLine } from './lib/savings_insights';
import { getCurrency } from './lib/currencies';
import { formatMoney, parseHashParams, setHashPage, uid } from './lib/format';
import {
  APP_LOCALES,
  categoryMessageKey,
  htmlLang,
  modeMessageKey,
  type TranslateFn,
} from './lib/i18n';
import { defaultTagsForCategory } from './lib/tags';
import type {
  AppLocale,
  CalcInput,
  CalcResult,
  LoanCategory,
  RepaymentMode,
  SavedCalculation,
  SavingsGoal,
} from './lib/types';
import './style.css';

const ROUTE = defineHashPageRoute(
  [
    { id: 'calc', title: '计算' },
    { id: 'calc-result', title: '计算结果' },
    { id: 'amortization', title: '摊还明细' },
    { id: 'compare', title: '方案对比' },
    { id: 'savings', title: '储蓄' },
    { id: 'savings-detail', title: '储蓄详情' },
    { id: 'savings-new', title: '新建储蓄' },
    { id: 'profile', title: '我的' },
    { id: 'profile-saved', title: '已保存方案' },
    { id: 'profile-settings', title: '偏好设置' },
    { id: 'profile-data', title: '数据管理' },
    { id: 'profile-about', title: '关于与隐私' },
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
};

const CATEGORY_PRESETS: Record<
  Exclude<LoanCategory, 'other'>,
  { principal: string; rate: string; years: string; months: string; vehicle?: string; downPct?: string }
> = {
  mortgage: { principal: '1000000', rate: '3.6', years: '30', months: '0' },
  auto: { principal: '126000', rate: '4.5', years: '3', months: '0', vehicle: '180000', downPct: '30' },
  personal: { principal: '50000', rate: '8.5', years: '3', months: '0' },
};

function categoryLabel(c: LoanCategory, t: TranslateFn) {
  return t(categoryMessageKey(c));
}

function modeLabel(mode: RepaymentMode, t: TranslateFn) {
  return t(modeMessageKey(mode));
}

function sameLoanInput(a: CalcInput, b: CalcInput): boolean {
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
      note:
        input.label ||
        `${categoryLabel(input.category, t)} · ${modeLabel(input.mode, t)}`,
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
    const showSave = resultFrom !== 'profile-saved';
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
          if (id) {
            const ok = app.addToCompare(id);
            if (!ok) app.showToast(t('compare.max'));
            else app.showToast(t('compare.added'));
          }
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
        pendingResult={app.pendingResult}
        onBack={() => setPage(from)}
        onRemove={(id) => app.persistCompareIds(app.compareIds.filter((x) => x !== id))}
        onOpenSaved={() => setHashPage('profile-saved', { from: 'compare' })}
        onPick={(id) => {
          const ok = app.addToCompare(id);
          if (!ok) app.showToast(t('compare.max'));
        }}
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
          const ok = app.addToCompare(id);
          if (!ok) app.showToast(t('compare.max'));
          else {
            app.showToast(t('compare.added'));
            setHashPage('compare', { from: 'profile-saved' });
          }
        }}
        onGoCalc={() => setPage('calc')}
      />
    );
  } else if (page === 'profile-settings') {
    content = (
      <ProfileSettings
        settings={app.settings}
        profile={app.profile}
        onBack={() => setPage('profile')}
        onSaveSettings={app.updateSettings}
        onSaveProfile={app.updateProfile}
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
  } else if (page === 'profile-about') {
    content = <ProfileAbout onBack={() => setPage('profile')} />;
  } else {
    content = <RedirectCalc />;
  }

  const activeTab = tabForPage(page);

  return (
    <div className="loan-app" lang={htmlLang(app.settings.locale)}>
      <div className="loan-shell">
        {app.toast ? <div className="loan-toast">{app.toast}</div> : null}
        <main className="loan-main">{content}</main>
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
  const [errors, setErrors] = useState<Record<string, boolean>>({});

  const applyCategory = (next: Exclude<LoanCategory, 'other'>) => {
    setCategory(next);
    const p = CATEGORY_PRESETS[next];
    setPrincipal(p.principal);
    setRate(p.rate);
    setYears(p.years);
    setMonths(p.months);
    setErrors({});
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

  const preview = useMemo(() => {
    try {
      const P = Number(principal);
      const r = Number(rate);
      const termMonths = Number(years) * 12 + Number(months);
      if (!P || P <= 0 || Number.isNaN(r) || r < 0 || !termMonths) return null;
      const input: Parameters<typeof computeLoan>[0] = {
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
      return computeLoan(input);
    } catch {
      return null;
    }
  }, [principal, rate, years, months, mode, category, vehiclePrice, downPayment]);

  const buildResult = (): CalcResult | null => {
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
    (mode === 'equal-principal' ? preview.firstMonthPayment : preview.monthlyPayment);

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
        <div className="loan-type-grid loan-type-grid-3">
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
            {t('home.preview', { mode: modeLabel(mode, t) })}
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
      <p className="loan-muted" style={{ fontSize: 12, marginTop: 12, textAlign: 'center' }}>
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
  const isEqualPrincipal = result.input.mode === 'equal-principal';
  const hero = isEqualPrincipal
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
          ←
        </button>
        <div>
          <h1 className="loan-title">{t('result.title')}</h1>
          <p className="loan-subtitle">
            {categoryLabel(result.input.category, t)} · {modeLabel(result.input.mode, t)}
          </p>
        </div>
      </header>

      <div className="loan-card">
        <div className="loan-label">
          {isEqualPrincipal ? t('result.firstLast') : t('result.monthly')}
        </div>
        <div className="loan-hero-amount">{hero}</div>
        <Donut
          segments={[
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
          ]}
          centerValue={`${interestShare}%`}
          centerCaption={t('result.interestShare')}
        />
        <div className="loan-row">
          <span>{t('result.totalPayment')}</span>
          <strong>{money(result.totalPayment)}</strong>
        </div>
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
  const maxPeriod = result.schedule.length;
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
    if (viewMode === 'year') {
      const byYear: {
        period: number;
        payment: number;
        principal: number;
        interest: number;
        balance: number;
      }[] = [];
      for (let i = 0; i < result.schedule.length; i += 12) {
        const chunk = result.schedule.slice(i, i + 12);
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
      return result.schedule.filter(
        (row) => row.period >= clampedRange.from && row.period <= clampedRange.to,
      );
    }

    return result.schedule;
  }, [viewMode, result.schedule, clampedRange]);

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
          ←
        </button>
        <div>
          <h1 className="loan-title">{t('amort.title')}</h1>
          <p className="loan-subtitle">{t('amort.periods', { n: maxPeriod })}</p>
        </div>
      </header>

      <div className="loan-card">
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

        <div style={{ overflowX: 'auto', marginTop: 12 }}>
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
              <strong>{g.name}</strong>
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
          </div>
        );
      })}
      {goals.map((g) => (
        <div key={`${g.id}-insights`} className="loan-card loan-savings-insight">
          <div className="loan-label" style={{ marginBottom: 10 }}>
            {t('savings.insights')}
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
      ))}
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
          ←
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
}: {
  goal: SavingsGoal;
  money: (n: number) => string;
  onBack: () => void;
  onUpdate: (g: SavingsGoal) => void;
}) {
  const { t } = useApp();
  const [amount, setAmount] = useState('');

  const addTx = (type: 'deposit' | 'withdraw') => {
    const v = Number(amount);
    if (!v || v <= 0) return;
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
          ←
        </button>
        <div>
          <h1 className="loan-title">{goal.name}</h1>
          <p className="loan-subtitle">
            {money(goal.current)} / {money(goal.target)}
          </p>
        </div>
      </header>
      <div className="loan-card">
        <div className="loan-label">{t('savings.depositWithdraw')}</div>
        <input
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
    </>
  );
}

function CompareView({
  money,
  calculations,
  compareIds,
  pendingResult,
  onBack,
  onRemove,
  onOpenSaved,
  onPick,
}: {
  money: (n: number) => string;
  calculations: SavedCalculation[];
  compareIds: string[];
  pendingResult: CalcResult | null;
  onBack: () => void;
  onRemove: (id: string) => void;
  onOpenSaved: () => void;
  onPick: (id: string) => void;
}) {
  const { t } = useApp();
  const items = compareIds
    .map((id) => calculations.find((c) => c.id === id))
    .filter(Boolean) as SavedCalculation[];

  const metrics = [
    {
      key: 'monthly',
      label: t('compare.monthly'),
      values: items.map((c) =>
        c.result.input.mode === 'equal-principal'
          ? c.result.firstMonthPayment
          : c.result.monthlyPayment,
      ),
      lowerBetter: true,
    },
    {
      key: 'interest',
      label: t('home.totalInterest'),
      values: items.map((c) => c.result.totalInterest),
      lowerBetter: true,
    },
    {
      key: 'total',
      label: t('home.totalPayment'),
      values: items.map((c) => c.result.totalPayment),
      lowerBetter: true,
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

  const candidates = calculations.filter((c) => !compareIds.includes(c.id)).slice(0, 6);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          ←
        </button>
        <div>
          <h1 className="loan-title">{t('compare.title')}</h1>
          <p className="loan-subtitle">{t('compare.subtitle', { n: items.length })}</p>
        </div>
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
        <div className="loan-card loan-compare-card">
          <div className="loan-compare-grid" style={{ ['--cols' as string]: items.length }}>
            <div className="loan-compare-cell loan-compare-head">{t('compare.metric')}</div>
            {items.map((c) => (
              <div key={c.id} className="loan-compare-cell loan-compare-head">
                <div>{categoryLabel(c.result.input.category, t)}</div>
                <button type="button" className="loan-compare-remove" onClick={() => onRemove(c.id)}>
                  {t('compare.remove')}
                </button>
              </div>
            ))}
            <div className="loan-compare-cell">{t('compare.principal')}</div>
            {items.map((c) => (
              <div key={`${c.id}-p`} className="loan-compare-cell">
                {money(c.result.input.principal)}
              </div>
            ))}
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
                      {money(v)}
                    </div>
                  ))}
                </React.Fragment>
              );
            })}
          </div>
        </div>
      )}

      {candidates.length ? (
        <div className="loan-card">
          <div className="loan-label">{t('compare.addSaved')}</div>
          {candidates.map((c) => (
            <button
              key={c.id}
              type="button"
              className="loan-menu-item"
              onClick={() => onPick(c.id)}
              disabled={compareIds.length >= 3}
            >
              <span>
                {categoryLabel(c.result.input.category, t)} ·{' '}
                {t('compare.perMonth', { amount: money(c.result.monthlyPayment) })}
              </span>
              <span>+</span>
            </button>
          ))}
        </div>
      ) : null}

      {pendingResult && items.length < 3 ? (
        <p className="loan-muted" style={{ fontSize: 12 }}>
          {t('compare.hint')}
        </p>
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
  onGoCalc: () => void;
}) {
  const { t } = useApp();
  if (!calculations.length) {
    return (
      <>
        <header className="loan-topbar">
          <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
            ←
          </button>
          <h1 className="loan-title">{t('saved.title')}</h1>
        </header>
        <div className="loan-empty">
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
          ←
        </button>
        <div>
          <h1 className="loan-title">{t('saved.title')}</h1>
          <p className="loan-subtitle">{t('saved.count', { n: calculations.length })}</p>
        </div>
      </header>
      {calculations.map((c) => {
        const pay =
          c.result.input.mode === 'equal-principal'
            ? c.result.firstMonthPayment
            : c.result.monthlyPayment;
        return (
          <div key={c.id} className="loan-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
              <button
                type="button"
                style={{
                  all: 'unset',
                  cursor: 'pointer',
                  flex: 1,
                }}
                onClick={() => onOpen(c)}
              >
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                  <span className="loan-chip">{categoryLabel(c.result.input.category, t)}</span>
                  {c.favorite ? <span className="loan-chip">{t('saved.fav')}</span> : null}
                  {compareIds.includes(c.id) ? (
                    <span className="loan-chip">{t('saved.inCompare')}</span>
                  ) : null}
                </div>
                <div style={{ fontWeight: 700, fontSize: 18, marginTop: 8 }}>
                  {t('compare.perMonth', { amount: money(pay) })}
                </div>
                <div className="loan-muted" style={{ fontSize: 12, marginTop: 4 }}>
                  {t('saved.meta', {
                    principal: money(c.result.input.principal),
                    rate: c.result.input.annualRatePercent,
                    months: c.result.input.termMonths,
                  })}
                </div>
              </button>
            </div>
            <div className="loan-saved-actions">
              <button type="button" className="loan-quick-chip" onClick={() => onToggleFav(c.id)}>
                {c.favorite ? t('saved.unfav') : t('saved.fav')}
              </button>
              <button type="button" className="loan-quick-chip" onClick={() => onCompare(c.id)}>
                {t('saved.compare')}
              </button>
              <button type="button" className="loan-quick-chip" onClick={() => onDelete(c.id)}>
                {t('saved.delete')}
              </button>
            </div>
          </div>
        );
      })}
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
      <div className="loan-card" style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <div className="loan-profile-avatar">{profile.avatar}</div>
        <div>
          <div style={{ fontSize: 20, fontWeight: 700 }}>{profile.nickname}</div>
          <div className="loan-muted" style={{ fontSize: 13 }}>
            {t('profile.localOnly')}
          </div>
        </div>
      </div>
      <div className="loan-stat-row">
        <div className="loan-stat-box">
          <div className="loan-label">{t('profile.savedCount')}</div>
          <strong>{savedCount}</strong>
        </div>
        <div className="loan-stat-box">
          <div className="loan-label">{t('profile.savingsCount')}</div>
          <strong>{savingsCount}</strong>
        </div>
      </div>
      <div className="loan-card" style={{ padding: '0 16px' }}>
        <button
          type="button"
          className="loan-menu-item"
          onClick={() => setPage('profile-saved')}
        >
          {t('profile.saved')} <ChevronRight size={18} aria-hidden />
        </button>
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
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-about')}>
          {t('profile.about')} <ChevronRight size={18} aria-hidden />
        </button>
      </div>
    </>
  );
}

function ProfileSettings({
  settings,
  profile,
  onBack,
  onSaveSettings,
  onSaveProfile,
}: {
  settings: {
    currencyCode: string;
    decimals: number;
    theme: string;
    locale: AppLocale;
  };
  profile: { nickname: string; avatar: string; createdAt: string };
  onBack: () => void;
  onSaveSettings: (s: typeof settings & { theme: 'dark' | 'light' | 'system'; locale: AppLocale }) => void;
  onSaveProfile: (p: typeof profile) => void;
}) {
  const { t } = useApp();
  const [currencyCode, setCurrencyCode] = useState(settings.currencyCode);
  const [decimals, setDecimals] = useState(String(settings.decimals));
  const [nickname, setNickname] = useState(profile.nickname);
  const [avatar, setAvatar] = useState(profile.avatar);
  const [locale, setLocale] = useState<AppLocale>(settings.locale);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          ←
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
          {t('settings.nickname')}
        </div>
        <input className="loan-input" value={nickname} onChange={(e) => setNickname(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          {t('settings.avatar')}
        </div>
        <input className="loan-input" value={avatar} onChange={(e) => setAvatar(e.target.value)} />
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
          onSaveProfile({
            ...profile,
            nickname: nickname.trim() || t('settings.defaultNick'),
            avatar,
          });
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
          ←
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

function ProfileAbout({ onBack }: { onBack: () => void }) {
  const { t } = useApp();
  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label={t('nav.back')}>
          ←
        </button>
        <h1 className="loan-title">{t('about.title')}</h1>
      </header>
      <div className="loan-card">
        <p className="loan-muted" style={{ fontSize: 15, lineHeight: 1.7, margin: 0 }}>
          {t('about.body')}
        </p>
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
