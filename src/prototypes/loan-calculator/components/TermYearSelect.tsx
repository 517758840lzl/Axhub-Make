import React, { useEffect, useRef, useState } from 'react';
import { ChevronDown } from 'lucide-react';
import { useApp } from '../context';

export function TermYearSelect({
  value,
  maxYears,
  error = false,
  onChange,
}: {
  value: string;
  maxYears: number;
  error?: boolean;
  onChange: (years: string) => void;
}) {
  const { t } = useApp();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const options = Array.from({ length: maxYears }, (_, i) => String(maxYears - i));
  const display = options.includes(value) ? value : value || options[0] || '1';

  useEffect(() => {
    if (!open) return;
    const onPointerDown = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, [open]);

  return (
    <div className="loan-term-select" ref={rootRef}>
      <button
        type="button"
        className={`loan-term-select-trigger ${error ? 'loan-input-error' : ''}`}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label={t('home.term')}
        onClick={() => setOpen((v) => !v)}
      >
        <span>{t('home.yearsN', { n: display })}</span>
        <ChevronDown size={18} aria-hidden className="loan-term-select-chevron" data-open={open} />
      </button>
      {open ? (
        <div className="loan-term-select-list" role="listbox">
          {options.map((year) => (
            <button
              key={year}
              type="button"
              role="option"
              className="loan-term-select-option"
              aria-selected={year === value}
              onClick={() => {
                onChange(year);
                setOpen(false);
              }}
            >
              {t('home.yearsN', { n: year })}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
