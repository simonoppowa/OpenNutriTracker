import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the in-app consent text for meal export (#1245) to what
/// `HealthPackageService.writeMeal` actually sends. The user opts in on the
/// strength of this text, so a nutrient written but not named here is data
/// shared without disclosure (#1393 review). The iOS purpose string carries
/// the same list; `ios_health_purpose_strings_test.dart` pins that one.
void main() {
  final arb =
      jsonDecode(File('lib/l10n/intl_en.arb').readAsStringSync())
          as Map<String, dynamic>;

  test('the export disclosure names the micronutrients written', () {
    final body = arb['healthSyncExportDisclosureBody'] as String;
    for (final nutrient in const [
      'calories',
      'macronutrients',
      'cholesterol',
      'sodium',
      'minerals',
      'vitamins',
    ]) {
      expect(body, contains(nutrient));
    }
  });
}
