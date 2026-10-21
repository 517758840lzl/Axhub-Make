import React, { useLayoutEffect, useRef } from 'react';
import { editGroupedAmount, formatGroupedAmount } from '../lib/format';

export const AmountInput = React.forwardRef<
  HTMLInputElement,
  {
    value: string;
    onChange: (raw: string) => void;
    className?: string;
    placeholder?: string;
  }
>(function AmountInput({ value, onChange, className, placeholder }, forwardedRef) {
  const innerRef = useRef<HTMLInputElement>(null);
  const caret = useRef<number | null>(null);

  const setRefs = (node: HTMLInputElement | null) => {
    innerRef.current = node;
    if (typeof forwardedRef === 'function') forwardedRef(node);
    else if (forwardedRef) forwardedRef.current = node;
  };

  useLayoutEffect(() => {
    const el = innerRef.current;
    const pos = caret.current;
    if (!el || pos == null || document.activeElement !== el) return;
    el.setSelectionRange(pos, pos);
    caret.current = null;
  });

  return (
    <input
      ref={setRefs}
      className={['loan-input-amount', className].filter(Boolean).join(' ')}
      inputMode="decimal"
      placeholder={placeholder}
      value={formatGroupedAmount(value)}
      onChange={(e) => {
        const next = editGroupedAmount(e.target.value, e.target.selectionStart ?? e.target.value.length);
        caret.current = next.caret;
        onChange(next.raw);
      }}
    />
  );
});
