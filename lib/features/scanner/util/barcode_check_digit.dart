/// Validates the Modulo-10 check digit shared by EAN-8, UPC-A, EAN-13, and
/// GTIN-14 barcodes.
///
/// All four formats use the same algorithm: starting from the digit immediately
/// to the left of the check digit and moving right-to-left, each digit is
/// multiplied alternately by 3 and 1. The sum of those products determines the
/// expected check digit as `(10 - sum % 10) % 10`.
///
/// Returns `true` only when [code] is exactly 8, 12, 13, or 14 numeric digits
/// and its trailing digit matches the computed value.
bool isValidBarcodeCheckDigit(String code) {
  if (code.isEmpty) return false;
  const allowedLengths = {8, 12, 13, 14};
  if (!allowedLengths.contains(code.length)) return false;
  if (!RegExp(r'^\d+$').hasMatch(code)) return false;

  final digits = code.codeUnits.map((u) => u - 0x30).toList(growable: false);
  final checkDigit = digits.last;

  var sum = 0;
  // Walk the payload right-to-left so the rightmost payload digit gets weight 3.
  for (var i = digits.length - 2, weightIs3 = true; i >= 0; i--, weightIs3 = !weightIs3) {
    sum += digits[i] * (weightIs3 ? 3 : 1);
  }

  final expected = (10 - sum % 10) % 10;
  return expected == checkDigit;
}
