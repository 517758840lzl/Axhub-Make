import React from 'react';
import { PICKER_CURRENCIES } from '../lib/currencies';
import { type TranslateFn } from '../lib/i18n';

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
        </div>
      ) : null}
      <div className="loan-currency-grid" role="listbox" aria-label={t('currency.pick')}>
        {PICKER_CURRENCIES.map((c) => (
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
          </button>
        ))}
      </div>
    </div>
  );
}
