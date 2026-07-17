import 'package:flutter/services.dart';

class CustomTextInputFormatter {
  /// Allows a decimal number with at most [maxDecimals] places (comma or
  /// period), normalising the separator to a period. Defaults to two decimals
  /// so every food-quantity field accepts the same precision; pass a different
  /// limit only where a field genuinely needs more.
  static List<TextInputFormatter> doubleOnly({int maxDecimals = 2}) =>
      <TextInputFormatter>[
        // Reject inputs with too many decimals by returning oldValue.
        // An anchored regex in `FilteringTextInputFormatter.allow` would
        // blank the entire field on the first invalid digit (e.g. "12.345"
        // → ""), which is jarring. A withFunction gives us fine-grained
        // control: only the offending keystroke is dropped.
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text.replaceAll(',', '.');
          final dotIdx = text.indexOf('.');
          if (dotIdx >= 0 && text.length - dotIdx - 1 > maxDecimals) {
            return oldValue;
          }
          return newValue;
        }),
        // Normalize comma → period separator (kept for convenience).
        TextInputFormatter.withFunction(
          (oldValue, newValue) =>
              newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
        ),
      ];
}
