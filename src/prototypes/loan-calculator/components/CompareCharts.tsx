import React, { useMemo } from 'react';
import type { CalcResult } from '../lib/types';

export const COMPARE_PLAN_COLORS = ['#6B5BFF', '#0D9F5F', '#E5484D'] as const;

type PlanSeries = {
  id: string;
  label: string;
  color: string;
  result: CalcResult;
};

type CompareChartsProps = {
  plans: PlanSeries[];
  money: (n: number) => string;
  barTitle: string;
  barLabels: { monthly: string; interest: string; total: string };
};

/** Bars comparing monthly payment, total interest, and total cost. */
export function CompareCharts({ plans, money, barTitle, barLabels }: CompareChartsProps) {
  const barGroups = useMemo(
    () => [
      {
        key: 'monthly',
        label: barLabels.monthly,
        values: plans.map((p) =>
          p.result.input.mode === 'equal-principal'
            ? p.result.firstMonthPayment
            : p.result.monthlyPayment,
        ),
      },
      {
        key: 'interest',
        label: barLabels.interest,
        values: plans.map((p) => p.result.totalInterest),
      },
      {
        key: 'total',
        label: barLabels.total,
        values: plans.map((p) => p.result.totalPayment),
      },
    ],
    [plans, barLabels],
  );

  const barMax = Math.max(1, ...barGroups.flatMap((g) => g.values));

  const barW = 320;
  const barH = 168;
  const barPad = { t: 12, r: 8, b: 36, l: 8 };
  const barInnerW = barW - barPad.l - barPad.r;
  const barInnerH = barH - barPad.t - barPad.b;
  const groupW = barInnerW / barGroups.length;
  const barGap = 3;
  const barSlot = (groupW - 16) / Math.max(plans.length, 1);

  return (
    <div className="loan-compare-charts">
      <div className="loan-card loan-compare-chart-card">
        <div className="loan-label">{barTitle}</div>
        <svg className="loan-compare-svg" viewBox={`0 0 ${barW} ${barH}`} role="img" aria-label={barTitle}>
          {barGroups.map((g, gi) => {
            const gx = barPad.l + gi * groupW + 8;
            return (
              <g key={g.key}>
                {g.values.map((v, pi) => {
                  const h = (v / barMax) * barInnerH;
                  const x = gx + pi * barSlot;
                  const y = barPad.t + barInnerH - h;
                  return (
                    <rect
                      key={`${g.key}-${pi}`}
                      x={x}
                      y={y}
                      width={Math.max(6, barSlot - barGap)}
                      height={Math.max(2, h)}
                      rx={4}
                      fill={plans[pi]?.color ?? COMPARE_PLAN_COLORS[pi]}
                    >
                      <title>{`${plans[pi]?.label}: ${money(v)}`}</title>
                    </rect>
                  );
                })}
                <text
                  x={gx + (groupW - 16) / 2}
                  y={barH - 12}
                  textAnchor="middle"
                  className="loan-compare-axis"
                >
                  {g.label}
                </text>
              </g>
            );
          })}
        </svg>
        <div className="loan-compare-legend">
          {plans.map((p) => (
            <span key={p.id} className="loan-compare-legend-item">
              <i style={{ background: p.color }} />
              {p.label}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
