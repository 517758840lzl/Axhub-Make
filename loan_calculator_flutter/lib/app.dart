import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/i18n.dart';
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: revolutSystemUi,
        child: MaterialApp(
          title: '贷款计算器',
          debugShowCheckedModeBanner: false,
          theme: buildRevolutTheme(),
          builder: (context, child) {
            // 点空白处收起键盘（全页生效）
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            );
          },
          home: const _AppHost(),
        ),
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
    // 底层始终铺画布色，避免 Splash 切换瞬间露出系统黑底
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final app = context.read<AppState>();
        if (app.canPopRoute) {
          app.pop();
          return;
        }
        // 根页面退到后台，不结束 Activity，再次打开不用重走启动页
        SystemNavigator.pop();
      },
      child: ColoredBox(
        color: RevolutColors.canvas,
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onComplete: () => setState(() => _showSplash = false),
              )
            : const LoanRoot(key: ValueKey('main')),
        ),
      ),
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
          tabLabels: [
            app.tr('tab.calc'),
            app.tr('tab.savings'),
            app.tr('tab.profile'),
          ],
          fab: onSavingsList
              ? LoanFab(
                  label: app.tr('savings.fab'),
                  onPressed: () => app.push(AppRoute.savingsNew),
                )
              : null,
          scrollResetKey: ValueKey(
            '${app.route.name}|${app.detailId ?? ''}|${app.savingsPrefill ?? ''}',
          ),
          expandBody: app.route == AppRoute.amortization ||
              app.route == AppRoute.profileAboutUs ||
              app.route == AppRoute.profileAbout,
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
      case AppRoute.compare:
        return const CompareScreen();
      case AppRoute.savings:
        return const SavingsListScreen();
      case AppRoute.savingsNew:
        return const SavingsNewScreen();
      case AppRoute.savingsDetail:
        return const SavingsDetailScreen();
      case AppRoute.profile:
        return const ProfileHomeScreen();
      case AppRoute.profileEdit:
        return const ProfileEditScreen();
      case AppRoute.profileSettings:
        return const ProfileSettingsScreen();
      case AppRoute.profileData:
        return const ProfileDataScreen();
      case AppRoute.profileAboutUs:
        return const ProfileTextScreen(titleKey: 'aboutUs.title', bodyKey: 'aboutUs.body');
      case AppRoute.profileAbout:
        return const ProfileTextScreen(titleKey: 'about.title', bodyKey: 'about.body');
      case AppRoute.savedList:
        return const SavedListScreen();
      case AppRoute.savedDetail:
        return const SavedDetailScreen();
    }
  }
}
