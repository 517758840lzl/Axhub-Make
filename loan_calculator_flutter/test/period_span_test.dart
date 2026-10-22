import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calculator_flutter/screens/calc/amort_page.dart';

void main() {
  test('blocks a start period after the end period and keeps the typed numbers', () {
    final span = resolvePeriodSpan(fromText: '1120', toText: '360', max: 360);
    expect(span.inverted, isTrue);
    expect(span.blocked, isTrue);
    expect(span.from, 1120);
    expect(span.to, 360);
    expect(span.fromBad, isTrue);
    expect(span.toBad, isTrue);
  });

  test('blocks an end period that is smaller than the start', () {
    final span = resolvePeriodSpan(fromText: '20', toText: '10', max: 360);
    expect(span.inverted, isTrue);
    expect(span.blocked, isTrue);
  });

  test('accepts a valid range', () {
    final span = resolvePeriodSpan(fromText: '1', toText: '12', max: 360);
    expect(span.blocked, isFalse);
    expect(span.from, 1);
    expect(span.to, 12);
  });

  test('does not clamp both ends to the last period when they are past the term', () {
    final span = resolvePeriodSpan(fromText: '400', toText: '500', max: 360);
    expect(span.inverted, isFalse);
    expect(span.outOfRange, isTrue);
    expect(span.blocked, isTrue);
  });
}
