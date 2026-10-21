export type CurrencyOption = {
  code: string;
  symbol: string;
  name: string;
  locale: string;
  /** 常用默认小数位 */
  defaultDecimals: number;
};

export const CURRENCY_OPTIONS: CurrencyOption[] = [
  { code: 'CNY', symbol: '¥', name: '人民币', locale: 'zh-CN', defaultDecimals: 2 },
  { code: 'USD', symbol: '$', name: '美元', locale: 'en-US', defaultDecimals: 2 },
  { code: 'EUR', symbol: '€', name: '欧元', locale: 'de-DE', defaultDecimals: 2 },
  { code: 'GBP', symbol: '£', name: '英镑', locale: 'en-GB', defaultDecimals: 2 },
  { code: 'INR', symbol: '₹', name: '印度卢比', locale: 'en-IN', defaultDecimals: 2 },
  { code: 'JPY', symbol: '¥', name: '日元', locale: 'ja-JP', defaultDecimals: 0 },
  { code: 'HKD', symbol: 'HK$', name: '港币', locale: 'zh-HK', defaultDecimals: 2 },
  { code: 'SGD', symbol: 'S$', name: '新元', locale: 'en-SG', defaultDecimals: 2 },
  { code: 'AUD', symbol: 'A$', name: '澳元', locale: 'en-AU', defaultDecimals: 2 },
  { code: 'CAD', symbol: 'C$', name: '加元', locale: 'en-CA', defaultDecimals: 2 },
  { code: 'KRW', symbol: '₩', name: '韩元', locale: 'ko-KR', defaultDecimals: 0 },
  { code: 'THB', symbol: '฿', name: '泰铢', locale: 'th-TH', defaultDecimals: 2 },
];

const byCode = new Map(CURRENCY_OPTIONS.map((c) => [c.code, c]));

/** 列表不展示 CNY，新用户与旧的人民币偏好都落在美元。 */
export const DEFAULT_CURRENCY_CODE = 'USD';

export const PICKER_CURRENCIES = CURRENCY_OPTIONS.filter((c) => c.code !== 'CNY');

export function getCurrency(code: string): CurrencyOption {
  return byCode.get(code) ?? byCode.get(DEFAULT_CURRENCY_CODE)!;
}

export function resolveCurrencyCode(legacy: { currencyCode?: string; currency?: string }): string {
  if (legacy.currencyCode && PICKER_CURRENCIES.some((c) => c.code === legacy.currencyCode)) {
    return legacy.currencyCode;
  }
  const fromSymbol = PICKER_CURRENCIES.find((c) => c.symbol === legacy.currency);
  return fromSymbol?.code ?? DEFAULT_CURRENCY_CODE;
}
