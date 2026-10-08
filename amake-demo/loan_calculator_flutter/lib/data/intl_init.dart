import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'currencies.dart';

bool _intlReady = false;

/// 加载 intl 本地化（日期与货币格式化依赖此项）
Future<void> initializeAppIntl() async {
  if (_intlReady) return;
  final locales = <String>{'zh_CN', 'en_US'};
  for (final c in currencyOptions) {
    locales.add(c.locale);
  }
  for (final locale in locales) {
    await initializeDateFormatting(locale);
  }
  _intlReady = true;
}

/// 中文短日期（记账 / 储蓄流水）
String formatShortDate(DateTime date) {
  return DateFormat.yMd('zh_CN').format(date);
}

String formatShortDateTime(DateTime date) {
  return DateFormat.yMd('zh_CN').add_Hm().format(date);
}
