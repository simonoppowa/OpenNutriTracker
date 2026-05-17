import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/scanner/util/barcode_check_digit.dart';

void main() {
  group('isValidBarcodeCheckDigit', () {
    test('accepts a known-valid EAN-13 (Mars bar 5000159484695)', () {
      expect(isValidBarcodeCheckDigit('5000159484695'), isTrue);
    });

    test('accepts a known-valid UPC-A (Coca-Cola 049000028911)', () {
      expect(isValidBarcodeCheckDigit('049000028911'), isTrue);
    });

    test('accepts a known-valid EAN-8 (96385074)', () {
      expect(isValidBarcodeCheckDigit('96385074'), isTrue);
    });

    test('accepts a known-valid GTIN-14 (zero-padded EAN-13)', () {
      // Any valid 13-digit EAN with a leading zero is a valid GTIN-14.
      expect(isValidBarcodeCheckDigit('05000159484695'), isTrue);
    });

    test('rejects an EAN-13 with a single mistyped digit', () {
      // Mars bar with one payload digit changed (4 -> 5 at position 6).
      expect(isValidBarcodeCheckDigit('5000159584695'), isFalse);
    });

    test('rejects an 11-digit input (not a supported length)', () {
      expect(isValidBarcodeCheckDigit('12345678901'), isFalse);
    });

    test('rejects a non-numeric input of correct length', () {
      expect(isValidBarcodeCheckDigit('500015948469A'), isFalse);
    });

    test('rejects empty string', () {
      expect(isValidBarcodeCheckDigit(''), isFalse);
    });
  });
}
