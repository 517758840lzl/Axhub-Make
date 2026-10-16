import 'models.dart';

const tagMessageKey = <String, String>{
  '房贷': 'tag.mortgage',
  '车贷': 'tag.auto',
  '消费贷': 'tag.consumer',
  '月供': 'tag.payment',
  '保险': 'tag.insurance',
  '装修': 'tag.reno',
  '教育': 'tag.edu',
  '医疗': 'tag.medical',
  '日常': 'tag.daily',
  '其他': 'tag.other',
  '组合贷': 'cat.dual',
};

String tagLabel(String tag, String Function(String key, [Map<String, String>? params]) tr) {
  final key = tagMessageKey[tag];
  return key == null ? tag : tr(key);
}

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
        LoanCategory.dual => '房贷',
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
