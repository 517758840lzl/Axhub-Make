import type { LoanCategory } from './types';

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
  return [...set].sort((a, b) => a.localeCompare(b, 'zh-CN'));
}
