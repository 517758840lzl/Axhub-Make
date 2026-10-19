part of 'loan_screens.dart';

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
