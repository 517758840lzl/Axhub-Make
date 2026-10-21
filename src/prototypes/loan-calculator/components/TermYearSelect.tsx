import React, { useEffect, useRef, useState } from 'react';
import { Calendar } from 'lucide-react';
import { useApp } from '../context';

const MONTH_PRESETS = [3, 6, 9, 12];

function yearPresets(maxYears: number) {
  const source = maxYears <= 5 ? [1, 2, 3, 5] : [1, 5, 10, 15, 20, 25, 30];
  return source.filter((year) => year <= maxYears);
}

export function TermYearSelect({
  years,
  months,
  maxYears,
  error = false,
  onChange,
}: {
  years: string;
  months: string;
  maxYears: number;
  error?: boolean;
  onChange: (years: string, months: string) => void;
}) {
  const { t } = useApp();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const yearValue = Math.max(0, Number.parseInt(years, 10) || 0);
  const monthValue = Math.max(0, Number.parseInt(months, 10) || 0);
  const byMonth = monthValue > 0 && yearValue === 0;
  const presets = byMonth ? MONTH_PRESETS : yearPresets(maxYears);
  const showCustom = !byMonth && maxYears > 5;
  const customSelected = showCustom && (monthValue !== 0 || !presets.includes(yearValue));
  const valueLabel = byMonth
    ? t('home.monthsN', { n: String(monthValue) })
    : t('home.yearsN', { n: String(yearValue <= 0 ? 1 : yearValue) });
  const optionCount = byMonth ? Math.min(12, Math.max(1, maxYears * 12)) : maxYears;
  const options = Array.from({ length: optionCount }, (_, index) => String(optionCount - index));
  const current = byMonth ? String(monthValue) : String(yearValue);

  useEffect(() => {
    if (!open) return;
    const onPointerDown = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, [open]);

  const setUnit = (nextByMonth: boolean) => {
    setOpen(false);
    if (nextByMonth === byMonth) return;
    if (nextByMonth) {
      onChange('0', yearValue === 1 && monthValue === 0 ? '12' : '6');
      return;
    }
    const nextYears = monthValue > 0 && monthValue % 12 === 0 ? String(monthValue / 12) : '1';
    const clamped = Math.min(maxYears, Math.max(1, Number(nextYears)));
    onChange(String(clamped), '0');
  };

  return (
    <div className={`loan-term-picker ${error ? 'loan-term-picker-error' : ''}`} ref={rootRef}>
      <div className="loan-segment">
        <button type="button" data-active={byMonth} onClick={() => setUnit(true)}>
          {t('home.termByMonth')}
        </button>
        <button type="button" data-active={!byMonth} onClick={() => setUnit(false)}>
          {t('home.termByYear')}
        </button>
      </div>
      <div className="loan-term-value">
        <strong>{valueLabel}</strong>
        <button
          type="button"
          className="loan-term-calendar"
          aria-label={t('home.termCustom')}
          aria-expanded={open}
          onClick={() => setOpen((value) => !value)}
        >
          <Calendar size={20} aria-hidden />
        </button>
      </div>
      <div className="loan-term-chips">
        {presets.map((preset) => {
          const selected = byMonth ? monthValue === preset : yearValue === preset && monthValue === 0;
          const label = byMonth
            ? t('home.monthsN', { n: String(preset) })
            : t('home.yearsN', { n: String(preset) });
          return (
            <button
              key={preset}
              type="button"
              className="loan-quick-chip"
              data-active={selected}
              onClick={() => {
                setOpen(false);
                if (byMonth) onChange('0', String(preset));
                else onChange(String(preset), '0');
              }}
            >
              {label}
            </button>
          );
        })}
        {showCustom ? (
          <button
            type="button"
            className="loan-quick-chip"
            data-active={customSelected}
            onClick={() => setOpen(true)}
          >
            {t('home.termCustom')}
          </button>
        ) : null}
      </div>
      {open ? (
        <div className="loan-term-select-list" role="listbox">
          {options.map((option) => (
            <button
              key={option}
              type="button"
              role="option"
              className="loan-term-select-option"
              aria-selected={option === current}
              onClick={() => {
                if (byMonth) onChange('0', option);
                else onChange(option, '0');
                setOpen(false);
              }}
            >
              {byMonth ? t('home.monthsN', { n: option }) : t('home.yearsN', { n: option })}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
