import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/loan_widgets.dart';

class ProfileTextScreen extends StatelessWidget {
  const ProfileTextScreen({super.key, required this.titleKey, required this.bodyKey});

  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final paragraphs = app
        .tr(bodyKey)
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanTopBar(onBack: () => app.pop(), title: app.tr(titleKey)),
        LoanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < paragraphs.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                LoanMuted(paragraphs[i], fontSize: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
