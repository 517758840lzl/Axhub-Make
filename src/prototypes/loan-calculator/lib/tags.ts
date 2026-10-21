import type { MessageKey, TranslateFn } from './i18n';
import type { LoanCategory } from './types';

const TAG_MESSAGE_KEY: Record<string, MessageKey> = {
  房贷: 'tag.mortgage',
  车贷: 'tag.auto',
  消费贷: 'tag.consumer',
  月供: 'tag.payment',
  保险: 'tag.insurance',
  装修: 'tag.reno',
  教育: 'tag.edu',
  医疗: 'tag.medical',
  日常: 'tag.daily',
  其他: 'tag.other',
  组合贷: 'cat.dual',
};

export function tagLabel(tag: string, t: TranslateFn): string {
  const key = TAG_MESSAGE_KEY[tag];
  return key ? t(key) : tag;
}

/** 常用标签，供选择；用户可自定义追加 */
export const SUGGESTED_TAGS = [
  '房贷',
  '车贷',
  '消费贷',
  '月供',
  '保险',
  '装修',
  '教育',
  '医疗',
  '日常',
  '其他',
] as const;

const CATEGORY_TAG: Record<LoanCategory, string> = {
  mortgage: '房贷',
  auto: '车贷',
  personal: '消费贷',
  dual: '组合贷',
  other: '其他',
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
