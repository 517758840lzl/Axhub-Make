import React, { useEffect, useState } from 'react';

type DonutSegment = {
  value: number;
  color: string;
  label: string;
  /** 环外明细金额文案，如 ¥1,000.00；不进圆心 */
  amountText?: string;
};

type DonutProps = {
  segments: DonutSegment[];
  size?: number;
  stroke?: number;
  /** 圆心主文案：宜短，如 39% / 35% */
  centerValue: string;
  /** 圆心副文案：如 利息占比 / 已完成 */
  centerCaption?: string;
  animate?: boolean;
};

/**
 * 环内只放短指标；完整金额放在环下明细行（避免长金额撑破圆环）。
 */
export function Donut({
  segments,
  size = 160,
  stroke = 14,
  centerValue,
  centerCaption,
  animate = true,
}: DonutProps) {
  const [progress, setProgress] = useState(animate ? 0 : 1);
  const total = segments.reduce((s, x) => s + Math.max(0, x.value), 0) || 1;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  let offset = 0;

  useEffect(() => {
    if (!animate) return;
    const t = window.requestAnimationFrame(() => setProgress(1));
    return () => window.cancelAnimationFrame(t);
  }, [animate, segments]);

  return (
    <div className="loan-donut-wrap">
      <div className="loan-donut-chart" style={{ width: size, height: size }}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} aria-hidden>
          <circle
            cx={size / 2}
            cy={size / 2}
            r={r}
            fill="none"
            stroke="var(--rev-donut-track, #e2e5f0)"
            strokeWidth={stroke}
          />
          {segments.map((seg) => {
            const len = (Math.max(0, seg.value) / total) * c * progress;
            const dash = `${len} ${c - len}`;
            const el = (
              <circle
                key={seg.label}
                cx={size / 2}
                cy={size / 2}
                r={r}
                fill="none"
                stroke={seg.color}
                strokeWidth={stroke}
                strokeDasharray={dash}
                strokeDashoffset={-offset}
                transform={`rotate(-90 ${size / 2} ${size / 2})`}
                strokeLinecap="butt"
              />
            );
            offset += (Math.max(0, seg.value) / total) * c;
            return el;
          })}
        </svg>
        <div className="loan-donut-center">
          <div className="loan-donut-center-value">{centerValue}</div>
          {centerCaption ? (
            <div className="loan-donut-center-caption">{centerCaption}</div>
          ) : null}
        </div>
      </div>

      <div className="loan-donut-breakdown">
        {segments.map((s) => (
          <div key={s.label} className="loan-donut-breakdown-row">
            <span className="loan-donut-breakdown-label">
              <i style={{ background: s.color }} />
              {s.label}
            </span>
            <span className="loan-donut-breakdown-amount">
              {s.amountText ?? `${((Math.max(0, s.value) / total) * 100).toFixed(0)}%`}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
