import 'package:flutter/services.dart';

/// 去掉千分位与全角符号，解析金额/数字输入。
double? parseAmountString(String raw) {
  final s = raw.trim().replaceAll(',', '').replaceAll('，', '').replaceAll(' ', '');
  if (s.isEmpty || s == '.') return null;
  if (s.contains('-')) return null;
  return double.tryParse(s);
}

class PositiveDecimalInputFormatter extends TextInputFormatter {
  const PositiveDecimalInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var t = newValue.text;
    if (t.contains('-')) return oldValue;
    final buf = StringBuffer();
    var dot = false;
    for (var i = 0; i < t.length; i++) {
      final ch = t[i];
      if (ch == '.' ) {
        if (dot) continue;
        dot = true;
        buf.write(ch);
      } else if (RegExp(r'\d').hasMatch(ch)) {
        buf.write(ch);
      }
    }
    t = buf.toString();
    if (t == newValue.text) return newValue;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length.clamp(0, t.length)),
    );
  }
}

const positiveDecimalInputFormatters = [PositiveDecimalInputFormatter()];

/// 金额输入展示，如 1000000 → 1,000,000。保留小数点。
String formatGroupedAmount(String raw) {
  if (raw.isEmpty) return '';
  final dot = raw.indexOf('.');
  final intRaw = dot == -1 ? raw : raw.substring(0, dot);
  final frac = dot == -1 ? '' : raw.substring(dot);
  final digits = intRaw.replaceAll(RegExp(r'\D'), '');
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final left = digits.length - i;
    if (i > 0 && left % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '$buf$frac';
}

String _plainDecimal(String raw) {
  final buf = StringBuffer();
  var dot = false;
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    if (ch == '.') {
      if (dot) continue;
      dot = true;
      buf.write(ch);
    } else if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
      buf.write(ch);
    }
  }
  return buf.toString();
}

class GroupedDecimalInputFormatter extends TextInputFormatter {
  const GroupedDecimalInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.contains('-')) return oldValue;
    final plain = _plainDecimal(newValue.text);
    final formatted = formatGroupedAmount(plain);
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final kept = _plainDecimal(newValue.text.substring(0, end)).length;
    var caret = formatted.length;
    if (kept == 0) {
      caret = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] == ',') continue;
        seen++;
        if (seen == kept) {
          caret = i + 1;
          break;
        }
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret.clamp(0, formatted.length)),
    );
  }
}

const groupedDecimalInputFormatters = [GroupedDecimalInputFormatter()];

class IntegerInputFormatter extends TextInputFormatter {
  const IntegerInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (t == newValue.text) return newValue;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

const integerInputFormatters = [IntegerInputFormatter()];
