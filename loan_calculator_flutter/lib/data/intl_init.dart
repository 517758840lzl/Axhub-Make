import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'currencies.dart';

bool _intlReady = false;

/// Load intl data used by dates and currency formatting.
Future<void> initializeAppIntl() async {
  if (_intlReady) return;
  final locales = <String>{'en_US'};
  for (final c in currencyOptions) {
    locales.add(c.locale);
  }
  for (final locale in locales) {
    await initializeDateFormatting(locale);
  }
  _intlReady = true;
}

/// User-facing date: day/month/year. Stored timestamps stay ISO-8601.
String formatShortDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatShortDateTime(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}
