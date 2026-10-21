import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/revolut_theme.dart';
import 'controls.dart';

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

    return Transform.translate(
      offset: const Offset(0, -4),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, marginTop, 0, (icon == null ? 8 : 10) - 4),
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
