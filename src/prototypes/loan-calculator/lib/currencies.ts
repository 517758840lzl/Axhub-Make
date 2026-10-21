export type CurrencyOption = {
  code: string;
  symbol: string;
  name: string;
  locale: string;
  /** 常用默认小数位 */
  defaultDecimals: number;
};

export const CURRENCY_OPTIONS: CurrencyOption[] = [
  { code: 'CNY', symbol: '¥', name: 'Chinese Yuan', locale: 'zh-CN', defaultDecimals: 2 },
  { code: 'USD', symbol: '$', name: 'US Dollar', locale: 'en-US', defaultDecimals: 2 },
  { code: 'EUR', symbol: '€', name: 'Euro', locale: 'de-DE', defaultDecimals: 2 },
  { code: 'GBP', symbol: '£', name: 'British Pound', locale: 'en-GB', defaultDecimals: 2 },
  { code: 'INR', symbol: '₹', name: 'Indian Rupee', locale: 'en-IN', defaultDecimals: 2 },
  { code: 'JPY', symbol: '¥', name: 'Japanese Yen', locale: 'ja-JP', defaultDecimals: 0 },
  { code: 'HKD', symbol: 'HK$', name: 'Hong Kong Dollar', locale: 'zh-HK', defaultDecimals: 2 },
  { code: 'SGD', symbol: 'S$', name: 'Singapore Dollar', locale: 'en-SG', defaultDecimals: 2 },
  { code: 'AUD', symbol: 'A$', name: 'Australian Dollar', locale: 'en-AU', defaultDecimals: 2 },
  { code: 'CAD', symbol: 'C$', name: 'Canadian Dollar', locale: 'en-CA', defaultDecimals: 2 },
  { code: 'KRW', symbol: '₩', name: 'Korean Won', locale: 'ko-KR', defaultDecimals: 0 },
  { code: 'THB', symbol: '฿', name: 'Thai Baht', locale: 'th-TH', defaultDecimals: 2 },
  { code: 'CHF', symbol: 'Fr', name: 'Swiss Franc', locale: 'de-CH', defaultDecimals: 2 },
  { code: 'NZD', symbol: 'NZ$', name: 'New Zealand Dollar', locale: 'en-NZ', defaultDecimals: 2 },
  { code: 'SEK', symbol: 'kr', name: 'Swedish Krona', locale: 'sv-SE', defaultDecimals: 2 },
  { code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', locale: 'nb-NO', defaultDecimals: 2 },
  { code: 'DKK', symbol: 'kr', name: 'Danish Krone', locale: 'da-DK', defaultDecimals: 2 },
  { code: 'TWD', symbol: 'NT$', name: 'New Taiwan Dollar', locale: 'zh-TW', defaultDecimals: 0 },
  { code: 'MOP', symbol: 'MOP$', name: 'Macanese Pataca', locale: 'zh-MO', defaultDecimals: 2 },
  { code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', locale: 'ms-MY', defaultDecimals: 2 },
  { code: 'PHP', symbol: '₱', name: 'Philippine Peso', locale: 'en-PH', defaultDecimals: 2 },
  { code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', locale: 'id-ID', defaultDecimals: 0 },
  { code: 'VND', symbol: '₫', name: 'Vietnamese Dong', locale: 'vi-VN', defaultDecimals: 0 },
  { code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', locale: 'ar-AE', defaultDecimals: 2 },
  { code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', locale: 'ar-SA', defaultDecimals: 2 },
  { code: 'MXN', symbol: 'MX$', name: 'Mexican Peso', locale: 'es-MX', defaultDecimals: 2 },
  { code: 'BRL', symbol: 'R$', name: 'Brazilian Real', locale: 'pt-BR', defaultDecimals: 2 },
  { code: 'ZAR', symbol: 'R', name: 'South African Rand', locale: 'en-ZA', defaultDecimals: 2 },
  { code: 'TRY', symbol: '₺', name: 'Turkish Lira', locale: 'tr-TR', defaultDecimals: 2 },
];

const byCode = new Map(CURRENCY_OPTIONS.map((c) => [c.code, c]));

/** 列表不展示 CNY，新用户与旧的 CNY 偏好都落在美元。 */
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
