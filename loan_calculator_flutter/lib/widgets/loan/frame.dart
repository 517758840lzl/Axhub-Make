import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/revolut_theme.dart';

const loanShellMaxWidth = 430.0;

/// Tab 栏高度：外层 8+8 + item 上下 6+6 + 图标 28 + 间距 3 + 文案约 13 ≈ 72
const loanTabBarHeight = 72.0;

/// FAB 底边与 Tab 顶边的空隙
const loanFabTabGap = 16.0;

class LoanShell extends StatelessWidget {
  const LoanShell({
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

  /// 浮在内容之上、Tab 之上（不占布局条带）
  final Widget? fab;

  /// 路由变化时换 key，避免沿用上一页滚动位置（如结果页滑到底再进摊还）
  final Key? scrollResetKey;

  /// 子页面自己占满剩余高度（摊还明细），不要再套一层可滚矮盒子
  final bool expandBody;

  @override
  Widget build(BuildContext context) {
    final fabClearance = fab != null ? 52.0 + loanFabTabGap + 8 : 0.0;
    // 页面没有 Scaffold，键盘不会自动把内容顶上去。按键盘高度把整页抬到键盘上方。
    final keyboardLift = MediaQuery.viewInsetsOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: revolutSystemUi,
      child: Material(
        color: RevolutColors.canvas,
        child: SafeArea(
          top: true,
          bottom: true,
          left: false,
          right: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: loanShellMaxWidth),
              child: ColoredBox(
                color: RevolutColors.canvas,
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboardLift),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: expandBody
                                ? body
                                : SingleChildScrollView(
                                    key: scrollResetKey,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      showTabBar ? 16 + fabClearance : 12,
                                    ),
                                    child: body,
                                  ),
                          ),
                          if (showTabBar)
                            _LoanTabBar(
                              activeTab: activeTab,
                              onTab: onTab,
                              labels: tabLabels,
                            ),
                        ],
                      ),
                      if (fab != null && showTabBar)
                        Positioned(
                          right: 12,
                          bottom: loanTabBarHeight + loanFabTabGap,
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
