import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/serving_label_localizer.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  group('localizeServingLabel', () {
    test('translates unit words with plural agreement (German)', () async {
      final s = lookupS(const Locale('de'));
      expect(localizeServingLabel(s, '1 slice (38 g)'), '1 Scheibe (38 g)');
      expect(localizeServingLabel(s, '2 slices (76 g)'), '2 Scheiben (76 g)');
      expect(localizeServingLabel(s, '1 portion (150 g)'),
          '1 Portion (150 g)');
      expect(localizeServingLabel(s, '1 cup'), '1 Tasse');
    });

    test('keeps English labels intact for the English locale', () async {
      final s = lookupS(const Locale('en'));
      expect(localizeServingLabel(s, '1 slice (38 g)'), '1 slice (38 g)');
      expect(localizeServingLabel(s, '2 slices (76 g)'), '2 slices (76 g)');
    });

    test('leaves unknown units and descriptive prose untouched', () async {
      final s = lookupS(const Locale('de'));
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
  group('imperialServingLabel (#1368)', () {
    final s = lookupS(const Locale('en'));

    test('converts grams and millilitres, keeping the rest of the label', () {
      expect(imperialServingLabel(s, '15 g (Portion)'), '0.53 oz (Portion)');
      expect(imperialServingLabel(s, '1 slice (38 g)'), '1 slice (1.34 oz)');
      expect(imperialServingLabel(s, '250ml'), '8.45 ${s.flOzUnit}');
      expect(imperialServingLabel(s, 'Serving (31.8 g)'), 'Serving (1.12 oz)');
    });

    test('leaves labels without a gram or millilitre amount alone', () {
      expect(imperialServingLabel(s, '1 cup'), '1 cup');
      expect(imperialServingLabel(s, '1 tablet (500 mg)'), '1 tablet (500 mg)');
      expect(imperialServingLabel(s, '1.5 kg'), '1.5 kg');
      expect(imperialServingLabel(s, '2 grams'), '2 grams');
    });

    // Copilot review on #1384: only a complete amount converts, never the
    // tail of a longer number or of a compound unit.
    test('converts a leading-decimal amount as a whole number', () {
      expect(imperialServingLabel(s, '.5 g'), '0.02 oz');
      expect(imperialServingLabel(s, 'Serving (.5 g)'), 'Serving (0.02 oz)');
    });

    test('leaves a fraction alone', () {
      expect(imperialServingLabel(s, '1/2 g'), '1/2 g');
      expect(imperialServingLabel(s, '1 1/2 g'), '1 1/2 g');
    });

    test('leaves the g/ml custom-meal unit alone', () {
      expect(
        imperialServingLabel(s, 'Serving (100.0 g/ml)'),
        'Serving (100.0 g/ml)',
      );
      expect(imperialServingLabel(s, '100 g/ml'), '100 g/ml');
    });
  });
}
