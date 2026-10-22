class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.locale,
    required this.defaultDecimals,
  });

  final String code;
  final String symbol;
  final String name;
  final String locale;
  final int defaultDecimals;
}

const currencyOptions = <CurrencyOption>[
  CurrencyOption(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', locale: 'zh_CN', defaultDecimals: 2),
  CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar', locale: 'en_US', defaultDecimals: 2),
  CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro', locale: 'de_DE', defaultDecimals: 2),
  CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound', locale: 'en_GB', defaultDecimals: 2),
  CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee', locale: 'en_IN', defaultDecimals: 2),
  CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen', locale: 'ja_JP', defaultDecimals: 0),
  CurrencyOption(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar', locale: 'zh_HK', defaultDecimals: 2),
  CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', locale: 'en_SG', defaultDecimals: 2),
  CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', locale: 'en_AU', defaultDecimals: 2),
  CurrencyOption(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', locale: 'en_CA', defaultDecimals: 2),
  CurrencyOption(code: 'KRW', symbol: '₩', name: 'Korean Won', locale: 'ko_KR', defaultDecimals: 0),
  CurrencyOption(code: 'THB', symbol: '฿', name: 'Thai Baht', locale: 'th_TH', defaultDecimals: 2),
  CurrencyOption(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc', locale: 'de_CH', defaultDecimals: 2),
  CurrencyOption(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', locale: 'en_NZ', defaultDecimals: 2),
  CurrencyOption(code: 'SEK', symbol: 'kr', name: 'Swedish Krona', locale: 'sv_SE', defaultDecimals: 2),
  CurrencyOption(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', locale: 'nb_NO', defaultDecimals: 2),
  CurrencyOption(code: 'DKK', symbol: 'kr', name: 'Danish Krone', locale: 'da_DK', defaultDecimals: 2),
  CurrencyOption(code: 'TWD', symbol: 'NT\$', name: 'New Taiwan Dollar', locale: 'zh_TW', defaultDecimals: 0),
  CurrencyOption(code: 'MOP', symbol: 'MOP\$', name: 'Macanese Pataca', locale: 'zh_MO', defaultDecimals: 2),
  CurrencyOption(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', locale: 'ms_MY', defaultDecimals: 2),
  CurrencyOption(code: 'PHP', symbol: '₱', name: 'Philippine Peso', locale: 'en_PH', defaultDecimals: 2),
  CurrencyOption(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', locale: 'id_ID', defaultDecimals: 0),
  CurrencyOption(code: 'VND', symbol: '₫', name: 'Vietnamese Dong', locale: 'vi_VN', defaultDecimals: 0),
  CurrencyOption(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', locale: 'ar_AE', defaultDecimals: 2),
  CurrencyOption(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', locale: 'ar_SA', defaultDecimals: 2),
  CurrencyOption(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso', locale: 'es_MX', defaultDecimals: 2),
  CurrencyOption(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', locale: 'pt_BR', defaultDecimals: 2),
  CurrencyOption(code: 'ZAR', symbol: 'R', name: 'South African Rand', locale: 'en_ZA', defaultDecimals: 2),
  CurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira', locale: 'tr_TR', defaultDecimals: 2),
];

const defaultCurrencyCode = 'USD';

List<CurrencyOption> get pickerCurrencies =>
    currencyOptions.where((c) => c.code != 'CNY').toList();

/// The picker hides CNY. A missing, CNY, or unknown code resolves to USD.
String resolveCurrencyCode(String? code) {
  if (code != null && pickerCurrencies.any((c) => c.code == code)) return code;
  return defaultCurrencyCode;
}

CurrencyOption getCurrency(String code) => currencyOptions.firstWhere(
      (c) => c.code == code,
      orElse: () => currencyOptions.firstWhere((c) => c.code == defaultCurrencyCode),
    );
