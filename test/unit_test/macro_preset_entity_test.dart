import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/macro_preset_entity.dart';

void main() {
  group('MacroPresetEntity', () {
    test('every preset sums to 100%', () {
      // The dialog writes a preset straight into the sliders without
      // rebalancing, so a preset that doesn't add up would be saved as is.
      for (final preset in MacroPresetEntity.values) {
        expect(
          preset.carbsPct + preset.proteinPct + preset.fatPct,
          100,
          reason: '${preset.id} should sum to 100',
        );
      }
    });

    test('every share stays within the dialog range of 5–90%', () {
      for (final preset in MacroPresetEntity.values) {
        for (final pct in [preset.carbsPct, preset.proteinPct, preset.fatPct]) {
          expect(pct, inInclusiveRange(5, 90), reason: preset.id);
        }
      }
    });

    test('standard is the existing 60/15/25 default', () {
      expect(MacroPresetEntity.standard.matches(60, 15, 25), isTrue);
    });

    test('ids are unique', () {
      final ids = MacroPresetEntity.values.map((p) => p.id).toSet();
      expect(ids.length, MacroPresetEntity.values.length);
    });

    test('only low carb and keto are outside the general guidance', () {
      final flagged = MacroPresetEntity.values
          .where((p) => p.outsideGeneralGuidance)
          .toSet();
      expect(flagged, {MacroPresetEntity.lowCarb, MacroPresetEntity.keto});
    });

    test('low carb and keto stay below 26% and 10% carbohydrate', () {
      expect(MacroPresetEntity.lowCarb.carbsPct, lessThan(26));
      expect(MacroPresetEntity.keto.carbsPct, lessThanOrEqualTo(10));
    });
  });
}
