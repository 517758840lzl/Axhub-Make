import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/calc.dart';
import '../data/currencies.dart';
import '../data/format.dart';
import '../data/i18n.dart';
import '../data/models.dart';
import '../data/savings_insights.dart';
import '../state/app_state.dart';
import '../theme/revolut_theme.dart';
import '../widgets/compare_bar_chart.dart';
import '../widgets/currency_picker.dart';
import '../widgets/donut_chart.dart';
import '../widgets/loan_widgets.dart';

part 'calc_home.dart';
part 'calc_result.dart';
part 'amort_page.dart';
part 'compare_page.dart';
part 'savings_list.dart';
part 'savings_new.dart';
part 'savings_detail.dart';
part 'saved_list.dart';
part 'saved_detail.dart';
part 'profile_home.dart';
part 'profile_edit.dart';
part 'profile_settings.dart';
part 'profile_data.dart';
part 'profile_text.dart';

String _savingsName(String name, AppState app) => displaySavingsName(app.locale, name);

String _savedTitle(String note, CalcResult result, AppState app) {
  final n = note.trim();
  if (n.isEmpty) return categoryLabel(result.input.category, app.locale);
  return displayKnownCopy(app.locale, n);
}


extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}

class RedirectCalcScreen extends StatelessWidget {
  const RedirectCalcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return EmptyRedirectScreen(
      message: app.tr('home.fillFirst'),
      onGo: () => app.goTab(0),
    );
  }
}

class EmptyRedirectScreen extends StatelessWidget {
  const EmptyRedirectScreen({super.key, required this.message, required this.onGo});
  final String message;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      children: [
        LoanEmpty(
          icon: const Icon(LucideIcons.circleAlert, size: 40, color: RevolutColors.brandSolid),
          message: message,
          action: LoanPrimaryButton(label: app.tr('common.back'), onPressed: onGo),
        ),
      ],
    );
  }
}
