import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
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

  /// Savings insight card. Matches the web `.loan-savings-insight`.
  final Gradient? backgroundGradient;

  /// Matches the web insight: 180deg, #f5f6ff, then #fff from 45%.
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
    final labelFont = Theme.of(context).textTheme.bodyLarge;
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
            hintStyle: TextStyle(
              fontFamily: labelFont?.fontFamily,
              fontFamilyFallback: labelFont?.fontFamilyFallback,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.2,
              leadingDistribution: TextLeadingDistribution.even,
              color: RevolutColors.textMuted,
            ),
            filled: true,
            fillColor: RevolutColors.surface2,
            isDense: true,
            // Symmetric vertical padding so the digits do not sit high.
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
    this.stretch = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: stretch ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: stretch ? 6 : 12, vertical: 7),
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
            textAlign: TextAlign.center,
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
    required this.years,
    required this.months,
    required this.maxYears,
    required this.onChanged,
    this.error = false,
    this.title,
  });

  final int years;
  final int months;
  final int maxYears;
  final void Function(int years, int months) onChanged;
  final bool error;
  final String? title;

  bool get _byMonth => months > 0 && years == 0;

  List<int> get _yearPresets {
    const longTerm = [1, 5, 10, 15, 20, 25, 30];
    const shortTerm = [1, 2, 3, 5];
    final source = maxYears <= 5 ? shortTerm : longTerm;
    return source.where((year) => year <= maxYears).toList();
  }

  Future<void> _open(BuildContext context, AppState app, bool byMonth) async {
    final count = byMonth ? (maxYears * 12).clamp(1, 12) : maxYears;
    final current = byMonth ? months : years;
    final picked = await showModalBottomSheet<int>(
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
                  itemCount: count,
                  itemBuilder: (_, index) {
                    final value = count - index;
                    final selected = value == current;
                    final label = byMonth
                        ? app.tr('home.monthsN', {'n': '$value'})
                        : app.tr('home.yearsN', {'n': '$value'});
                    return ListTile(
                      title: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selected ? RevolutColors.brandSolid : RevolutColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: RevolutColors.brandSolid)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(value),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (byMonth) {
      onChanged(0, picked);
    } else {
      onChanged(picked, 0);
    }
  }

  void _setUnit(bool byMonth) {
    if (byMonth == _byMonth) return;
    if (byMonth) {
      final nextMonths = years == 1 && months == 0 ? 12 : 6;
      onChanged(0, nextMonths);
      return;
    }
    final nextYears = months > 0 && months % 12 == 0 ? months ~/ 12 : 1;
    onChanged(nextYears.clamp(1, maxYears), 0);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final byMonth = _byMonth;
    final presets = byMonth ? const [3, 6, 9, 12] : _yearPresets;
    final custom = !byMonth && maxYears > 5;
    final valueLabel = byMonth
        ? app.tr('home.monthsN', {'n': '$months'})
        : app.tr('home.yearsN', {'n': '${years <= 0 ? 1 : years}'});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoanSegment(
          options: [
            ('month', app.tr('home.termByMonth')),
            ('year', app.tr('home.termByYear')),
          ],
          selected: byMonth ? 'month' : 'year',
          onSelect: (value) => _setUnit(value == 'month'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: error ? RevolutColors.spend : RevolutColors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _open(context, app, byMonth),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(LucideIcons.calendar, size: 22, color: RevolutColors.brandSolid),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 4;
            const gap = 8.0;
            final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
            final labels = [
              for (final preset in presets)
                (
                  byMonth
                      ? app.tr('home.monthsN', {'n': '$preset'})
                      : app.tr('home.yearsN', {'n': '$preset'}),
                  byMonth ? months == preset : years == preset && months == 0,
                  () => byMonth ? onChanged(0, preset) : onChanged(preset, 0),
                ),
              if (custom)
                (
                  app.tr('home.termCustom'),
                  !presets.contains(years) || months != 0,
                  () => _open(context, app, false),
                ),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in labels)
                  SizedBox(
                    width: cell,
                    child: LoanQuickChip(
                      label: item.$1,
                      selected: item.$2,
                      stretch: true,
                      onTap: item.$3,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
