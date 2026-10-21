import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    colors: [savingsInsightTop, RevolutColors.surface1, RevolutColors.surface1],
  );

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 4 : 16),
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
  const LoanPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.flex,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool? flex;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    final btn = Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const RoundedRectangleBorder(borderRadius: radius),
        child: Ink(
          height: 52,
          decoration: const BoxDecoration(gradient: RevolutColors.gradient),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
    if (flex == true) return Expanded(child: btn);
    return SizedBox(width: double.infinity, child: btn);
  }
}

class LoanSecondaryButton extends StatelessWidget {
  const LoanSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.flex,
    this.marginTop,
  });

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
          backgroundColor: RevolutColors.surface1,
          side: const BorderSide(color: RevolutColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
    final wrapped = marginTop != null
        ? Padding(
            padding: EdgeInsets.only(top: marginTop!),
            child: btn,
          )
        : btn;
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
    this.inputFormatters,
  });

  final TextEditingController controller;
  final bool error;
  final String? suffix;
  final String? placeholder;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double? marginBottom;
  final bool amountStyle;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final field = Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          scrollPadding: const EdgeInsets.fromLTRB(20, 72, 20, 28),
          textAlignVertical: TextAlignVertical.center,
          style: amountStyle
              ? monoStyle(context, size: 18, w: FontWeight.w400).copyWith(
                  height: 1.2,
                  leadingDistribution: TextLeadingDistribution.even,
                )
              : const TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: RevolutColors.surface2,
            isDense: true,
            // 上下对称，避免数字视觉上偏上
            contentPadding: EdgeInsets.fromLTRB(14, 14, suffix != null ? 36 : 14, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RevolutColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error ? RevolutColors.spend : RevolutColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RevolutColors.brandSolid,
                width: 1,
              ),
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
                child: Text(
                  suffix!,
                  style: amountStyle
                      ? monoStyle(context, size: 13, w: FontWeight.w400).copyWith(
                          color: RevolutColors.textMuted,
                        )
                      : const TextStyle(
                          fontSize: 13,
                          color: RevolutColors.textMuted,
                        ),
                ),
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
  const LoanLabel(
    this.text, {
    super.key,
    this.marginTop,
    this.marginBottom = 8,
  });
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
  const LoanSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: RevolutColors.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(options[i].$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: options[i].$1 == selected ? RevolutColors.gradient : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    options[i].$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: options[i].$1 == selected ? Colors.white : RevolutColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoanMuted extends StatelessWidget {
  const LoanMuted(
    this.text, {
    super.key,
    this.center = false,
    this.fontSize = 12,
  });
  final String text;
  final bool center;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: fontSize,
        color: RevolutColors.textSecondary,
        height: 1.5,
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: RevolutColors.brandSolid,
        ),
      ),
    );
  }
}

class LoanQuickChip extends StatelessWidget {
  const LoanQuickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected ? RevolutColors.gradient : null,
            color: selected ? null : RevolutColors.surface1,
            border: Border.all(
              color: selected ? Colors.transparent : RevolutColors.divider,
              width: selected ? 0 : 1,
            ),
            boxShadow: selected ? [RevolutColors.softShadow] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : RevolutColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class LoanTermSelect extends StatelessWidget {
  const LoanTermSelect({
    super.key,
    required this.value,
    required this.maxYears,
    required this.labelBuilder,
    required this.onChanged,
    this.error = false,
    this.title,
  });

  final String value;
  final int maxYears;
  final String Function(String year) labelBuilder;
  final ValueChanged<String> onChanged;
  final bool error;
  final String? title;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: RevolutColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: RevolutColors.text,
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: maxYears,
                  itemBuilder: (_, index) {
                    final year = '${maxYears - index}';
                    final selected = year == value;
                    return ListTile(
                      title: Text(
                        labelBuilder(year),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? RevolutColors.brandSolid
                              : RevolutColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: RevolutColors.brandSolid)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(year),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: RevolutColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error ? RevolutColors.spend : RevolutColors.divider,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labelBuilder(value.isEmpty ? '1' : value),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: RevolutColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
