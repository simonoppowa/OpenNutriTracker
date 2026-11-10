import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/macro_preset_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// One-tap starting points for the macro split dialog (#1630), laid out
/// like the per-meal kcal share presets. A preset only fills in the
/// sliders; nothing is saved until the dialog's OK.
class MacroPresetButtons extends StatelessWidget {
  final int carbsPct;
  final int proteinPct;
  final int fatPct;

  /// Called with the preset's carbohydrate, protein and fat shares in whole
  /// percent.
  final void Function(int carbsPct, int proteinPct, int fatPct) onSelected;

  const MacroPresetButtons({
    super.key,
    required this.carbsPct,
    required this.proteinPct,
    required this.fatPct,
    required this.onSelected,
  });

  String _label(S s, MacroPresetEntity preset) {
    switch (preset) {
      case MacroPresetEntity.standard:
        return s.mealPatternStandard;
      case MacroPresetEntity.mediterranean:
        return s.mealPatternMediterranean;
      case MacroPresetEntity.highProtein:
        return s.macroPresetHighProtein;
      case MacroPresetEntity.lowCarb:
        return s.macroPresetLowCarb;
      case MacroPresetEntity.keto:
        return s.macroPresetKeto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final showNote = MacroPresetEntity.values.any(
      (preset) =>
          preset.outsideGeneralGuidance &&
          preset.matches(carbsPct, proteinPct, fatPct),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.mealPatternPresetsLabel, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final preset in MacroPresetEntity.values)
              Semantics(
                identifier: 'macro-split-preset-${preset.id}',
                child: OutlinedButton(
                  onPressed: () => onSelected(
                    preset.carbsPct,
                    preset.proteinPct,
                    preset.fatPct,
                  ),
                  child: Text(_label(s, preset)),
                ),
              ),
          ],
        ),
        if (showNote) ...[
          const SizedBox(height: 4),
          Text(s.macroPresetLowCarbNote, style: textTheme.bodySmall),
        ],
      ],
    );
  }
}
