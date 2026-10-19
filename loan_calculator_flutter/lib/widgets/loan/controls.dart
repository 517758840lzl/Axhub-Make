import 'package:flutter/material.dart';

import '../../theme/revolut_theme.dart';

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
    this.emoji = false,
  });

  final TextEditingController controller;
  final bool error;
  final String? suffix;
  final String? placeholder;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double? marginBottom;
  final bool amountStyle;
  final bool emoji;

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
            fontSize: emoji ? 26 : (amountStyle ? 18 : 16),
            height: emoji ? 1 : 1.2,
            leadingDistribution: TextLeadingDistribution.even,
            fontFeatures: emoji ? null : const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: RevolutColors.surface2,
            isDense: true,
            // 上下对称，避免数字视觉上偏上
            contentPadding: EdgeInsets.fromLTRB(14, emoji ? 8 : 14, suffix != null ? 36 : 14, emoji ? 8 : 14),
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
