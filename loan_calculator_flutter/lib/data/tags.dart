import 'models.dart';

const suggestedTags = [
  '房贷',
  '车贷',
  '消费贷',
  '月供',
  '保险',
  '装修',
  '教育',
  '医疗',
  '日常',
  '其他',
];

List<String> defaultTagsForCategory(LoanCategory category) => [
      switch (category) {
        LoanCategory.mortgage => '房贷',
        LoanCategory.auto => '车贷',
        LoanCategory.personal => '消费贷',
        LoanCategory.other => '其他',
      },
    ];

List<String> normalizeTagList(List<String>? tags) {
  if (tags == null || tags.isEmpty) return [];
  final seen = <String>{};
  final out = <String>[];
  for (final t in tags) {
    final s = t.trim();
    if (s.isEmpty || seen.contains(s)) continue;
    seen.add(s);
    out.add(s);
    if (out.length >= 8) break;
  }
  return out;
}

List<String> collectAllTags(List<List<String>> calcTags, List<List<String>> manualTags) {
  final set = <String>{};
  for (final list in [...calcTags, ...manualTags]) {
    set.addAll(list);
  }
  final out = set.toList()..sort((a, b) => a.compareTo(b));
  return out;
}
