import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/tags.dart';
import '../state/app_state.dart';
import '../theme/revolut_theme.dart';

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
                                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          _LoanTabBar(activeTab: activeTab, onTab: onTab, labels: tabLabels),
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
                              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                            color: active ? Colors.white : RevolutColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active ? RevolutColors.brandSolid : RevolutColors.textMuted,
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: RevolutColors.text),
        ),
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.child,
    this.dense = false,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundGradient,
  });

  final Widget child;
  final bool dense;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  /// 储蓄「智能提示」等（对应 Web `.loan-savings-insight`）
  final Gradient? backgroundGradient;

  /// 与 Web `.loan-savings-insight`：`180deg`，#f5f6ff → 45% 起为 `#fff`（6% brand on white）
  static const Color savingsInsightTop = Color(0xFFF5F6FF);

  static LinearGradient get savingsInsightGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 0.45, 1],
        colors: [
          savingsInsightTop,
          RevolutColors.surface1,
          RevolutColors.surface1,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 4 : 16),
        decoration: BoxDecoration(
          color: backgroundGradient == null ? RevolutColors.surface1 : null,
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RevolutColors.divider),
          boxShadow: [RevolutColors.softShadow],
        ),
        child: child,
      ),
    );
    final spaced = Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: onTap == null ? card : GestureDetector(onTap: onTap, child: card),
    );
    return spaced;
  }
}

class LoanPrimaryButton extends StatelessWidget {
  const LoanPrimaryButton({super.key, required this.label, required this.onPressed, this.flex});

  final String label;
  final VoidCallback? onPressed;
  final bool? flex;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: RevolutColors.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [RevolutColors.ctaShadow],
          ),
          child: Center(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
    if (flex == true) return Expanded(child: btn);
    return SizedBox(width: double.infinity, child: btn);
  }
}

class LoanSecondaryButton extends StatelessWidget {
  const LoanSecondaryButton({super.key, required this.label, required this.onPressed, this.flex, this.marginTop});

  final String label;
  final VoidCallback? onPressed;
  final bool? flex;
  final double? marginTop;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      height: 48,
      width: flex == true ? null : double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: RevolutColors.text,
          side: const BorderSide(color: RevolutColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
    final wrapped = marginTop != null ? Padding(padding: EdgeInsets.only(top: marginTop!), child: btn) : btn;
    if (flex == true) return Expanded(child: wrapped);
    return wrapped;
  }
}

class LoanInput extends StatelessWidget {
  const LoanInput({
    super.key,
    required this.controller,
    this.error = false,
    this.suffix,
    this.placeholder,
    this.keyboardType,
    this.onChanged,
    this.marginBottom,
    this.amountStyle = false,
  });

  final TextEditingController controller;
  final bool error;
  final String? suffix;
  final String? placeholder;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double? marginBottom;
  final bool amountStyle;

  @override
  Widget build(BuildContext context) {
    final field = Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: amountStyle ? 18 : 16,
            height: 1.2,
            leadingDistribution: TextLeadingDistribution.even,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: RevolutColors.surface2,
            isDense: true,
            // 上下对称，避免数字视觉上偏上
            contentPadding: EdgeInsets.fromLTRB(14, 14, suffix != null ? 36 : 14, 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: RevolutColors.divider)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: error ? RevolutColors.spend : RevolutColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RevolutColors.brandSolid, width: 1),
            ),
          ),
        ),
      ),
    );
    final wrapped = suffix == null
        ? field
        : Stack(
            alignment: Alignment.centerRight,
            children: [
              field,
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(suffix!, style: const TextStyle(fontSize: 13, color: RevolutColors.textMuted)),
              ),
            ],
          );
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom ?? 0),
      child: wrapped,
    );
  }
}

class LoanLabel extends StatelessWidget {
  const LoanLabel(this.text, {super.key, this.marginTop, this.marginBottom = 8});
  final String text;
  final double? marginTop;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom, top: marginTop ?? 0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: RevolutColors.textSecondary,
        ),
      ),
    );
  }
}

class LoanSegment extends StatelessWidget {
  const LoanSegment({super.key, required this.options, required this.selected, required this.onSelect});

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: RevolutColors.surface2, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: options.map((o) {
          final active = o.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: active ? RevolutColors.gradient : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : RevolutColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LoanTopBar extends StatelessWidget {
  const LoanTopBar({
    super.key,
    this.onBack,
    required this.title,
    this.subtitle,
    this.leadingOnlyTitle = false,
  });

  final VoidCallback? onBack;
  final String title;
  final String? subtitle;
  final bool leadingOnlyTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            LoanBackButton(onPressed: onBack!),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 13, color: RevolutColors.textSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoanBackButton extends StatelessWidget {
  const LoanBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Icon(LucideIcons.arrowLeft, size: 22, color: RevolutColors.text),
      ),
    );
  }
}

class LoanStatRow extends StatelessWidget {
  const LoanStatRow({super.key, required this.children, this.triple = false});

  final List<Widget> children;
  /// 与 Web `.loan-stat-row--triple` 一致（三列等分）；两列时忽略
  final bool triple;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class LoanStatBox extends StatelessWidget {
  const LoanStatBox({super.key, required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RevolutColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RevolutColors.divider),
        boxShadow: [RevolutColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanLabel(label),
          Text(value, style: monoStyle(context, size: 20, w: FontWeight.w700).copyWith(color: RevolutColors.brandSolid)),
        ],
      ),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: box,
      ),
    );
  }
}

class LoanHeroBanner extends StatelessWidget {
  const LoanHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badges,
    this.marginBottom = 16,
  });

  final String title;
  final String subtitle;
  final List<Widget> badges;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: RevolutColors.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [RevolutColors.ctaShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white.withValues(alpha: 0.92)),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: badges),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class LoanHeroBadge extends StatelessWidget {
  const LoanHeroBadge({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class LoanFeatureRow extends StatelessWidget {
  const LoanFeatureRow({
    super.key,
    required this.ratioLabel,
    required this.amortLabel,
    required this.compareLabel,
    required this.onRatio,
    required this.onAmort,
    required this.onCompare,
  });

  final String ratioLabel;
  final String amortLabel;
  final String compareLabel;
  final VoidCallback onRatio;
  final VoidCallback onAmort;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.pieChart, ratioLabel, onRatio),
      (LucideIcons.tableProperties, amortLabel, onAmort),
      (LucideIcons.columns2, compareLabel, onCompare),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
                child: Material(
                  color: RevolutColors.surface1,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: items[i].$3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RevolutColors.divider),
                        boxShadow: [RevolutColors.softShadow],
                      ),
                      child: Column(
                        children: [
                          Icon(items[i].$1, size: 20, color: RevolutColors.brandSolid),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RevolutColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoanPreviewCard extends StatelessWidget {
  const LoanPreviewCard({
    super.key,
    required this.previewTitle,
    required this.payment,
    required this.totalInterest,
    required this.totalPayment,
    required this.interestLabel,
    required this.totalLabel,
  });

  final String previewTitle;
  final String payment;
  final String totalInterest;
  final String totalPayment;
  final String interestLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF8F9FE)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevolutColors.divider),
        boxShadow: [RevolutColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 14, color: RevolutColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  previewTitle,
                  style: const TextStyle(fontSize: 12, color: RevolutColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(payment, style: monoStyle(context, size: 28, w: FontWeight.w700).copyWith(color: RevolutColors.brandSolid)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metaBox(interestLabel, totalInterest, context)),
              const SizedBox(width: 8),
              Expanded(child: _metaBox(totalLabel, totalPayment, context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaBox(String label, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: RevolutColors.surface2, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: RevolutColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: monoStyle(context, size: 13)),
        ],
      ),
    );
  }
}

class LoanChip extends StatelessWidget {
  const LoanChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: RevolutColors.brandStart.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RevolutColors.brandSolid)),
    );
  }
}

class LoanQuickChip extends StatelessWidget {
  const LoanQuickChip({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: RevolutColors.divider),
        foregroundColor: RevolutColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class LoanTagFilter extends StatelessWidget {
  const LoanTagFilter({super.key, required this.tags, required this.activeTag, required this.onSelect});

  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    String labelOf(String tag) => tagLabel(tag, app.tr);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _filterChip(app.tr('tag.all'), activeTag == null, () => onSelect(null)),
          ...tags.map((t) => _filterChip(labelOf(t), activeTag == t, () => onSelect(activeTag == t ? null : t))),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? RevolutColors.brandStart.withValues(alpha: 0.14) : RevolutColors.surface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? Colors.transparent : RevolutColors.divider),
            boxShadow: active ? [BoxShadow(color: RevolutColors.brandStart.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: 1)] : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? RevolutColors.brandSolid : RevolutColors.textSecondary)),
        ),
      ),
    );
  }
}

/// 记账列表行（对应 Web `.loan-list-item.loan-list-item--stack`）
class LoanListItemStack extends StatelessWidget {
  const LoanListItemStack({super.key, required this.children, this.showDivider = true});

  final List<Widget> children;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
      decoration: showDivider
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: RevolutColors.divider)))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class LoanListItemTitle extends StatelessWidget {
  const LoanListItemTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class LoanBadgeCalc extends StatelessWidget {
  const LoanBadgeCalc({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: RevolutColors.brandStart.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.watch<AppState>().tr('tag.calcBadge'),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RevolutColors.brandSolid),
      ),
    );
  }
}

class LoanListItemActions extends StatelessWidget {
  const LoanListItemActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    );
  }
}

class LoanLedgerInlineAction extends StatelessWidget {
  const LoanLedgerInlineAction({super.key, required this.label, required this.onPressed, this.danger = true});

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: danger ? RevolutColors.spend : RevolutColors.text,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class LoanSectionHead extends StatelessWidget {
  const LoanSectionHead({
    super.key,
    this.icon,
    required this.title,
    this.trailing,
    this.marginTop = 0,
  });

  final IconData? icon;
  final String title;
  final Widget? trailing;
  final double marginTop;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: icon == null ? 13 : 14,
      fontWeight: FontWeight.w700,
      color: icon == null ? RevolutColors.textSecondary : RevolutColors.text,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 4 + marginTop, 0, icon == null ? 8 : 10),
      child: icon == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: titleStyle),
                ?trailing,
              ],
            )
          : Row(
              children: [
                Icon(icon, size: 16, color: RevolutColors.brandSolid),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: titleStyle)),
                ?trailing,
              ],
            ),
    );
  }
}

class LoanRow extends StatelessWidget {
  const LoanRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.divider = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: divider
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: RevolutColors.divider)))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: monoStyle(context).copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class LoanHeroAmount extends StatelessWidget {
  const LoanHeroAmount(this.text, {super.key, this.fontSize = 36});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: monoStyle(context, size: fontSize, w: FontWeight.w700)),
    );
  }
}

class LoanEmpty extends StatelessWidget {
  const LoanEmpty({super.key, required this.message, this.icon, this.action});

  final String message;
  final Widget? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          if (icon != null) ...[icon!, const SizedBox(height: 12)],
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.5, color: RevolutColors.textSecondary)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
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
            child: const Center(child: Text('+', style: TextStyle(fontSize: 28, color: Colors.white, height: 1))),
          ),
        ),
      ),
    );
  }
}

class LoanMenuItem extends StatelessWidget {
  const LoanMenuItem({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
    this.divider = true,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: divider
            ? const BoxDecoration(border: Border(bottom: BorderSide(color: RevolutColors.divider)))
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: danger ? RevolutColors.spend : RevolutColors.text)),
            trailing ?? const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class LoanMuted extends StatelessWidget {
  const LoanMuted(this.text, {super.key, this.center = false, this.fontSize = 12});
  final String text;
  final bool center;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontSize: fontSize, color: RevolutColors.textSecondary, height: 1.5),
    );
  }
}

