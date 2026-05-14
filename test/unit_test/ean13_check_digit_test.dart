import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/barcode_validator.dart';

void main() {
  group('isEan13CheckDigitValid', () {
    // Real-world EAN-13 codes (sampled from common products). All have valid
    // check digits and should pass.
    test('accepts valid EAN-13 codes', () {
      expect(isEan13CheckDigitValid('5012345678900'), isTrue);
      expect(isEan13CheckDigitValid('4006381333931'), isTrue);
      expect(isEan13CheckDigitValid('8718265591714'), isTrue);
    });

    // A single-digit mutation of a known-good code should fail the check —
    // this is exactly the typo class the validator is meant to catch.
    test('rejects a single mis-keyed digit', () {
      // 5012345678900 with the final digit changed to 1.
      expect(isEan13CheckDigitValid('5012345678901'), isFalse);
      // 4006381333931 with the seventh digit changed.
      expect(isEan13CheckDigitValid('4006381338931'), isFalse);
    });

    // Lengths other than 13 are not EAN-13 and are accepted at face value —
    // see the doc comment on the validator for why.
    test('non-13-digit codes pass without validation', () {
      expect(isEan13CheckDigitValid('12345678'), isTrue); // EAN-8
      expect(isEan13CheckDigitValid('012345678905'), isTrue); // UPC-A 12-digit
      expect(isEan13CheckDigitValid('40063813339311'), isTrue); // GTIN-14
    });

    test('isBarcodeFormatValid accepts 8..14 digit runs', () {
      expect(isBarcodeFormatValid('12345678'), isTrue);
      expect(isBarcodeFormatValid('40063813339311'), isTrue);
      expect(isBarcodeFormatValid('1234567'), isFalse); // too short
      expect(isBarcodeFormatValid('123456789012345'), isFalse); // too long
      expect(isBarcodeFormatValid('1234-5678'), isFalse); // non-digits
      expect(isBarcodeFormatValid(''), isFalse);
    });
  });
}
