import 'models.dart';

const tagMessageKey = <String, String>{
  'mortgage': 'tag.mortgage',
  'auto': 'tag.auto',
  'consumer': 'tag.consumer',
  'payment': 'tag.payment',
  'insurance': 'tag.insurance',
  'reno': 'tag.reno',
  'edu': 'tag.edu',
  'medical': 'tag.medical',
  'daily': 'tag.daily',
  'other': 'tag.other',
  'dual': 'cat.dual',
};

String tagLabel(String tag, String Function(String key, [Map<String, String>? params]) tr) {
  final key = tagMessageKey[tag];
  return key == null ? tag : tr(key);
}

const suggestedTags = [
  'mortgage',
  'auto',
  'consumer',
  'payment',
  'insurance',
  'reno',
  'edu',
  'medical',
  'daily',
  'other',
];

List<String> defaultTagsForCategory(LoanCategory category) {
  if (category == LoanCategory.auto) return ['auto'];
  if (category == LoanCategory.personal) return ['consumer'];
  if (category == LoanCategory.dual) return ['mortgage'];
  if (category == LoanCategory.other) return ['other'];
  return ['mortgage'];
}

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
