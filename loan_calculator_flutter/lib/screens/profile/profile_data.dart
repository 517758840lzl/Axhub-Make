import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/loan_widgets.dart';

class ProfileDataScreen extends StatelessWidget {
  const ProfileDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr('data.title')),
        LoanSecondaryButton(
          label: app.tr('data.clear'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(app.tr('data.clear')),
                content: Text(app.tr('data.confirm')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(app.tr('common.back'))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(app.tr('data.clear'))),
                ],
              ),
            );
            if (ok == true) {
              await app.clearBusiness();
              app.showToast(app.tr('data.cleared'));
            }
          },
        ),
        const SizedBox(height: 12),
        LoanMuted(app.tr('data.hint'), fontSize: 12),
      ],
    );
  }
}
