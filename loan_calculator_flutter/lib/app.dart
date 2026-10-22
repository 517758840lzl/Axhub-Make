import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/i18n.dart';
import 'screens/loan_screens.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/revolut_theme.dart';
import 'widgets/loan_widgets.dart';

void _dismissKeyboardOnBlankTap(Offset position) {
  final focus = FocusManager.instance.primaryFocus;
  final focusContext = focus?.context;
  if (focusContext == null) return;
  final editor = focusContext.findAncestorStateOfType<EditableTextState>();
  final fieldContext = editor?.context;
  if (fieldContext == null) return;
  if (_tapLandsOnField(position, fieldContext)) return;
  focus!.unfocus();
}

bool _tapLandsOnField(Offset position, BuildContext fieldContext) {
  RenderObject? node = fieldContext.findRenderObject();
  while (node != null) {
    if (node is RenderBox && node.hasSize && node.attached) {
      final height = node.size.height;
      if (height >= 40 && height <= 80) {
        final rect = node.localToGlobal(Offset.zero) & node.size;
        if (rect.inflate(8).contains(position)) return true;
        break;
      }
      if (height > 80) break;
    }
    node = node.parent;
  }
  final result = HitTestResult();
  final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  if (view == null) return true;
  WidgetsBinding.instance.hitTestInView(result, position, view.viewId);
  for (final entry in result.path) {
    if (entry.target is RenderEditable) return true;
  }
  return false;
}

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
          title: appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildRevolutTheme(),
          builder: (context, child) {
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _dismissKeyboardOnBlankTap(event.position),
              child: child ?? const SizedBox.shrink(),
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
    // Keep the canvas color under the splash so the system black never flashes through.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final app = context.read<AppState>();
        // Sub-pages go back one step. On Calc, Save, or Me, stay on the current page.
        if (app.canPopRoute) app.pop();
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
        return LoanFrame(
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
          expandBody: app.route == AppRoute.amortization || app.route == AppRoute.profileAbout,
          body: _screenForRoute(app),
        );
      },
    );
  }

  Widget _screenForRoute(AppState app) {
    final route = app.route;
    if (route == AppRoute.calcResult) return const CalcResultScreen();
    if (route == AppRoute.amortization) return const AmortizationScreen();
    if (route == AppRoute.compare) return const CompareScreen();
    if (route == AppRoute.savings) return const SavingsListScreen();
    if (route == AppRoute.savingsNew) return const SavingsNewScreen();
    if (route == AppRoute.savingsDetail) return const SavingsDetailScreen();
    if (route == AppRoute.profile) return const ProfileHomeScreen();
    if (route == AppRoute.profileEdit) return const ProfileEditScreen();
    if (route == AppRoute.profileSettings) return const ProfileSettingsScreen();
    if (route == AppRoute.profileData) return const ProfileDataScreen();
    if (route == AppRoute.profileAboutUs) {
      return const ProfileTextScreen(titleKey: 'aboutUs.title', bodyKey: 'aboutUs.body');
    }
    if (route == AppRoute.profileAbout) return const ProfilePrivacyScreen();
    if (route == AppRoute.savedList) return const SavedListScreen();
    if (route == AppRoute.savedDetail) return const SavedDetailScreen();
    return const CalcHomeScreen();
  }
}
