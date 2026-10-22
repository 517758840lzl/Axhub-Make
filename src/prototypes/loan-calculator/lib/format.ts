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
      useGrouping: true,
    }).format(n);
  } catch {
    return `${cur.symbol}${n.toFixed(settings.decimals)}`;
  }
}

export function parseAmountString(raw: string): number | null {
  const s = raw.trim().replace(/,/g, '').replace(/，/g, '');
  if (!s || s.includes('-')) return null;
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
}

export function sanitizeDecimalInput(raw: string): string {
  let out = '';
  let dot = false;
  for (const ch of raw) {
    if (ch >= '0' && ch <= '9') out += ch;
    else if (ch === '.' && !dot) {
      dot = true;
      out += ch;
    }
  }
  return out;
}

/** Display form for an amount, such as 1000000 to 1,000,000. Keeps the decimal point. */
export function formatGroupedAmount(raw: string): string {
  if (!raw) return '';
  const dot = raw.indexOf('.');
  const intRaw = dot === -1 ? raw : raw.slice(0, dot);
  const frac = dot === -1 ? '' : raw.slice(dot);
  const digits = intRaw.replace(/\D/g, '');
  const grouped = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return `${grouped}${frac}`;
}

/** Turn a grouped amount back into digits and place the caret after formatting. */
export function editGroupedAmount(display: string, caret: number): { raw: string; caret: number } {
  const raw = sanitizeDecimalInput(display);
  const formatted = formatGroupedAmount(raw);
  const kept = sanitizeDecimalInput(display.slice(0, Math.max(0, caret))).length;
  if (kept === 0) return { raw, caret: 0 };
  let seen = 0;
  for (let i = 0; i < formatted.length; i++) {
    if (formatted[i] === ',') continue;
    seen += 1;
    if (seen === kept) return { raw, caret: i + 1 };
  }
  return { raw, caret: formatted.length };
}

export function currencyAmountUnit(settings: Pick<AppSettings, 'currencyCode'>): string {
  return getCurrency(settings.currencyCode).symbol;
}

/** User-facing date. Stored timestamps stay ISO-8601. */
export function formatShortDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  return `${dd}/${mm}/${d.getFullYear()}`;
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
