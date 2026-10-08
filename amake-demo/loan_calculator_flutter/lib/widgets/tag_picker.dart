import 'package:flutter/material.dart';

import '../data/tags.dart';
import '../theme/revolut_theme.dart';
import 'loan_widgets.dart';

class TagPicker extends StatefulWidget {
  const TagPicker({super.key, required this.value, required this.onChange, this.label = '标签'});

  final List<String> value;
  final ValueChanged<List<String>> onChange;
  final String label;

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _toggle(String tag) {
    final tags = normalizeTagList(widget.value);
    if (tags.contains(tag)) {
      widget.onChange(tags.where((t) => t != tag).toList());
    } else {
      widget.onChange(normalizeTagList([...tags, tag]));
    }
  }

  void _addCustom() {
    final t = _draft.text.trim();
    if (t.isEmpty) return;
    widget.onChange(normalizeTagList([...normalizeTagList(widget.value), t]));
    _draft.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tags = normalizeTagList(widget.value);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RevolutColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RevolutColors.divider),
        boxShadow: [RevolutColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanLabel(widget.label),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedTags.map((tag) {
              final active = tags.contains(tag);
              return GestureDetector(
                onTap: () => _toggle(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? RevolutColors.brandStart.withValues(alpha: 0.14) : RevolutColors.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? Colors.transparent : RevolutColors.divider),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? RevolutColors.brandSolid : RevolutColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LoanInput(
                  controller: _draft,
                  placeholder: '自定义标签，回车添加',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: LoanSecondaryButton(label: '添加', onPressed: _addCustom),
              ),
            ],
          ),
          if (tags.isNotEmpty)
            TagRow(tags: tags, onRemove: (t) => widget.onChange(tags.where((x) => x != t).toList()))
          else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LoanMuted('至少选一个标签，便于筛选', fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class TagRow extends StatelessWidget {
  const TagRow({super.key, required this.tags, this.onRemove});

  final List<String> tags;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tags.map((t) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: onRemove == null ? 8 : 10, vertical: onRemove == null ? 3 : 4),
            decoration: BoxDecoration(
              color: RevolutColors.brandStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: RevolutColors.brandSolid)),
                if (onRemove != null)
                  GestureDetector(
                    onTap: () => onRemove!(t),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('×', style: TextStyle(fontSize: 14, color: RevolutColors.brandSolid)),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
