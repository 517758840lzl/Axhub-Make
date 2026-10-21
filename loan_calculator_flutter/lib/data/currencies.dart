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
  CurrencyOption(code: 'CNY', symbol: '¥', name: '人民币', locale: 'zh_CN', defaultDecimals: 2),
  CurrencyOption(code: 'USD', symbol: '\$', name: '美元', locale: 'en_US', defaultDecimals: 2),
  CurrencyOption(code: 'EUR', symbol: '€', name: '欧元', locale: 'de_DE', defaultDecimals: 2),
  CurrencyOption(code: 'GBP', symbol: '£', name: '英镑', locale: 'en_GB', defaultDecimals: 2),
  CurrencyOption(code: 'INR', symbol: '₹', name: '印度卢比', locale: 'en_IN', defaultDecimals: 2),
  CurrencyOption(code: 'JPY', symbol: '¥', name: '日元', locale: 'ja_JP', defaultDecimals: 0),
  CurrencyOption(code: 'HKD', symbol: 'HK\$', name: '港币', locale: 'zh_HK', defaultDecimals: 2),
  CurrencyOption(code: 'SGD', symbol: 'S\$', name: '新元', locale: 'en_SG', defaultDecimals: 2),
  CurrencyOption(code: 'AUD', symbol: 'A\$', name: '澳元', locale: 'en_AU', defaultDecimals: 2),
  CurrencyOption(code: 'CAD', symbol: 'C\$', name: '加元', locale: 'en_CA', defaultDecimals: 2),
  CurrencyOption(code: 'KRW', symbol: '₩', name: '韩元', locale: 'ko_KR', defaultDecimals: 0),
  CurrencyOption(code: 'THB', symbol: '฿', name: '泰铢', locale: 'th_TH', defaultDecimals: 2),
  CurrencyOption(code: 'CHF', symbol: 'Fr', name: '瑞士法郎', locale: 'de_CH', defaultDecimals: 2),
  CurrencyOption(code: 'NZD', symbol: 'NZ\$', name: '新西兰元', locale: 'en_NZ', defaultDecimals: 2),
  CurrencyOption(code: 'SEK', symbol: 'kr', name: '瑞典克朗', locale: 'sv_SE', defaultDecimals: 2),
  CurrencyOption(code: 'NOK', symbol: 'kr', name: '挪威克朗', locale: 'nb_NO', defaultDecimals: 2),
  CurrencyOption(code: 'DKK', symbol: 'kr', name: '丹麦克朗', locale: 'da_DK', defaultDecimals: 2),
  CurrencyOption(code: 'TWD', symbol: 'NT\$', name: '新台币', locale: 'zh_TW', defaultDecimals: 0),
  CurrencyOption(code: 'MOP', symbol: 'MOP\$', name: '澳门元', locale: 'zh_MO', defaultDecimals: 2),
  CurrencyOption(code: 'MYR', symbol: 'RM', name: '林吉特', locale: 'ms_MY', defaultDecimals: 2),
  CurrencyOption(code: 'PHP', symbol: '₱', name: '菲律宾比索', locale: 'en_PH', defaultDecimals: 2),
  CurrencyOption(code: 'IDR', symbol: 'Rp', name: '印尼盾', locale: 'id_ID', defaultDecimals: 0),
  CurrencyOption(code: 'VND', symbol: '₫', name: '越南盾', locale: 'vi_VN', defaultDecimals: 0),
  CurrencyOption(code: 'AED', symbol: 'د.إ', name: '阿联酋迪拉姆', locale: 'ar_AE', defaultDecimals: 2),
  CurrencyOption(code: 'SAR', symbol: '﷼', name: '沙特里亚尔', locale: 'ar_SA', defaultDecimals: 2),
  CurrencyOption(code: 'MXN', symbol: 'MX\$', name: '墨西哥比索', locale: 'es_MX', defaultDecimals: 2),
  CurrencyOption(code: 'BRL', symbol: 'R\$', name: '巴西雷亚尔', locale: 'pt_BR', defaultDecimals: 2),
  CurrencyOption(code: 'ZAR', symbol: 'R', name: '南非兰特', locale: 'en_ZA', defaultDecimals: 2),
  CurrencyOption(code: 'TRY', symbol: '₺', name: '土耳其里拉', locale: 'tr_TR', defaultDecimals: 2),
];

const defaultCurrencyCode = 'USD';

List<CurrencyOption> get pickerCurrencies =>
    currencyOptions.where((c) => c.code != 'CNY').toList();

/// 列表不展示 CNY。缺失、人民币或未知代码都落在美元。
String resolveCurrencyCode(String? code) {
  if (code != null && pickerCurrencies.any((c) => c.code == code)) return code;
  return defaultCurrencyCode;
}

CurrencyOption getCurrency(String code) => currencyOptions.firstWhere(
      (c) => c.code == code,
      orElse: () => currencyOptions.firstWhere((c) => c.code == defaultCurrencyCode),
    );
