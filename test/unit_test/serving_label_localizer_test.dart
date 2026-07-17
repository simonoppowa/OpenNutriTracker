import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/serving_label_localizer.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  group('localizeServingLabel', () {
    test('translates unit words with plural agreement (German)', () async {
      final s = await S.load(const Locale('de'));
      expect(localizeServingLabel(s, '1 slice (38 g)'), '1 Scheibe (38 g)');
      expect(localizeServingLabel(s, '2 slices (76 g)'), '2 Scheiben (76 g)');
      expect(localizeServingLabel(s, '1 portion (150 g)'),
          '1 Portion (150 g)');
      expect(localizeServingLabel(s, '1 cup'), '1 Tasse');
    });

    test('keeps English labels intact for the English locale', () async {
      final s = await S.load(const Locale('en'));
      expect(localizeServingLabel(s, '1 slice (38 g)'), '1 slice (38 g)');
      expect(localizeServingLabel(s, '2 slices (76 g)'), '2 slices (76 g)');
    });

    test('leaves unknown units and descriptive prose untouched', () async {
      final s = await S.load(const Locale('de'));
      // Unknown unit word.
      expect(localizeServingLabel(s, '1 drumstick (110 g)'),
          '1 drumstick (110 g)');
      // Comma-separated modifier prose is deliberately not half-translated.
      expect(localizeServingLabel(s, '1 cup, sliced (240 g)'),
          '1 cup, sliced (240 g)');
      // Weight-only labels have no unit word to translate.
      expect(localizeServingLabel(s, '38 g'), '38 g');
    });
  });
}
