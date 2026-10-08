/**
 * @name 贷款计算器
 */

import React, { useEffect, useMemo, useState } from 'react';
import {
  Calculator,
  Car,
  ChevronRight,
  Clock3,
  Home,
  Landmark,
  MoreHorizontal,
  PieChart,
  PiggyBank,
  Shield,
  ShoppingBag,
  Sparkles,
  TableProperties,
  UserRound,
  Wallet,
  WifiOff,
  type LucideIcon,
} from 'lucide-react';
import { defineHashPageRoute, useHashPage } from '../../common/useHashPage';
import { CurrencyPicker } from './components/CurrencyPicker';
import { Donut } from './components/Donut';
import { AppProvider, useApp } from './context';
import { computeLoan, modeLabel } from './lib/calc';
import { getCurrency } from './lib/currencies';
import { formatMoney, parseHashParams, setHashPage, uid } from './lib/format';
import type {
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
    { id: 'savings', title: '储蓄' },
    { id: 'savings-detail', title: '储蓄详情' },
    { id: 'savings-new', title: '新建储蓄' },
    { id: 'history', title: '历史' },
    { id: 'history-detail', title: '历史详情' },
    { id: 'profile', title: '我的' },
    { id: 'profile-settings', title: '偏好设置' },
    { id: 'profile-data', title: '数据管理' },
    { id: 'profile-about', title: '关于与隐私' },
  ],
  { defaultPageId: 'calc' },
);

const TAB_ROOTS = ['calc', 'savings', 'history', 'profile'] as const;

const TAB_NAV: {
  id: (typeof TAB_ROOTS)[number];
  label: string;
  Icon: LucideIcon;
}[] = [
  { id: 'calc', label: '计算', Icon: Calculator },
  { id: 'savings', label: '储蓄', Icon: PiggyBank },
  { id: 'history', label: '历史', Icon: Clock3 },
  { id: 'profile', label: '我的', Icon: UserRound },
];

const LOAN_TYPE_META: Record<
  LoanCategory,
  { label: string; Icon: LucideIcon }
> = {
  mortgage: { label: '房贷', Icon: Home },
  auto: { label: '车贷', Icon: Car },
  personal: { label: '消费', Icon: ShoppingBag },
  other: { label: '其他', Icon: MoreHorizontal },
};

function tabForPage(page: string): (typeof TAB_ROOTS)[number] {
  if (page.startsWith('calc')) return 'calc';
  if (page.startsWith('savings')) return 'savings';
  if (page.startsWith('history')) return 'history';
  return 'profile';
}

function showTabBar(page: string) {
  return (TAB_ROOTS as readonly string[]).includes(page);
}

function LoanCalculatorApp() {
  const { page, setPage } = useHashPage(ROUTE);
  const app = useApp();
  const params = parseHashParams();
  const entityId = params.get('id') ?? '';

  const money = (n: number) => formatMoney(n, app.settings);

  const applyCurrency = (code: string) => {
    const cur = getCurrency(code);
    app.updateSettings({
      ...app.settings,
      currencyCode: code,
      decimals: cur.defaultDecimals,
    });
    app.showToast(`已切换为 ${cur.name}（${cur.symbol}）`);
  };

  const goTab = (tab: (typeof TAB_ROOTS)[number]) => setPage(tab);

  let content: React.ReactNode = null;

  if (page === 'calc') {
    content = (
      <CalcHome
        currencyCode={app.settings.currencyCode}
        onCurrencyChange={applyCurrency}
        onResult={(r) => {
          app.setPendingResult(r);
          setPage('calc-result');
        }}
        money={money}
      />
    );
  } else if (page === 'calc-result' && app.pendingResult) {
    content = (
      <CalcResultView
        result={app.pendingResult}
        money={money}
        onAmortization={() => setPage('amortization')}
        onSave={() => {
          const item: SavedCalculation = {
            id: uid('calc'),
            createdAt: new Date().toISOString(),
            favorite: false,
            note: app.pendingResult!.input.label || modeLabel(app.pendingResult!.input.mode),
            result: app.pendingResult!,
          };
          app.persistCalculations([item, ...app.calculations]);
          app.showToast('已保存到历史');
        }}
        onSavings={() => {
          const monthly = app.pendingResult!.monthlyPayment;
          setHashPage('savings-new', {
            prefill: String(Math.round(monthly * 3)),
          });
        }}
        back={() => setPage('calc')}
      />
    );
  } else if (page === 'calc-result') {
    content = <RedirectCalc />;
  } else if (page === 'amortization' && app.pendingResult) {
    content = (
      <AmortizationView
        result={app.pendingResult}
        money={money}
        back={() => setPage('calc-result')}
      />
    );
  } else if (page === 'amortization') {
    content = <RedirectCalc />;
  } else if (page === 'savings') {
    content = (
      <SavingsList
        goals={app.savingsGoals}
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
          app.showToast('目标已创建');
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
      <EmptyRedirect message="目标不存在" onGo={() => setPage('savings')} />
    );
  } else if (page === 'history') {
    content = (
      <HistoryList
        items={app.calculations}
        money={money}
        favCount={app.calculations.filter((c) => c.favorite).length}
        onOpen={(id) => setHashPage('history-detail', { id: id })}
        onDelete={(id) => {
          app.persistCalculations(app.calculations.filter((c) => c.id !== id));
          app.showToast('已删除');
        }}
        onToggleFav={(id) => {
          app.persistCalculations(
            app.calculations.map((c) =>
              c.id === id ? { ...c, favorite: !c.favorite } : c,
            ),
          );
        }}
      />
    );
  } else if (page === 'history-detail') {
    const item = app.calculations.find((c) => c.id === entityId);
    content = item ? (
      <HistoryDetail
        item={item}
        money={money}
        onBack={() => setPage('history')}
        onView={() => {
          app.setPendingResult(item.result);
          setPage('calc-result');
        }}
      />
    ) : (
      <EmptyRedirect message="记录不存在" onGo={() => setPage('history')} />
    );
  } else if (page === 'profile') {
    content = (
      <ProfileHome
        profile={app.profile}
        setPage={setPage}
        calcCount={app.calculations.length}
        savingsCount={app.savingsGoals.length}
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
          if (window.confirm('确定清空所有计算与储蓄数据？偏好设置将保留。')) {
            app.clearBusiness();
            app.showToast('业务数据已清空');
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
    <div className="loan-app">
      <div className="loan-shell">
        {app.toast ? <div className="loan-toast">{app.toast}</div> : null}
        <main className="loan-main">{content}</main>
        {showTabBar(page) ? (
          <nav className="loan-tabbar" aria-label="主导航">
            {TAB_NAV.map(({ id, label, Icon }) => (
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
                {label}
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
  return (
    <div className="loan-empty">
      <p>{message}</p>
      <button type="button" className="loan-btn-primary" onClick={onGo}>
        返回
      </button>
    </div>
  );
}

function CalcHome({
  currencyCode,
  onCurrencyChange,
  onResult,
  money,
}: {
  currencyCode: string;
  onCurrencyChange: (code: string) => void;
  onResult: (r: CalcResult) => void;
  money: (n: number) => string;
}) {
  const app = useApp();
  const [mode, setMode] = useState<RepaymentMode>('equal-payment');
  const [category, setCategory] = useState<LoanCategory>('mortgage');
  const [principal, setPrincipal] = useState('1000000');
  const [rate, setRate] = useState('4.2');
  const [years, setYears] = useState('30');
  const [months, setMonths] = useState('0');
  const [errors, setErrors] = useState<Record<string, boolean>>({});

  const preview = useMemo(() => {
    const P = Number(principal);
    const r = Number(rate);
    const termMonths = Number(years) * 12 + Number(months);
    if (!P || P <= 0 || Number.isNaN(r) || r < 0 || !termMonths) return null;
    try {
      return computeLoan({
        principal: P,
        annualRatePercent: r,
        termMonths,
        mode,
        category,
      });
    } catch {
      return null;
    }
  }, [principal, rate, years, months, mode, category]);

  const submit = () => {
    const P = Number(principal);
    const r = Number(rate);
    const termMonths = Number(years) * 12 + Number(months);
    const err: Record<string, boolean> = {};
    if (!P || P <= 0) err.principal = true;
    if (Number.isNaN(r) || r < 0) err.rate = true;
    if (!termMonths || termMonths <= 0) err.term = true;
    setErrors(err);
    if (Object.keys(err).length) return;

    try {
      const result = computeLoan({
        principal: P,
        annualRatePercent: r,
        termMonths,
        mode,
        category,
      });
      onResult(result);
    } catch {
      setErrors({ principal: true, term: true });
    }
  };

  const previewPayment =
    preview &&
    (mode === 'equal-principal'
      ? preview.firstMonthPayment
      : preview.monthlyPayment);

  return (
    <>
      <div className="loan-hero-banner">
        <h2>智能贷款试算</h2>
        <p>输入金额与期限，实时预览月供与总利息，结果可保存并关联储蓄目标。</p>
        <div className="loan-hero-badges">
          <span className="loan-hero-badge">
            <WifiOff aria-hidden />
            纯离线
          </span>
          <span className="loan-hero-badge">
            <Shield aria-hidden />
            数据在本地
          </span>
          {app.calculations.length > 0 ? (
            <span className="loan-hero-badge">
              <Clock3 aria-hidden />
              已存 {app.calculations.length} 条方案
            </span>
          ) : null}
        </div>
      </div>

      <CurrencyPicker currencyCode={currencyCode} onChange={onCurrencyChange} />

      <div className="loan-feature-row">
        <div className="loan-feature-item">
          <PieChart aria-hidden />
          <div>本息占比图</div>
        </div>
        <div className="loan-feature-item">
          <TableProperties aria-hidden />
          <div>摊还明细表</div>
        </div>
        <div className="loan-feature-item">
          <PiggyBank aria-hidden />
          <div>月供储蓄</div>
        </div>
      </div>

      {preview && previewPayment != null ? (
        <div className="loan-preview-card">
          <div className="loan-preview-label">
            <Sparkles size={14} style={{ verticalAlign: -2, marginRight: 4 }} />
            实时预览 · {modeLabel(mode)}
          </div>
          <div className="loan-preview-amount">{money(previewPayment)}</div>
          <div className="loan-preview-meta">
            <div>
              总利息
              <strong>{money(preview.totalInterest)}</strong>
            </div>
            <div>
              还款总额
              <strong>{money(preview.totalPayment)}</strong>
            </div>
          </div>
        </div>
      ) : null}

      <div className="loan-card">
        <div className="loan-section-head">
          <Landmark aria-hidden />
          <span>还款方式</span>
        </div>
        <div className="loan-segment">
          <button
            type="button"
            data-active={mode === 'equal-payment'}
            onClick={() => setMode('equal-payment')}
          >
            等额本息
          </button>
          <button
            type="button"
            data-active={mode === 'equal-principal'}
            onClick={() => setMode('equal-principal')}
          >
            等额本金
          </button>
        </div>
        <p className="loan-muted" style={{ fontSize: 12, margin: '10px 0 0', lineHeight: 1.5 }}>
          {mode === 'equal-payment'
            ? '每月还款额固定，前期利息占比较高。'
            : '每月本金固定，月供逐月递减。'}
        </p>
      </div>

      <div className="loan-card">
        <div className="loan-section-head">
          <Wallet aria-hidden />
          <span>贷款类型</span>
        </div>
        <div className="loan-type-grid">
          {(Object.keys(LOAN_TYPE_META) as LoanCategory[]).map((k) => {
            const { label, Icon } = LOAN_TYPE_META[k];
            return (
              <button
                key={k}
                type="button"
                className="loan-type-tile"
                data-active={category === k}
                onClick={() => setCategory(k)}
              >
                <Icon size={20} />
                {label}
              </button>
            );
          })}
        </div>
      </div>

      <div className="loan-card">
        <div className="loan-section-head">
          <Calculator aria-hidden />
          <span>贷款参数</span>
        </div>
        <div className="loan-label">贷款本金</div>
        <div className="loan-input-wrap">
          <input
            className={`loan-input ${errors.principal ? 'loan-input-error' : ''}`}
            inputMode="decimal"
            value={principal}
            onChange={(e) => setPrincipal(e.target.value.replace(/[^\d.]/g, ''))}
          />
          <span className="loan-input-suffix">元</span>
        </div>
        <div className="loan-chip-row">
          {[500_000, 1_000_000, 1_500_000, 2_000_000].map((v) => (
            <button
              key={v}
              type="button"
              className="loan-quick-chip"
              onClick={() => setPrincipal(String(v))}
            >
              {v >= 1_000_000 ? `${v / 1_000_000} 百万` : `${v / 10_000} 万`}
            </button>
          ))}
        </div>
        <div className="loan-label" style={{ marginTop: 14 }}>
          年利率
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
          {['3.1', '3.85', '4.2', '4.9'].map((v) => (
            <button
              key={v}
              type="button"
              className="loan-quick-chip"
              onClick={() => setRate(v)}
            >
              {v}%
            </button>
          ))}
        </div>
        <div className="loan-label" style={{ marginTop: 14 }}>
          贷款期限
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
            <span className="loan-input-suffix">年</span>
          </div>
          <div className="loan-input-wrap">
            <input
              className={`loan-input ${errors.term ? 'loan-input-error' : ''}`}
              inputMode="numeric"
              value={months}
              placeholder="0"
              onChange={(e) => setMonths(e.target.value.replace(/\D/g, ''))}
            />
            <span className="loan-input-suffix">月</span>
          </div>
        </div>
        <div className="loan-chip-row">
          {[
            ['30', '0'],
            ['20', '0'],
            ['10', '0'],
            ['5', '0'],
          ].map(([y, m]) => (
            <button
              key={`${y}-${m}`}
              type="button"
              className="loan-quick-chip"
              onClick={() => {
                setYears(y);
                setMonths(m);
              }}
            >
              {y} 年
            </button>
          ))}
        </div>
      </div>

      <button type="button" className="loan-btn-primary" onClick={submit}>
        开始计算
      </button>
      <p className="loan-muted" style={{ fontSize: 12, marginTop: 12, textAlign: 'center' }}>
        试算结果仅供参考，不构成任何放贷承诺
      </p>
    </>
  );
}

function CalcResultView({
  result,
  money,
  onAmortization,
  onSave,
  onSavings,
  back,
}: {
  result: CalcResult;
  money: (n: number) => string;
  onAmortization: () => void;
  onSave: () => void;
  onSavings: () => void;
  back: () => void;
}) {
  const isEqualPrincipal = result.input.mode === 'equal-principal';
  const hero = isEqualPrincipal
    ? `${money(result.firstMonthPayment)} → ${money(result.lastMonthPayment)}`
    : money(result.monthlyPayment);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={back} aria-label="返回">
          ←
        </button>
        <div>
          <h1 className="loan-title">计算结果</h1>
          <p className="loan-subtitle">{modeLabel(result.input.mode)}</p>
        </div>
      </header>

      <div className="loan-card">
        <div className="loan-label">{isEqualPrincipal ? '首月 → 末月还款' : '月供'}</div>
        <div className="loan-hero-amount">{hero}</div>
        <Donut
          segments={[
            {
              value: result.input.principal,
              color: '#5b6bff',
              label: '本金',
            },
            {
              value: result.totalInterest,
              color: '#9c6bff',
              label: '利息',
            },
          ]}
          centerLabel={money(result.totalPayment)}
          centerSub="还款总额"
        />
        <div className="loan-row">
          <span>总利息</span>
          <span className="loan-text-spend">{money(result.totalInterest)}</span>
        </div>
        <div className="loan-row">
          <span>贷款本金</span>
          <span>{money(result.input.principal)}</span>
        </div>
      </div>

      <button type="button" className="loan-btn-primary" onClick={onAmortization}>
        查看摊还明细
      </button>
      <div style={{ height: 8 }} />
      <button type="button" className="loan-btn-secondary" onClick={onSave}>
        保存到历史
      </button>
      <div style={{ height: 8 }} />
      <button type="button" className="loan-btn-secondary" onClick={onSavings}>
        为月供设储蓄目标
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
  const [yearly, setYearly] = useState(false);

  const rows = useMemo(() => {
    if (!yearly) return result.schedule;
    const byYear: { period: number; payment: number; principal: number; interest: number; balance: number }[] = [];
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
  }, [yearly, result.schedule]);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={back} aria-label="返回">
          ←
        </button>
        <div>
          <h1 className="loan-title">摊还明细</h1>
          <p className="loan-subtitle">共 {result.schedule.length} 期</p>
        </div>
      </header>

      <div className="loan-card">
        <div className="loan-segment">
          <button type="button" data-active={!yearly} onClick={() => setYearly(false)}>
            按月
          </button>
          <button type="button" data-active={yearly} onClick={() => setYearly(true)}>
            按年
          </button>
        </div>
        <div style={{ overflowX: 'auto', marginTop: 12 }}>
          <table className="loan-amort-table">
            <thead>
              <tr>
                <th>{yearly ? '年' : '期'}</th>
                <th>还款</th>
                <th>本金</th>
                <th>利息</th>
                <th>余额</th>
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
  money,
  calcCount,
  onOpen,
  onNew,
}: {
  goals: SavingsGoal[];
  money: (n: number) => string;
  calcCount: number;
  onOpen: (id: string) => void;
  onNew: () => void;
}) {
  const totalSaved = goals.reduce((s, g) => s + g.current, 0);
  const totalTarget = goals.reduce((s, g) => s + g.target, 0);

  if (!goals.length) {
    return (
      <>
        <header className="loan-topbar">
          <div>
            <h1 className="loan-title">储蓄目标</h1>
            <p className="loan-subtitle">为月供或缓冲金攒一笔</p>
          </div>
        </header>
        <div className="loan-empty">
          <PiggyBank size={40} strokeWidth={1.6} color="#6b5bff" style={{ marginBottom: 12 }} />
          <p>还没有储蓄目标。可从计算结果一键创建，或手动新建。</p>
          <button type="button" className="loan-btn-primary" onClick={onNew}>
            新建目标
          </button>
        </div>
      </>
    );
  }

  return (
    <>
      <header className="loan-topbar">
        <div>
          <h1 className="loan-title">储蓄目标</h1>
          <p className="loan-subtitle">{goals.length} 个进行中</p>
        </div>
      </header>
      <div className="loan-stat-row">
        <div className="loan-stat-box">
          <div className="loan-label">已存合计</div>
          <strong>{money(totalSaved)}</strong>
        </div>
        <div className="loan-stat-box">
          <div className="loan-label">目标合计</div>
          <strong>{money(totalTarget)}</strong>
        </div>
      </div>
      {calcCount > 0 ? (
        <p className="loan-muted" style={{ fontSize: 12, margin: '-4px 0 12px' }}>
          已关联 {calcCount} 条贷款方案，可在计算结果页快速创建目标
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
                { value: g.current, color: '#5b6bff', label: '已存' },
                { value: Math.max(0, g.target - g.current), color: '#e2e5f0', label: '待存' },
              ]}
              centerLabel={money(g.current)}
              centerSub={`目标 ${money(g.target)}`}
              animate={false}
            />
          </div>
        );
      })}
      <button type="button" className="loan-fab" aria-label="新建" onClick={onNew}>
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
  const [name, setName] = useState('月供缓冲金');
  const [target, setTarget] = useState(prefillTarget || '15000');

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onDone} aria-label="返回">
          ←
        </button>
        <h1 className="loan-title">新建目标</h1>
      </header>
      <div className="loan-card">
        <div className="loan-label">名称</div>
        <input className="loan-input" value={name} onChange={(e) => setName(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          目标金额
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
          const t = Number(target);
          if (!name.trim() || !t || t <= 0) return;
          onSave({
            id: uid('goal'),
            name: name.trim(),
            target: t,
            current: 0,
            deadline: null,
            linkedCalcId: null,
            transactions: [],
            createdAt: new Date().toISOString(),
          });
        }}
      >
        创建
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
      note: type === 'deposit' ? '存入' : '取出',
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
        <button type="button" className="loan-back" onClick={onBack} aria-label="返回">
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
        <div className="loan-label">存入 / 取出</div>
        <input
          className="loan-input"
          inputMode="decimal"
          placeholder="金额"
          value={amount}
          onChange={(e) => setAmount(e.target.value.replace(/[^\d.]/g, ''))}
        />
        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
          <button type="button" className="loan-btn-primary" style={{ flex: 1 }} onClick={() => addTx('deposit')}>
            存入
          </button>
          <button type="button" className="loan-btn-secondary" style={{ flex: 1 }} onClick={() => addTx('withdraw')}>
            取出
          </button>
        </div>
      </div>
      <div className="loan-card">
        <div className="loan-label">流水</div>
        {goal.transactions.length === 0 ? (
          <p className="loan-muted" style={{ fontSize: 14 }}>暂无记录</p>
        ) : (
          goal.transactions.map((tx) => (
            <div key={tx.id} className="loan-row">
              <span>
                {tx.type === 'deposit' ? '存入' : '取出'} ·{' '}
                {new Date(tx.at).toLocaleDateString('zh-CN')}
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

function HistoryList({
  items,
  money,
  favCount,
  onOpen,
  onDelete,
  onToggleFav,
}: {
  items: SavedCalculation[];
  money: (n: number) => string;
  favCount: number;
  onOpen: (id: string) => void;
  onDelete: (id: string) => void;
  onToggleFav: (id: string) => void;
}) {
  const [q, setQ] = useState('');
  const filtered = items.filter(
    (c) =>
      !q.trim() ||
      c.note.toLowerCase().includes(q.toLowerCase()) ||
      modeLabel(c.result.input.mode).includes(q),
  );

  if (!items.length) {
    return (
      <>
        <header className="loan-topbar">
          <div>
            <h1 className="loan-title">历史</h1>
            <p className="loan-subtitle">保存的计算方案</p>
          </div>
        </header>
        <div className="loan-empty">
          <Clock3 size={40} strokeWidth={1.6} color="#6b5bff" style={{ marginBottom: 12 }} />
          <p>完成一次计算并保存后，会出现在这里。</p>
        </div>
      </>
    );
  }

  return (
    <>
      <header className="loan-topbar">
        <div>
          <h1 className="loan-title">历史</h1>
          <p className="loan-subtitle">{items.length} 条记录</p>
        </div>
      </header>
      <div className="loan-stat-row">
        <div className="loan-stat-box">
          <div className="loan-label">全部方案</div>
          <strong>{items.length}</strong>
        </div>
        <div className="loan-stat-box">
          <div className="loan-label">已收藏</div>
          <strong>{favCount}</strong>
        </div>
      </div>
      <input
        className="loan-input"
        placeholder="搜索备注或还款方式"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        style={{ marginBottom: 12 }}
      />
      <div className="loan-card" style={{ padding: '8px 16px' }}>
        {filtered.map((c) => (
          <div key={c.id} className="loan-list-item">
            <div style={{ flex: 1 }} onClick={() => onOpen(c.id)} role="presentation">
              <div style={{ fontWeight: 600 }}>{c.note}</div>
              <div className="loan-muted" style={{ fontSize: 12 }}>
                {modeLabel(c.result.input.mode)} · {money(c.result.monthlyPayment)}/月
              </div>
            </div>
            <button
              type="button"
              style={{ background: 'none', border: 0, cursor: 'pointer', fontSize: 18 }}
              onClick={() => onToggleFav(c.id)}
              aria-label="收藏"
            >
              {c.favorite ? '★' : '☆'}
            </button>
            <button
              type="button"
              className="loan-text-spend"
              style={{ background: 'none', border: 0, cursor: 'pointer' }}
              onClick={() => onDelete(c.id)}
            >
              删
            </button>
          </div>
        ))}
      </div>
    </>
  );
}

function HistoryDetail({
  item,
  money,
  onBack,
  onView,
}: {
  item: SavedCalculation;
  money: (n: number) => string;
  onBack: () => void;
  onView: () => void;
}) {
  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label="返回">
          ←
        </button>
        <div>
          <h1 className="loan-title">{item.note}</h1>
          <p className="loan-subtitle">
            {new Date(item.createdAt).toLocaleString('zh-CN')}
          </p>
        </div>
      </header>
      <div className="loan-card">
        <div className="loan-row">
          <span>月供</span>
          <span>{money(item.result.monthlyPayment)}</span>
        </div>
        <div className="loan-row">
          <span>总利息</span>
          <span>{money(item.result.totalInterest)}</span>
        </div>
        <div className="loan-row">
          <span>还款总额</span>
          <span>{money(item.result.totalPayment)}</span>
        </div>
      </div>
      <button type="button" className="loan-btn-primary" onClick={onView}>
        打开完整结果
      </button>
    </>
  );
}

function ProfileHome({
  profile,
  setPage,
  calcCount,
  savingsCount,
}: {
  profile: { nickname: string; avatar: string };
  setPage: (p: string) => void;
  calcCount: number;
  savingsCount: number;
}) {
  return (
    <>
      <header className="loan-topbar">
        <div>
          <h1 className="loan-title">我的</h1>
          <p className="loan-subtitle">本地资料与偏好</p>
        </div>
      </header>
      <div className="loan-card" style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <div className="loan-profile-avatar">{profile.avatar}</div>
        <div>
          <div style={{ fontSize: 20, fontWeight: 700 }}>{profile.nickname}</div>
          <div className="loan-muted" style={{ fontSize: 13 }}>数据仅保存在本设备</div>
        </div>
      </div>
      <div className="loan-stat-row">
        <div className="loan-stat-box">
          <div className="loan-label">计算方案</div>
          <strong>{calcCount}</strong>
        </div>
        <div className="loan-stat-box">
          <div className="loan-label">储蓄目标</div>
          <strong>{savingsCount}</strong>
        </div>
      </div>
      <div className="loan-card" style={{ padding: '0 16px' }}>
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-settings')}>
          偏好设置 <ChevronRight size={18} aria-hidden />
        </button>
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-data')}>
          数据管理 <ChevronRight size={18} aria-hidden />
        </button>
        <button type="button" className="loan-menu-item" onClick={() => setPage('profile-about')}>
          关于与隐私 <ChevronRight size={18} aria-hidden />
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
  settings: { currencyCode: string; decimals: number; theme: string };
  profile: { nickname: string; avatar: string; createdAt: string };
  onBack: () => void;
  onSaveSettings: (s: typeof settings & { theme: 'dark' | 'light' | 'system' }) => void;
  onSaveProfile: (p: typeof profile) => void;
}) {
  const [currencyCode, setCurrencyCode] = useState(settings.currencyCode);
  const [decimals, setDecimals] = useState(String(settings.decimals));
  const [nickname, setNickname] = useState(profile.nickname);
  const [avatar, setAvatar] = useState(profile.avatar);

  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label="返回">
          ←
        </button>
        <h1 className="loan-title">偏好设置</h1>
      </header>
      <div className="loan-card">
        <div className="loan-label">昵称</div>
        <input className="loan-input" value={nickname} onChange={(e) => setNickname(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          头像（emoji）
        </div>
        <input className="loan-input" value={avatar} onChange={(e) => setAvatar(e.target.value)} />
        <div className="loan-label" style={{ marginTop: 12 }}>
          小数位
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
        onChange={(code) => {
          setCurrencyCode(code);
          setDecimals(String(getCurrency(code).defaultDecimals));
        }}
      />
      <button
        type="button"
        className="loan-btn-primary"
        onClick={() => {
          onSaveProfile({ ...profile, nickname: nickname.trim() || '借款人', avatar });
          onSaveSettings({
            ...settings,
            currencyCode,
            decimals: Math.min(4, Math.max(0, Number(decimals) || 2)),
            theme: 'light',
          });
          onBack();
        }}
      >
        保存
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
  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label="返回">
          ←
        </button>
        <h1 className="loan-title">数据管理</h1>
      </header>
      <div className="loan-card" style={{ padding: 0 }}>
        <button type="button" className="loan-menu-item" style={{ padding: '16px' }} onClick={onExport}>
          导出 JSON 备份 <span>↓</span>
        </button>
        <button
          type="button"
          className="loan-menu-item loan-danger"
          style={{ padding: '16px' }}
          onClick={onClear}
        >
          清空计算与储蓄数据 <span>!</span>
        </button>
      </div>
      <p className="loan-muted" style={{ fontSize: 13, lineHeight: 1.6 }}>
        清空仅删除计算历史与储蓄目标，不会重置昵称、货币等偏好。
      </p>
    </>
  );
}

function ProfileAbout({ onBack }: { onBack: () => void }) {
  return (
    <>
      <header className="loan-topbar">
        <button type="button" className="loan-back" onClick={onBack} aria-label="返回">
          ←
        </button>
        <h1 className="loan-title">关于与隐私</h1>
      </header>
      <div className="loan-card">
        <p className="loan-muted" style={{ fontSize: 15, lineHeight: 1.7, margin: 0 }}>
          本原型为离线贷款计算器演示：所有计算在浏览器内完成，数据写入 localStorage，不连接任何服务器，不上传个人信息。
          导出文件仅由您自行保存。设计参考 Revolut Mobile 视觉规范，仅供产品原型与后续 App 开发参考。
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
