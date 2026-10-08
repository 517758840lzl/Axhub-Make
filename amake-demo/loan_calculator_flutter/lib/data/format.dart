import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'currencies.dart';
import 'models.dart';

String uid(String prefix) => '$prefix-${const Uuid().v4().substring(0, 8)}';

String formatMoney(double value, AppSettings settings) {
  final cur = getCurrency(settings.currencyCode);
  final locale = cur.locale.replaceAll('_', '-');
  final fmt = NumberFormat.currency(
    locale: locale,
    name: cur.code,
    symbol: cur.symbol,
    decimalDigits: settings.decimals,
  );
  return fmt.format(value);
}
