import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../calc/calc_result.dart';
import '../screen_shared.dart';

class SavedDetailScreen extends StatelessWidget {
  const SavedDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = app.calculations.where((c) => c.id == app.detailId).firstOrNull;
    if (item == null) {
      return EmptyRedirectScreen(
        message: app.tr('common.missing'),
        onGo: () => app.replaceRoute(AppRoute.savedList),
      );
    }
    // Ensure pending mirrors saved item (idempotent if already set by list tap).
    if (app.pendingSavedId != item.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<AppState>().setPendingResult(item.result, savedId: item.id);
        }
      });
    }
    return const CalcResultScreen();
  }
}
