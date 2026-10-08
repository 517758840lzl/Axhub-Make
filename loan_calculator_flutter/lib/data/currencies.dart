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
];

CurrencyOption getCurrency(String code) =>
    currencyOptions.firstWhere((c) => c.code == code, orElse: () => currencyOptions.first);
