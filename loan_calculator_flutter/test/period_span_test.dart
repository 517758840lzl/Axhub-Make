import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator_flutter/screens/calc/amort_page.dart';

void main() {
  test('起始期大于结束期时拦住，并保留输入框里的数字', () {
    final span = resolvePeriodSpan(fromText: '1120', toText: '360', max: 360);
    expect(span.inverted, isTrue);
    expect(span.blocked, isTrue);
    expect(span.from, 1120);
    expect(span.to, 360);
    expect(span.fromBad, isTrue);
    expect(span.toBad, isTrue);
  });

  test('范围内结束期更小同样拦住', () {
    final span = resolvePeriodSpan(fromText: '20', toText: '10', max: 360);
    expect(span.inverted, isTrue);
    expect(span.blocked, isTrue);
  });

  test('合法区间可以出明细', () {
    final span = resolvePeriodSpan(fromText: '1', toText: '12', max: 360);
    expect(span.blocked, isFalse);
    expect(span.from, 1);
    expect(span.to, 12);
  });

  test('起止都超过总期数时不算成最后一期', () {
    final span = resolvePeriodSpan(fromText: '400', toText: '500', max: 360);
    expect(span.inverted, isFalse);
    expect(span.outOfRange, isTrue);
    expect(span.blocked, isTrue);
  });
}
