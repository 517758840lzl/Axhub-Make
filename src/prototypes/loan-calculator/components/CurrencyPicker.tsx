import React from 'react';
import { CURRENCY_OPTIONS, getCurrency } from '../lib/currencies';

type CurrencyPickerProps = {
  currencyCode: string;
  onChange: (code: string) => void;
  compact?: boolean;
};

export function CurrencyPicker({ currencyCode, onChange, compact }: CurrencyPickerProps) {
  const active = getCurrency(currencyCode);

  return (
    <div className={compact ? 'loan-currency-picker loan-currency-picker--compact' : 'loan-currency-picker'}>
      {!compact ? (
        <div className="loan-currency-picker-head">
          <span className="loan-label" style={{ margin: 0 }}>
            显示货币
          </span>
          <span className="loan-chip">
            当前 {active.symbol} {active.name}
          </span>
        </div>
      ) : null}
      <div className="loan-currency-grid" role="listbox" aria-label="选择货币">
        {CURRENCY_OPTIONS.map((c) => (
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
              <span className="loan-currency-option-name">{c.name}</span>
            ) : null}
          </button>
        ))}
      </div>
    </div>
  );
}
