/// #1630: a named starting point for the macro split. Users pick one in
/// Settings → Calculations → Macro split, then fine-tune with the sliders.
///
/// Standard is the existing WHO TRS 916 default. Mediterranean and High
/// protein stay inside the IOM 2005 Acceptable Macronutrient Distribution
/// Ranges (carbohydrate 45–65 %, protein 10–35 %, fat 20–35 %). Low carb and
/// Keto follow the carbohydrate cut-offs of Feinman et al. (2015): under
/// 26 % of energy, and 10 % or less. Keto sits on the dialog's 5 % floor.
///
/// Every preset sums to 100, so the dialog drops it into the sliders
/// without running the rebalance pass.
enum MacroPresetEntity {
  standard(id: 'standard', carbsPct: 60, proteinPct: 15, fatPct: 25),
  mediterranean(id: 'mediterranean', carbsPct: 45, proteinPct: 20, fatPct: 35),
  highProtein(id: 'high_protein', carbsPct: 45, proteinPct: 30, fatPct: 25),
  lowCarb(
    id: 'low_carb',
    carbsPct: 20,
    proteinPct: 30,
    fatPct: 50,
    outsideGeneralGuidance: true,
  ),
  keto(
    id: 'keto',
    carbsPct: 5,
    proteinPct: 20,
    fatPct: 75,
    outsideGeneralGuidance: true,
  );

  final String id;
  final int carbsPct;
  final int proteinPct;
  final int fatPct;

  /// Whether the split falls outside the general-population ranges, so the
  /// dialog shows a short note while it is selected.
  final bool outsideGeneralGuidance;

  const MacroPresetEntity({
    required this.id,
    required this.carbsPct,
    required this.proteinPct,
    required this.fatPct,
    this.outsideGeneralGuidance = false,
  });

  /// Whether the given whole-percent split is exactly this preset.
  bool matches(int carbs, int protein, int fat) =>
      carbs == carbsPct && protein == proteinPct && fat == fatPct;
}
