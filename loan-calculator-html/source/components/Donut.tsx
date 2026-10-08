import React, { useEffect, useState } from 'react';

type DonutProps = {
  segments: { value: number; color: string; label: string }[];
  size?: number;
  stroke?: number;
  centerLabel: string;
  centerSub?: string;
  animate?: boolean;
};

export function Donut({
  segments,
  size = 160,
  stroke = 14,
  centerLabel,
  centerSub,
  animate = true,
}: DonutProps) {
  const [progress, setProgress] = useState(animate ? 0 : 1);
  const total = segments.reduce((s, x) => s + x.value, 0) || 1;
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
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--rev-donut-track, #e2e5f0)"
          strokeWidth={stroke}
        />
        {segments.map((seg) => {
          const len = (seg.value / total) * c * progress;
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
          offset += (seg.value / total) * c;
          return el;
        })}
      </svg>
      <div style={{ marginTop: -size + 8, textAlign: 'center', pointerEvents: 'none' }}>
        <div className="loan-hero-amount" style={{ fontSize: 22 }}>
          {centerLabel}
        </div>
        {centerSub ? (
          <div className="loan-donut-sub">{centerSub}</div>
        ) : null}
      </div>
      <div className="loan-donut-legend">
        {segments.map((s) => (
          <span key={s.label}>
            <i style={{ background: s.color }} />
            {s.label}
          </span>
        ))}
      </div>
    </div>
  );
}
