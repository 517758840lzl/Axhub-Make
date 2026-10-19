import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/currencies.dart';
import '../../data/i18n.dart';
import '../../state/app_state.dart';
import '../../widgets/currency_picker.dart';
import '../../widgets/loan_widgets.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late int _decimals;
  late AppLocale _locale;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _decimals = app.settings.decimals;
    _locale = app.settings.locale;
    _currency = app.settings.currencyCode;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('settings.title')),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoanLabel(app.tr('settings.language')),
              LoanSegment(
                options: appLocales.map((e) => (e.$1.id, e.$2)).toList(),
                selected: _locale.id,
                onSelect: (v) => setState(() => _locale = AppLocaleX.fromId(v)),
              ),
              LoanLabel(app.tr('settings.decimals'), marginTop: 12),
              LoanSegment(
                options: const [('0', '0'), ('2', '2')],
                selected: '$_decimals',
                onSelect: (v) => setState(() => _decimals = int.parse(v)),
              ),
              LoanLabel(app.tr('currency.label'), marginTop: 12),
              CurrencyPicker(
                currencyCode: _currency,
                onChange: (c) => setState(() {
                  _currency = c;
                  _decimals = getCurrency(c).defaultDecimals;
                }),
              ),
            ],
          ),
        ),
        LoanPrimaryButton(
          label: app.tr('settings.save'),
          onPressed: () async {
            await app.updateSettings(app.settings.copyWith(
              decimals: _decimals,
              locale: _locale,
              currencyCode: _currency,
            ));
            app.showToast(app.tr('toast.savedProfile'));
            app.pop();
          },
        ),
      ],
    );
  }
}
