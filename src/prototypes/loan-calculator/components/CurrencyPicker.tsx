import React from 'react';
import { CURRENCY_OPTIONS, getCurrency } from '../lib/currencies';
import { currencyNameKey, type TranslateFn } from '../lib/i18n';

type CurrencyPickerProps = {
  currencyCode: string;
  onChange: (code: string) => void;
  t: TranslateFn;
  compact?: boolean;
};

export function CurrencyPicker({
  currencyCode,
  onChange,
  t,
  compact,
}: CurrencyPickerProps) {
  const active = getCurrency(currencyCode);
  const activeNameKey = currencyNameKey(active.code);
  const activeName = activeNameKey ? t(activeNameKey) : active.name;

  return (
    <div
      className={
        compact
          ? 'loan-currency-picker loan-currency-picker--compact'
          : 'loan-currency-picker'
      }
    >
      {!compact ? (
        <div className="loan-currency-picker-head">
          <span className="loan-label" style={{ margin: 0 }}>
            {t('currency.label')}
          </span>
          <span className="loan-chip">
            {t('currency.current', { symbol: active.symbol, name: activeName })}
          </span>
        </div>
      ) : null}
      <div className="loan-currency-grid" role="listbox" aria-label={t('currency.pick')}>
        {CURRENCY_OPTIONS.map((c) => {
          const nameKey = currencyNameKey(c.code);
          return (
            <button
              key={c.code}
              type="button"
              role="option"
              aria-selected={c.code === currencyCode}
              className="loan-currency-option"
              data-active={c.code === currencyCode}
              onClick={() => onChange(c.code)}
            >
              <span className="loan-currency-option-symbol">{c.symbol}</span>
              <span className="loan-currency-option-code">{c.code}</span>
              {!compact ? (
                <span className="loan-currency-option-name">
                  {nameKey ? t(nameKey) : c.name}
                </span>
              ) : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}
