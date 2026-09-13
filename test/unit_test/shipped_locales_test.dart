// PROTOTYPE for https://github.com/simonoppowa/OpenNutriTracker/issues/1182
// — replaces ios_localizations_drift_test.dart once adopted.
import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_locales.dart';

/// Every place that enumerates the app's languages must agree with
/// `lib/core/l10n/shipped_locales.dart`. The tool does the comparison and
/// says what drifted; `dart run tool/check_locales.dart --fix` repairs the
/// platform files.
void main() {
  test('every locale list matches shipped_locales.dart', () {
    final result = checkLocales();
    expect(result.ok, isTrue, reason: result.report);
  });
}
