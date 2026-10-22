import type { MessageKey, TranslateFn } from './i18n';
import type { LoanCategory } from './types';

const TAG_MESSAGE_KEY: Record<string, MessageKey> = {
  mortgage: 'tag.mortgage',
  auto: 'tag.auto',
  consumer: 'tag.consumer',
  payment: 'tag.payment',
  insurance: 'tag.insurance',
  reno: 'tag.reno',
  edu: 'tag.edu',
  medical: 'tag.medical',
  daily: 'tag.daily',
  other: 'tag.other',
  dual: 'cat.dual',
};

export function tagLabel(tag: string, t: TranslateFn): string {
  const key = TAG_MESSAGE_KEY[tag];
  return key ? t(key) : tag;
}

/** Suggested tags. Users can add their own. */
export const SUGGESTED_TAGS = [
  'mortgage',
  'auto',
  'consumer',
  'payment',
  'insurance',
  'reno',
  'edu',
  'medical',
  'daily',
  'other',
] as const;

const CATEGORY_TAG: Record<LoanCategory, string> = {
  mortgage: 'mortgage',
  auto: 'auto',
  personal: 'consumer',
  dual: 'dual',
  other: 'other',
};

export function defaultTagsForCategory(category: LoanCategory): string[] {
  return [CATEGORY_TAG[category]];
}

export function normalizeTagList(tags: string[] | undefined): string[] {
  if (!tags?.length) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const t of tags) {
    const s = t.trim();
    if (!s || seen.has(s)) continue;
    seen.add(s);
    out.push(s);
    if (out.length >= 8) break;
  }
  return out;
}

export function collectAllTags(
  calcTags: string[][],
  manualTags: string[][],
): string[] {
  const set = new Set<string>();
  for (const list of [...calcTags, ...manualTags]) {
    for (const t of list) set.add(t);
  }
  return [...set].sort((a, b) => a.localeCompare(b, 'en'));
}
