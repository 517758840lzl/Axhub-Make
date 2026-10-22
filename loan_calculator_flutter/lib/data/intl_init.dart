import 'package:intl/date_symbol_data_local.dart';

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
