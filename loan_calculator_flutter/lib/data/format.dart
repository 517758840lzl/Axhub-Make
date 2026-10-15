import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'currencies.dart';
import 'models.dart';

String uid(String prefix) => '$prefix-${const Uuid().v4().substring(0, 8)}';

NumberFormat? _moneyFmt;
String? _moneyFmtKey;

String formatMoney(double value, AppSettings settings) {
  final key = '${settings.currencyCode}|${settings.decimals}';
  var fmt = _moneyFmt;
  if (fmt == null || _moneyFmtKey != key) {
    final cur = getCurrency(settings.currencyCode);
    fmt = NumberFormat.currency(
      locale: cur.locale.replaceAll('_', '-'),
      name: cur.code,
      symbol: cur.symbol,
      decimalDigits: settings.decimals,
    );
    _moneyFmt = fmt;
    _moneyFmtKey = key;
  }
  return fmt.format(value);
}

String formatShortDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

String formatShortDateTime(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);
