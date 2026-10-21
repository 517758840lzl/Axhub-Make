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
  { code: 'CHF', symbol: 'Fr', name: '瑞士法郎', locale: 'de-CH', defaultDecimals: 2 },
  { code: 'NZD', symbol: 'NZ$', name: '新西兰元', locale: 'en-NZ', defaultDecimals: 2 },
  { code: 'SEK', symbol: 'kr', name: '瑞典克朗', locale: 'sv-SE', defaultDecimals: 2 },
  { code: 'NOK', symbol: 'kr', name: '挪威克朗', locale: 'nb-NO', defaultDecimals: 2 },
  { code: 'DKK', symbol: 'kr', name: '丹麦克朗', locale: 'da-DK', defaultDecimals: 2 },
  { code: 'TWD', symbol: 'NT$', name: '新台币', locale: 'zh-TW', defaultDecimals: 0 },
  { code: 'MOP', symbol: 'MOP$', name: '澳门元', locale: 'zh-MO', defaultDecimals: 2 },
  { code: 'MYR', symbol: 'RM', name: '林吉特', locale: 'ms-MY', defaultDecimals: 2 },
  { code: 'PHP', symbol: '₱', name: '菲律宾比索', locale: 'en-PH', defaultDecimals: 2 },
  { code: 'IDR', symbol: 'Rp', name: '印尼盾', locale: 'id-ID', defaultDecimals: 0 },
  { code: 'VND', symbol: '₫', name: '越南盾', locale: 'vi-VN', defaultDecimals: 0 },
  { code: 'AED', symbol: 'د.إ', name: '阿联酋迪拉姆', locale: 'ar-AE', defaultDecimals: 2 },
  { code: 'SAR', symbol: '﷼', name: '沙特里亚尔', locale: 'ar-SA', defaultDecimals: 2 },
  { code: 'MXN', symbol: 'MX$', name: '墨西哥比索', locale: 'es-MX', defaultDecimals: 2 },
  { code: 'BRL', symbol: 'R$', name: '巴西雷亚尔', locale: 'pt-BR', defaultDecimals: 2 },
  { code: 'ZAR', symbol: 'R', name: '南非兰特', locale: 'en-ZA', defaultDecimals: 2 },
  { code: 'TRY', symbol: '₺', name: '土耳其里拉', locale: 'tr-TR', defaultDecimals: 2 },
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
