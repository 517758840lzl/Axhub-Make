import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/revolut_theme.dart';

const loanFrameMaxWidth = 430.0;

/// Tab bar height: outer 8+8, item 6+6, icon 28, gap 3, label about 13, about 72.
const loanTabBarHeight = 72.0;

/// Gap between the FAB bottom and the tab bar top.
const loanFabTabGap = 16.0;

class LoanFrame extends StatelessWidget {
  const LoanFrame({
    super.key,
    required this.body,
    required this.showTabBar,
    required this.activeTab,
    required this.onTab,
    required this.tabLabels,
    this.toast,
    this.fab,
    this.scrollResetKey,
    this.expandBody = false,
  });

  final Widget body;
  final bool showTabBar;
  final int activeTab;
  final ValueChanged<int> onTab;
  final List<String> tabLabels;
  final String? toast;

  /// Floats above the content and the tab bar. It does not take a layout slot.
  final Widget? fab;

  /// New key on route change so the next page does not keep the previous scroll offset.
  final Key? scrollResetKey;

  /// A sub-page fills the remaining height itself. Do not wrap it in another short scroller.
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final fabClearance = fab != null ? 52.0 + loanFabTabGap + 8 : 0.0;
    // The keyboard covers the bottom of the screen. Lift only the content. The tab bar stays put and sits under the keyboard.
    // The bottom inset is inside the tab bar. The background reaches the screen edge.
    final keyboardLift = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final tabReserve = showTabBar ? loanTabBarHeight + safeBottom : safeBottom;
    final contentBottom = keyboardLift > tabReserve ? keyboardLift : tabReserve;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: revolutSystemUi,
      child: Material(
        color: RevolutColors.canvas,
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: loanFrameMaxWidth),
              child: ColoredBox(
                color: RevolutColors.canvas,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: contentBottom),
                        child: expandBody
                            ? body
                            : SingleChildScrollView(
                                key: scrollResetKey,
                                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  16 + fabClearance,
                                ),
                                child: body,
                              ),
                      ),
                    ),
                    if (showTabBar)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _LoanTabBar(
                          activeTab: activeTab,
                          onTab: onTab,
                          labels: tabLabels,
                        ),
                      ),
                    if (fab != null && showTabBar)
                      Positioned(
                        right: 12,
                        bottom: contentBottom + loanFabTabGap,
                        child: fab!,
                      ),
                    if (toast != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: const Alignment(0, 0.62),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: LoanToast(message: toast!),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanTabBar extends StatelessWidget {
  const _LoanTabBar({
    required this.activeTab,
    required this.onTab,
    required this.labels,
  });

  final int activeTab;
  final ValueChanged<int> onTab;
  final List<String> labels;

  static const _icons = [
    LucideIcons.calculator,
    LucideIcons.piggyBank,
    LucideIcons.userCircle,
  ];

  @override
  Widget build(BuildContext context) {
    final count = labels.length.clamp(0, _icons.length);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            border: Border(top: BorderSide(color: RevolutColors.divider)),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.viewPaddingOf(context).bottom),
          child: Row(
            children: List.generate(count, (i) {
              final active = activeTab == i;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: RevolutColors.brandStart.withValues(alpha: 0.1),
                  onTap: () => onTab(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: active ? RevolutColors.gradient : null,
                          ),
                          child: Icon(
                            _icons[i],
                            size: 18,
                            color: active
                                ? Colors.white
                                : RevolutColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? RevolutColors.brandSolid
                                : RevolutColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class LoanToast extends StatelessWidget {
  const LoanToast({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: RevolutColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RevolutColors.divider),
          boxShadow: [RevolutColors.softShadow],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RevolutColors.text,
          ),
        ),
      ),
    );
  }
}

class LoanFab extends StatelessWidget {
  const LoanFab({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        elevation: 0,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RevolutColors.gradient,
            ),
            child: const Center(
              child: Text(
                '+',
                style: TextStyle(fontSize: 28, color: Colors.white, height: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
