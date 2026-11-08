import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_l10n.dart';

void main() {
  test('the delete-intake confirmations ask "Do you want" (#1368)', () {
    expect(
      l10nEn.deleteTimeDialogContent,
      'Do you want to delete the selected item?',
    );
    expect(
      l10nEn.deleteTimeDialogPluralContent,
      'Do you want to delete all items of this meal?',
    );
  });
}
