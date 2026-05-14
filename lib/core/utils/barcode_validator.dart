/// Shared barcode validation helpers used by the custom-meal flow (#167)
/// and the JSON / CSV import paths.
///
/// We do two checks — a lenient digit-count regex that accepts the common
/// retail barcode lengths, and a stricter EAN-13 check-digit verification
/// that catches the most common typo class (a single mis-keyed digit) for
/// codes claiming to be EAN-13.
library;

/// Lenient EAN-13 / UPC-A check — accept any 8-to-14 digit run. The longer
/// bound covers GTIN-14 case packaging, the shorter covers EAN-8.
final RegExp _barcodeFormat = RegExp(r'^\d{8,14}$');

/// True when [value] is the right shape for a barcode (8–14 digits, no other
/// characters). Use this as the first-pass filter on user-entered values
/// before persisting.
bool isBarcodeFormatValid(String value) => _barcodeFormat.hasMatch(value);

/// EAN-13 specific check-digit validation. For a 13-digit code the final
/// digit must match the value computed from the first twelve, otherwise
/// the user has mis-keyed somewhere. 8 / 12 / 14-digit codes use different
/// algorithms (EAN-8, UPC-A, GTIN-14) and are accepted at face value by
/// the lenient format check — we don't validate those here because real
/// products on those formats may have been entered correctly without
/// matching the EAN-13 weighting.
///
/// Algorithm: sum the odd-positioned digits (1, 3, 5, 7, 9, 11), sum the
/// even-positioned digits (2, 4, 6, 8, 10, 12) and weight that by three,
/// take modulo ten, subtract from ten, modulo ten again — that's the
/// expected 13th digit.
///
/// Returns true for any code that isn't exactly 13 digits so the caller
/// can use this as a "if the user typed an EAN-13, does it check out?"
/// filter without having to special-case other lengths.
bool isEan13CheckDigitValid(String value) {
  if (value.length != 13) return true;
  var sumOdd = 0;
  var sumEven = 0;
  for (var i = 0; i < 12; i++) {
    final digit = int.parse(value[i]);
    // i is 0-indexed; position 1 (odd) corresponds to i == 0, etc.
    if (i.isEven) {
      sumOdd += digit;
    } else {
      sumEven += digit;
    }
  }
  final check = (10 - ((sumOdd + 3 * sumEven) % 10)) % 10;
  return int.parse(value[12]) == check;
}
