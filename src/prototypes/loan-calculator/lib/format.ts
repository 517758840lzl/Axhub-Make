import type { AppSettings } from './types';
import { getCurrency } from './currencies';

export function formatMoney(
  value: number,
  settings: Pick<AppSettings, 'currencyCode' | 'decimals'>,
): string {
  const n = Number.isFinite(value) ? value : 0;
  const cur = getCurrency(settings.currencyCode);
  try {
    return new Intl.NumberFormat(cur.locale, {
      style: 'currency',
      currency: cur.code,
      minimumFractionDigits: settings.decimals,
      maximumFractionDigits: settings.decimals,
    }).format(n);
  } catch {
    return `${cur.symbol}${n.toFixed(settings.decimals)}`;
  }
}

export function formatPercent(value: number, decimals = 2): string {
  return `${value.toFixed(decimals)}%`;
}

export function parseHashParams(): URLSearchParams {
  if (typeof window === 'undefined') return new URLSearchParams();
  return new URLSearchParams(window.location.hash.replace(/^#/, ''));
}

export function setHashPage(page: string, extra?: Record<string, string>) {
  const params = new URLSearchParams();
  params.set('page', page);
  if (extra) {
    for (const [k, v] of Object.entries(extra)) {
      if (v) params.set(k, v);
    }
  }
  window.location.hash = params.toString();
}

export function uid(prefix: string): string {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}
