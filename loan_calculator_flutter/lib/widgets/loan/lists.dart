import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/tags.dart';
import '../../state/app_state.dart';
import '../../theme/revolut_theme.dart';

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

/// Ledger row. Matches the web `.loan-list-item.loan-list-item--stack`.
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
