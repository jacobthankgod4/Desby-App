import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desby_app/core/widgets/price_text_field.dart';

void main() {
  group('formatPriceDigits', () {
    test('inserts thousands separators', () {
      expect(formatPriceDigits('50000'), '50,000');
      expect(formatPriceDigits('1250000'), '1,250,000');
      expect(formatPriceDigits('999'), '999');
      expect(formatPriceDigits('1000'), '1,000');
      expect(formatPriceDigits(''), '');
      expect(formatPriceDigits('abc'), '');
    });
  });

  group('priceToDigits', () {
    test('strips separators and currency marks', () {
      expect(priceToDigits('50,000'), '50000');
      expect(priceToDigits('₦1,250,000'), '1250000');
      expect(priceToDigits(' 12 345 '), '12345');
      expect(priceToDigits(null), '');
    });
  });

  group('PriceInputFormatter', () {
    const formatter = PriceInputFormatter();

    TextEditingValue type(String text, int caret) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );

    test('formats while typing at the end', () {
      final result = formatter.formatEditUpdate(type('', 0), type('5', 1));
      expect(result.text, '5');

      final result2 = formatter.formatEditUpdate(
        type('5', 1),
        type('50000', 6),
      );
      expect(result2.text, '50,000');
      expect(result2.selection.extentOffset, 6);
    });

    test('keeps the caret anchored to digits when typing mid-number', () {
      // User typed '9' after '12' inside "1234" -> caret sits after 3 digits.
      final result = formatter.formatEditUpdate(
        type('1234', 2),
        type('12934', 3),
      );
      expect(result.text, '12,934');
      // caret was after 3 digits ('129') -> offset 4 in '12,934'
      expect(result.selection.extentOffset, 4);
    });

    test('re-separates correctly when deleting', () {
      // "50,000" minus its last digit -> 5000 -> displayed as "5,000".
      final result = formatter.formatEditUpdate(
        type('50,000', 6),
        type('50,00', 5),
      );
      expect(result.text, '5,000');
      expect(result.selection.extentOffset, 5);
    });

    test('drops non-digit characters', () {
      final result = formatter.formatEditUpdate(
        type('', 0),
        type('50abc000', 8),
      );
      expect(result.text, '50,000');
    });
  });

  test('priceInputFormatters exposes the formatter for TextFormField', () {
    expect(priceInputFormatters, hasLength(1));
    expect(priceInputFormatters.first, isA<PriceInputFormatter>());
  });
}
