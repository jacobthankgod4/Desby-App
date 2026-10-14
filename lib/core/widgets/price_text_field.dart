import 'package:flutter/services.dart';

/// Formats a run of digits with thousands separators (`50000` → `50,000`).
String formatPriceDigits(String digits) {
  final cleaned = digits.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.isEmpty) return '';
  return cleaned.replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
}

/// Extracts the raw numeric value from a (possibly formatted) price string.
/// `'₦ 1,250,000'` → `1250000`.
String priceToDigits(String? text) {
  if (text == null) return '';
  return text.replaceAll(RegExp(r'[^0-9]'), '');
}

/// Number of digits before [offset] in [text].
int _digitsBefore(String text, int offset) {
  final bounded = offset < 0 ? 0 : (offset > text.length ? text.length : offset);
  var count = 0;
  for (var i = 0; i < bounded; i++) {
    final c = text.codeUnitAt(i);
    if (c >= 0x30 && c <= 0x39) count++;
  }
  return count;
}

/// Maps "the caret sits after N digits" onto the formatted string so the
/// cursor never jumps to the end while typing in the middle of a number.
int _offsetForDigits(String formatted, int digitCount) {
  if (digitCount <= 0) return 0;
  var seen = 0;
  for (var i = 0; i < formatted.length; i++) {
    final c = formatted.codeUnitAt(i);
    if (c >= 0x30 && c <= 0x39) seen++;
    if (seen == digitCount) return i + 1;
  }
  return formatted.length;
}

/// Live thousands-separator input formatter for currency fields.
///
/// * non-digits are dropped,
/// * the value is always displayed as `50,000` while the app reads it back
///   through [priceToDigits] as `50000`,
/// * the caret stays anchored to the digit it was after (no end-of-line jump).
class PriceInputFormatter extends TextInputFormatter {
  const PriceInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = priceToDigits(newValue.text);
    final formatted = formatPriceDigits(digits);

    // Anchor on the new caret's digit position so typing mid-number works.
    final digitsBeforeCaret = _digitsBefore(
      newValue.text,
      newValue.selection.isValid ? newValue.selection.extentOffset : 0,
    );
    final caret = _offsetForDigits(formatted, digitsBeforeCaret);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}

/// Ready-made formatter list for `TextFormField.inputFormatters`.
const List<TextInputFormatter> priceInputFormatters = [
  PriceInputFormatter(),
];
