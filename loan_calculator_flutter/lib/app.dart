import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/loan_screens.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/revolut_theme.dart';
import 'widgets/loan_widgets.dart';

class LoanCalculatorApp extends StatelessWidget {
  const LoanCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: '贷款计算器',
        debugShowCheckedModeBanner: false,
        theme: buildRevolutTheme(),
        home: const _AppHost(),
      ),
    );
  }
}

class _AppHost extends StatefulWidget {
  const _AppHost();

  @override
  State<_AppHost> createState() => _AppHostState();
}

class _AppHostState extends State<_AppHost> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey('splash'),
              onComplete: () => setState(() => _showSplash = false),
            )
          : const LoanRoot(key: ValueKey('main')),
    );
  }
}

class LoanRoot extends StatelessWidget {
  const LoanRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        if (!app.ready) {
          return const Scaffold(
            backgroundColor: RevolutColors.canvas,
            body: Center(
              child: CircularProgressIndicator(color: RevolutColors.brandSolid),
            ),
          );
        }

        final onSavingsList = app.route == AppRoute.savings && app.savingsGoals.isNotEmpty;
        return LoanShell(
          toast: app.toast,
          showTabBar: showTabBarForRoute(app.route),
          activeTab: app.activeTabIndex,
          onTab: app.goTab,
          fab: onSavingsList
              ? LoanFab(onPressed: () => app.push(AppRoute.savingsNew))
              : null,
          body: _screenForRoute(app),
        );
      },
    );
  }

  Widget _screenForRoute(AppState app) {
    switch (app.route) {
      case AppRoute.calc:
        return const CalcHomeScreen();
      case AppRoute.calcResult:
        return const CalcResultScreen();
      case AppRoute.amortization:
        return const AmortizationScreen();
      case AppRoute.savings:
        return const SavingsListScreen();
      case AppRoute.savingsNew:
        return const SavingsNewScreen();
      case AppRoute.savingsDetail:
        return const SavingsDetailScreen();
      case AppRoute.ledger:
        return const LedgerHomeScreen();
      case AppRoute.ledgerNew:
        return const LedgerNewScreen();
      case AppRoute.ledgerCalcDetail:
        return const LedgerCalcDetailScreen();
      case AppRoute.ledgerManualDetail:
        return const LedgerManualDetailScreen();
      case AppRoute.profile:
        return const ProfileHomeScreen();
      case AppRoute.profileSettings:
        return const ProfileSettingsScreen();
      case AppRoute.profileData:
        return const ProfileDataScreen();
      case AppRoute.profileAbout:
        return const ProfileAboutScreen();
    }
  }
}
