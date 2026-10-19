import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/dri_reference.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_total.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/nutrient_panel_rows.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Daily nutrient summary that aggregates every nutrient a meal stores (#47)
/// across the day's intake list and renders each as a "value / reference"
/// row with a small progress bar, in collapsible groups ([NutrientPanelRow]).
/// A nutrient without any reference shows its amount without a bar.
///
/// The references are sensible DRIs for an average adult (FDA Daily Values
/// where applicable). Iron and magnesium are gender-aware because the gap
/// between female and male DRIs is large enough that a single number would
/// mislead one group or the other.
///
/// As a follow-up to #160 the panel now supports two extra dimensions:
///   * a Day / Week SegmentedButton toggle. "Week" computes a 7-day rolling
///     average (today + the previous 6 days) so the user can see whether a
///     single low-iron day was actually an outlier; references stay the
///     same. The previous days' intakes are fetched via [GetIntakeUsecase]
///     in [didChangeDependencies] and again whenever [selectedDay] changes.
///   * a per-nutrient show/hide map persisted on [ConfigEntity]. Defaults to
///     "everything visible"; the user can hide individual nutrients from
///     Settings → Nutrients (see [NutrientPanelKeys]).
///
/// Computation is on the fly from [intakes] (plus the fetched week window
/// when Week is selected). PR #314 added the per-meal micronutrient fields
/// on [MealNutrimentsDBO]; this widget simply sums them.
class DailyNutrientPanel extends StatefulWidget {
  final List<IntakeEntity> intakes;

  /// The day the panel is summarising. Used as the anchor for the weekly
  /// rolling average (today + the previous 6 days). Defaults to "today".
  final DateTime? selectedDay;

  /// Forwarded from the diary day view so the panel can prefer the user's
  /// per-nutrient goals (set in Settings → Nutrient goals, #173) over
  /// the published daily references. Null on days the user hasn't tracked
  /// yet — in which case the panel falls back to the default DRIs.
  final TrackedDayEntity? trackedDay;

  const DailyNutrientPanel({
    super.key,
    required this.intakes,
    this.selectedDay,
    this.trackedDay,
  });

  // ---- Default daily references (#173) ----------------------------------
  // Published DRIs / FDA Daily Values used when the user hasn't set their
  // own target in Settings → Nutrient goals. Iron and magnesium default
  // to a gender-aware value; the rest are gender-neutral.
  static const double defaultFibreRefG = 30.0;
  static const double defaultSaturatedFatRefG = 20.0;
  static const double defaultSugarRefG = 50.0;
  static const double defaultSodiumRefMg = 2300.0;
  static const double defaultCalciumRefMg = 1000.0;
  static const double defaultPotassiumRefMg = 3500.0;
  static const double defaultVitaminDRefUg = 15.0;
  static const double defaultVitaminB12RefUg = 2.4;
  static const double defaultMagnesiumRefMg = 355.0; // non-binary midpoint

  /// Pure helpers that prefer the user's [TrackedDayEntity] per-nutrient
  /// goal when set, falling back to the published default otherwise.
  /// Public because the unit test suite asserts each one in isolation.
  static double resolveFibreReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.fibreGoal ?? defaultFibreRefG;

  static double resolveSatFatReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.satFatGoal ?? defaultSaturatedFatRefG;

  static double resolveSugarsReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.sugarsGoal ?? defaultSugarRefG;

  static double resolveSodiumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.sodiumGoal ?? defaultSodiumRefMg;

  static double resolveCalciumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.calciumGoal ?? defaultCalciumRefMg;

  /// Iron uses a gender-aware default that the caller supplies, since the
  /// female / male DRIs (18 vs 8 mg) are far enough apart that an averaged
  /// number would mislead one group.
  static double resolveIronReference(
    TrackedDayEntity? trackedDay,
    double genderDefault,
  ) =>
      trackedDay?.ironGoal ?? genderDefault;

  static double resolvePotassiumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.potassiumGoal ?? defaultPotassiumRefMg;

  static double resolveVitaminDReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.vitaminDGoal ?? defaultVitaminDRefUg;

  static double resolveVitaminB12Reference(TrackedDayEntity? trackedDay) =>
      trackedDay?.vitaminB12Goal ?? defaultVitaminB12RefUg;

  static double resolveMagnesiumReference(TrackedDayEntity? trackedDay) =>
      trackedDay?.magnesiumGoal ?? defaultMagnesiumRefMg;

  @override
  State<DailyNutrientPanel> createState() => _DailyNutrientPanelState();
}

class _DailyNutrientPanelState extends State<DailyNutrientPanel> {
  _NutrientView _view = _NutrientView.day;
  // Collapsed by default — see the build method's note on visual weight.
  // Persists for the lifetime of the screen; revisiting the day view
  // resets it, which feels right given how secondary the detail is.
  bool _expanded = false;
  final Set<NutrientPanelGroup> _collapsedGroups = {};

  Future<_PanelData>? _panelDataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _panelDataFuture ??= _loadPanelData();
  }

  @override
  void didUpdateWidget(covariant DailyNutrientPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent passes a fresh intake list whenever the day changes or an
    // intake is added/removed. Refetch so the weekly average stays accurate
    // and the visibility map picks up any Settings edits.
    if (oldWidget.intakes != widget.intakes ||
        oldWidget.selectedDay != widget.selectedDay) {
      _panelDataFuture = _loadPanelData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PanelData>(
      future: _panelDataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        // Render the daily view (no weekly history yet) while the future
        // resolves — keeps the panel from blank-flashing on every rebuild.
        return _buildPanel(context, data);
      },
    );
  }

  Future<_PanelData> _loadPanelData() async {
    UserEntity? user;
    try {
      user = await locator<GetUserUsecase>().getUserData();
    } catch (_) {
      // Pre-onboarding / tests: fall back to gender-neutral defaults.
      user = null;
    }

    Map<String, bool> visibility = const <String, bool>{};
    try {
      final config = await locator<GetConfigUsecase>().getConfig();
      visibility = config.nutrientPanelVisibility;
    } catch (_) {
      // Tests without the locator wired up — default to "all visible".
    }

    List<IntakeEntity> weekIntakes = widget.intakes;
    try {
      final anchor = widget.selectedDay ?? DateTime.now();
      weekIntakes = await _fetchLastSevenDaysIntakes(anchor);
    } catch (_) {
      // If the intake use case isn't registered (tests), the daily view
      // still works fine — fall back to whatever the parent gave us.
      weekIntakes = widget.intakes;
    }

    return _PanelData(
      user: user,
      visibility: visibility,
      weekIntakes: weekIntakes,
    );
  }

  Future<List<IntakeEntity>> _fetchLastSevenDaysIntakes(DateTime anchor) async {
    final getIntakeUsecase = locator<GetIntakeUsecase>();
    final all = <IntakeEntity>[];
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final day = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: dayOffset));
      all
        ..addAll(await getIntakeUsecase.getBreakfastIntakeByDay(day))
        ..addAll(await getIntakeUsecase.getLunchIntakeByDay(day))
        ..addAll(await getIntakeUsecase.getDinnerIntakeByDay(day))
        ..addAll(await getIntakeUsecase.getSnackIntakeByDay(day));
    }
    return all;
  }

  Widget _buildPanel(BuildContext context, _PanelData? data) {
    final user = data?.user;
    final visibility = data?.visibility ?? const <String, bool>{};
    // Pick the right source for totals. Daily view sums today's intakes;
    // weekly view sums the seven-day window and then divides each total by
    // seven to get an average daily intake.
    final isWeekly = _view == _NutrientView.week;
    final source = isWeekly ? (data?.weekIntakes ?? widget.intakes) : widget.intakes;
    final totals = NutrientPanelTotals.fromIntakes(source, weekly: isWeekly);

    // Reference values are sensible adult DRIs / FDA Daily Values. Iron's
    // reference uses UserEntity.gender so women see 18mg and men see 8mg;
    // magnesium follows the same gender-aware pattern (400/310). Non-binary
    // users get a midpoint, in line with the app's existing averaged-
    // reference convention for non-binary calculations.
    // Per-nutrient targets — route through the public resolver helpers so
    // the unit tests and the build method share a single source of truth.
    final td = widget.trackedDay;
    // Helper: prefer the per-day tracked override, then the IOM age-banded
    // DRI when a user record is available, then the gender-agnostic default
    // the panel has always used as a last resort. This keeps the existing
    // resolver helpers as the single source of truth for tests, but layers
    // the age-aware IOM lookup (#245) on top for users we know enough about.
    double resolveWithDri(
      double? Function() trackedOverride,
      String nutrientKey,
      double fallback,
    ) {
      final tracked = trackedOverride();
      if (tracked != null) return tracked;
      if (user != null) {
        final dri = getReferenceFor(nutrient: nutrientKey, user: user);
        if (dri != null) return dri.amount;
      }
      return fallback;
    }

    final fiberRefG = resolveWithDri(
      () => td?.fibreGoal,
      NutrientPanelKeys.fiber,
      DailyNutrientPanel.defaultFibreRefG,
    );
    final sodiumRefMg = resolveWithDri(
      () => td?.sodiumGoal,
      NutrientPanelKeys.sodium,
      DailyNutrientPanel.defaultSodiumRefMg,
    );
    // Saturated fat and sugars have no IOM RDA — the resolver helper still
    // returns the published FDA Daily Value as the fallback for both.
    final saturatedFatRefG = DailyNutrientPanel.resolveSatFatReference(td);
    final sugarRefG = DailyNutrientPanel.resolveSugarsReference(td);
    final calciumRefMg = resolveWithDri(
      () => td?.calciumGoal,
      NutrientPanelKeys.calcium,
      DailyNutrientPanel.defaultCalciumRefMg,
    );
    final ironRefMg = resolveWithDri(
      () => td?.ironGoal,
      NutrientPanelKeys.iron,
      _ironRefForUser(user),
    );
    final potassiumRefMg = resolveWithDri(
      () => td?.potassiumGoal,
      NutrientPanelKeys.potassium,
      DailyNutrientPanel.defaultPotassiumRefMg,
    );
    final vitaminDRefMcg = resolveWithDri(
      () => td?.vitaminDGoal,
      NutrientPanelKeys.vitaminD,
      DailyNutrientPanel.defaultVitaminDRefUg,
    );
    final vitaminB12RefMcg = resolveWithDri(
      () => td?.vitaminB12Goal,
      NutrientPanelKeys.vitaminB12,
      DailyNutrientPanel.defaultVitaminB12RefUg,
    );
    final magnesiumRefMg = resolveWithDri(
      () => td?.magnesiumGoal,
      NutrientPanelKeys.magnesium,
      _magnesiumRefForUser(user),
    );

    final s = S.of(context);
    final references = <String, double?>{
      NutrientPanelKeys.fiber: fiberRefG,
      NutrientPanelKeys.sodium: sodiumRefMg,
      NutrientPanelKeys.saturatedFat: saturatedFatRefG,
      NutrientPanelKeys.sugar: sugarRefG,
      NutrientPanelKeys.calcium: calciumRefMg,
      NutrientPanelKeys.iron: ironRefMg,
      NutrientPanelKeys.potassium: potassiumRefMg,
      NutrientPanelKeys.vitaminD: vitaminDRefMcg,
      NutrientPanelKeys.vitaminB12: vitaminB12RefMcg,
      NutrientPanelKeys.magnesium: magnesiumRefMg,
    };
    final useKj =
        Provider.of<EnergyUnitProvider?>(context)?.usesKilojoules ?? false;
    final groups = <NutrientPanelGroup, List<_NutrientRow>>{};
    for (final row in NutrientPanelRow.all) {
      if (!(visibility[row.key] ?? true)) continue;
      final total = totals.coverage[row.key]!;
      var value = total.sum;
      var reference = references.containsKey(row.key)
          ? references[row.key]
          : NutrientPanelRow.extraReference(row.key, trackedDay: td, user: user);
      var unit = row.field.unit;
      if (row.key == NutrientPanelKeys.energy) {
        if (useKj) {
          value = UnitCalc.kcalToKj(value);
          reference = reference == null ? null : UnitCalc.kcalToKj(reference);
        }
        unit = ' ${useKj ? s.kjLabel : s.kcalLabel}';
      }
      groups.putIfAbsent(row.group, () => []).add(
        _NutrientRow(
          label: row.label(s),
          value: value,
          reference: reference,
          unit: unit,
          excessMatters: row.excessMatters,
          total: total,
        ),
      );
    }

    // Collapsed by default: the diary day view already carries a lot of
    // visual weight (kcal summary, macro circles, sortable meal sections),
    // so the nutrient detail sits inside an ExpansionTile and only reveals
    // itself when the user explicitly opens it. The header still shows
    // "Today's nutrients" so the affordance is discoverable.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing4,
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing8),
        child: Theme(
          // Strips the dividers ExpansionTile would otherwise draw above and
          // below itself — they fight with the calm card surface the panel
          // now sits inside.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(borderRadius: Dimens.borderRadiusL),
            collapsedShape: const RoundedRectangleBorder(borderRadius: Dimens.borderRadiusL),
            tilePadding: const EdgeInsets.symmetric(horizontal: Dimens.spacing12),
            childrenPadding: const EdgeInsets.fromLTRB(
              Dimens.spacing12,
              0.0,
              Dimens.spacing12,
              Dimens.spacing16,
            ),
            title: Row(
              children: [
                Expanded(
                  child: AutoSizeText(
                    s.diaryNutrientPanelTitle,
                    maxLines: 1,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // Inline info icon. Tapping it pops the data-disclaimer
                // dialog without expanding the panel — IconButton's own
                // InkResponse consumes the pointer event, so the
                // surrounding ExpansionTile doesn't toggle.
                Semantics(
                  identifier: 'dri-panel-info',
                  child: IconButton(
                    tooltip: s.driPanelInfoTitle,
                    icon: Icon(
                      Icons.info_outline_rounded,
                      size: 22,
                      color: palette.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing8),
                    onPressed: () => _showDataDisclaimer(context, s),
                  ),
                ),
              ],
            ),
            initiallyExpanded: _expanded,
            onExpansionChanged: (open) => setState(() => _expanded = open),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<_NutrientView>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  showSelectedIcon: false,
                  segments: <ButtonSegment<_NutrientView>>[
                    ButtonSegment(
                      value: _NutrientView.day,
                      label: Text(s.nutrientPanelDayLabel),
                    ),
                    ButtonSegment(
                      value: _NutrientView.week,
                      label: Text(s.nutrientPanelWeekLabel),
                    ),
                  ],
                  selected: <_NutrientView>{_view},
                  onSelectionChanged: (selection) {
                    setState(() => _view = selection.first);
                  },
                ),
              ),
              const SizedBox(height: Dimens.spacing8),
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
                  child: Text(
                    s.nutrientPanelAllHiddenLabel,
                    style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
                  ),
                )
              else
                for (final MapEntry(key: group, value: rows) in groups.entries)
                  ..._groupSection(context, group, rows),
            ],
          ),
        ),
      ),
    );
  }

  /// A group's header, which folds the group in and out, and its rows.
  List<Widget> _groupSection(
    BuildContext context,
    NutrientPanelGroup group,
    List<_NutrientRow> rows,
  ) {
    final collapsed = _collapsedGroups.contains(group);
    return [
      Semantics(
        identifier: 'nutrient-group-${group.name}',
        button: true,
        child: InkWell(
          onTap: () => setState(() {
            if (!_collapsedGroups.remove(group)) _collapsedGroups.add(group);
          }),
          child: Padding(
            padding: const EdgeInsets.only(top: Dimens.spacing8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.label(S.of(context)),
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(collapsed ? Icons.expand_more : Icons.expand_less),
              ],
            ),
          ),
        ),
      ),
      if (!collapsed) ...rows,
    ];
  }

  void _showDataDisclaimer(BuildContext context, S s) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.info_outline),
          title: Text(s.driPanelInfoTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.driPanelInfoBody),
                const SizedBox(height: 12.0),
                Text(s.diaryNutrientPanelDataDisclaimer),
                const SizedBox(height: 16.0),
                Semantics(
                  identifier: 'dri-panel-info-link',
                  child: InkWell(
                    onTap: () async {
                      final uri = Uri.parse(driSourceUrl);
                      // Best-effort link launch — silently no-ops if the
                      // platform reports it cannot handle the URL, which is
                      // friendlier than throwing in front of the user.
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        s.driPanelInfoLinkLabel,
                        style:
                            Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(dialogContext)
                                      .colorScheme
                                      .primary,
                                  decoration: TextDecoration.underline,
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(s.dialogOKLabel),
            ),
          ],
        );
      },
    );
  }

  // Gender-aware defaults for the two nutrients where female / male DRIs
  // disagree substantively. Non-binary users route through their chosen
  // [CaloriesProfileEntity] just like the calorie calculation does
  // (see [TDEECalc.getTDEEKcalIOM2005]): Estrogen-typical → female value,
  // Testosterone-typical → male value, Averaged (default) → midpoint.
  // This keeps a single source of truth for what "non-binary → which
  // reference" means across the app, rather than the nutrient panel
  // silently disagreeing with the calorie panel a few sections above.
  static double _ironRefForUser(UserEntity? user) {
    const female = 18.0;
    const male = 8.0;
    const averaged = 14.0;
    return _dispatchGenderReference(
      user,
      female: female,
      male: male,
      averaged: averaged,
    );
  }

  static double _magnesiumRefForUser(UserEntity? user) {
    const female = 310.0;
    const male = 400.0;
    const averaged = 355.0;
    return _dispatchGenderReference(
      user,
      female: female,
      male: male,
      averaged: averaged,
    );
  }

  static double _dispatchGenderReference(
    UserEntity? user, {
    required double female,
    required double male,
    required double averaged,
  }) {
    if (user == null) return averaged;
    switch (user.gender) {
      case UserGenderEntity.female:
        return female;
      case UserGenderEntity.male:
        return male;
      case UserGenderEntity.nonBinary:
        switch (user.caloriesProfile ?? CaloriesProfileEntity.averaged) {
          case CaloriesProfileEntity.averaged:
            return averaged;
          case CaloriesProfileEntity.estrogenTypical:
            return female;
          case CaloriesProfileEntity.testosteroneTypical:
            return male;
        }
    }
  }
}

enum _NutrientView { day, week }

/// Pure-function helper that aggregates a list of intakes into per-nutrient
/// totals. Pulled out of the widget so unit tests can exercise it directly
/// without spinning up a Flutter binding. `weekly: true` divides every total
/// by 7 to convert a seven-day window into an average daily intake.
class NutrientPanelTotals {
  final double fiberG;
  final double sodiumMg;
  final double saturatedFatG;
  final double sugarG;
  final double calciumMg;
  final double ironMg;
  final double potassiumMg;
  final double vitaminDMcg;
  final double vitaminB12Mcg;
  final double magnesiumMg;

  const NutrientPanelTotals({
    required this.fiberG,
    required this.sodiumMg,
    required this.saturatedFatG,
    required this.sugarG,
    required this.calciumMg,
    required this.ironMg,
    required this.potassiumMg,
    required this.vitaminDMcg,
    required this.vitaminB12Mcg,
    required this.magnesiumMg,
    this.coverage = const {},
  });

  /// Per panel key, how much of the total the logged entries knew (#46).
  final Map<String, NutrientTotal> coverage;

  factory NutrientPanelTotals.fromIntakes(
    List<IntakeEntity> intakes, {
    bool weekly = false,
  }) {
    final divisor = weekly ? 7.0 : 1.0;
    NutrientTotal total(NutrientField field) => NutrientTotal.over(
      intakes,
      per100: (intake) => field.per100(intake.meal.nutriments),
      amountG: (intake) => intake.amount,
      divisor: divisor,
    );

    final coverage = {
      for (final MapEntry(key: key, value: field) in panelFields.entries)
        key: total(field),
    };
    double sum(String key) => coverage[key]!.sum;
    return NutrientPanelTotals(
      fiberG: sum(NutrientPanelKeys.fiber),
      sodiumMg: sum(NutrientPanelKeys.sodium),
      saturatedFatG: sum(NutrientPanelKeys.saturatedFat),
      sugarG: sum(NutrientPanelKeys.sugar),
      calciumMg: sum(NutrientPanelKeys.calcium),
      ironMg: sum(NutrientPanelKeys.iron),
      potassiumMg: sum(NutrientPanelKeys.potassium),
      vitaminDMcg: sum(NutrientPanelKeys.vitaminD),
      vitaminB12Mcg: sum(NutrientPanelKeys.vitaminB12),
      magnesiumMg: sum(NutrientPanelKeys.magnesium),
      coverage: coverage,
    );
  }

  /// The stored nutrient behind each panel key.
  static const panelFields = <String, NutrientField>{
    NutrientPanelKeys.fiber: NutrientField.fiber,
    NutrientPanelKeys.sodium: NutrientField.sodium,
    NutrientPanelKeys.saturatedFat: NutrientField.saturatedFat,
    NutrientPanelKeys.sugar: NutrientField.sugars,
    NutrientPanelKeys.calcium: NutrientField.calcium,
    NutrientPanelKeys.iron: NutrientField.iron,
    NutrientPanelKeys.potassium: NutrientField.potassium,
    NutrientPanelKeys.vitaminD: NutrientField.vitaminD,
    NutrientPanelKeys.vitaminB12: NutrientField.vitaminB12,
    NutrientPanelKeys.magnesium: NutrientField.magnesium,
    NutrientPanelKeys.energy: NutrientField.energyKcal,
    NutrientPanelKeys.carbohydrates: NutrientField.carbohydrates,
    NutrientPanelKeys.fat: NutrientField.fat,
    NutrientPanelKeys.protein: NutrientField.proteins,
    NutrientPanelKeys.monounsaturatedFat: NutrientField.monounsaturatedFat,
    NutrientPanelKeys.polyunsaturatedFat: NutrientField.polyunsaturatedFat,
    NutrientPanelKeys.transFat: NutrientField.transFat,
    NutrientPanelKeys.cholesterol: NutrientField.cholesterol,
    NutrientPanelKeys.zinc: NutrientField.zinc,
    NutrientPanelKeys.phosphorus: NutrientField.phosphorus,
    NutrientPanelKeys.vitaminA: NutrientField.vitaminA,
    NutrientPanelKeys.vitaminC: NutrientField.vitaminC,
    NutrientPanelKeys.vitaminB6: NutrientField.vitaminB6,
    NutrientPanelKeys.niacin: NutrientField.niacin,
  };
}

/// Stable identifiers for the panel's nutrient rows. These are the keys the
/// per-nutrient visibility map uses on [ConfigEntity], so renaming any of
/// them is a backward-incompatible change: existing visibility overrides
/// would silently lose their associations.
class NutrientPanelKeys {
  NutrientPanelKeys._();

  static const String fiber = 'fiber';
  static const String sodium = 'sodium';
  static const String saturatedFat = 'saturated_fat';
  static const String sugar = 'sugar';
  static const String calcium = 'calcium';
  static const String iron = 'iron';
  static const String potassium = 'potassium';
  static const String vitaminD = 'vitamin_d';
  static const String vitaminB12 = 'vitamin_b12';
  static const String magnesium = 'magnesium';
  static const String energy = 'energy';
  static const String carbohydrates = 'carbohydrates';
  static const String fat = 'fat';
  static const String protein = 'protein';
  static const String monounsaturatedFat = 'monounsaturated_fat';
  static const String polyunsaturatedFat = 'polyunsaturated_fat';
  static const String transFat = 'trans_fat';
  static const String cholesterol = 'cholesterol';
  static const String zinc = 'zinc';
  static const String phosphorus = 'phosphorus';
  static const String vitaminA = 'vitamin_a';
  static const String vitaminC = 'vitamin_c';
  static const String vitaminB6 = 'vitamin_b6';
  static const String niacin = 'niacin';

  static const List<String> all = <String>[
    fiber,
    sodium,
    saturatedFat,
    sugar,
    calcium,
    iron,
    potassium,
    vitaminD,
    vitaminB12,
    magnesium,
    energy,
    carbohydrates,
    fat,
    protein,
    monounsaturatedFat,
    polyunsaturatedFat,
    transFat,
    cholesterol,
    zinc,
    phosphorus,
    vitaminA,
    vitaminC,
    vitaminB6,
    niacin,
  ];

  /// The keys added in #47 whose own goal lives in
  /// `TrackedDayEntity.extraNutrientGoals`; energy and the macros take
  /// theirs from the day's calorie and macro goals instead.
  static const List<String> extraGoalKeys = <String>[
    monounsaturatedFat,
    polyunsaturatedFat,
    transFat,
    cholesterol,
    zinc,
    phosphorus,
    vitaminA,
    vitaminC,
    vitaminB6,
    niacin,
  ];
}

class _PanelData {
  final UserEntity? user;
  final Map<String, bool> visibility;
  final List<IntakeEntity> weekIntakes;

  _PanelData({
    required this.user,
    required this.visibility,
    required this.weekIntakes,
  });
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final double value;

  /// Null when the nutrient has no reference: the row shows the amount
  /// without a bar.
  final double? reference;
  final String unit;

  /// Whether going over the reference is a problem (sodium, saturated fat,
  /// sugar) versus simply not meeting a target (fibre, calcium, iron,
  /// potassium, vitamin D, vitamin B12, magnesium). Affects the colour the
  /// bar turns when the user goes over.
  final bool excessMatters;

  /// How much of [value] the entries knew: "unknown" when none did, "at
  /// least" when only some (#46).
  final NutrientTotal? total;

  const _NutrientRow({
    required this.label,
    required this.value,
    required this.reference,
    required this.unit,
    required this.excessMatters,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;
    final reference = this.reference;
    final ratio = switch (reference) {
      final ref? when ref > 0 => value / ref,
      final ref? when ref == 0 && value > 0 && excessMatters => 1.0,
      _ => 0.0,
    };
    final clamped = ratio.clamp(0.0, 1.0).toDouble();
    final color = _colorForRatio(context, ratio);
    final unknown = total?.isUnknown ?? false;
    final partial = total?.isPartial ?? false;
    final referenceLabel = reference == null
        ? null
        : '${reference.toStringAsFixed(reference >= 10 ? 0 : 1)}$unit';
    final amountLabel =
        '${partial ? '≥ ' : ''}${value.toStringAsFixed(value >= 10 ? 0 : 1)}';
    final valueLabel = switch ((unknown, referenceLabel)) {
      (true, null) => s.nutrientUnknownLabel,
      (true, final ref?) => '${s.nutrientUnknownLabel} / $ref',
      (false, null) => '$amountLabel$unit',
      (false, final ref?) => '$amountLabel / $ref',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(color: palette.textStrong),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // For ceiling nutrients (sodium, saturated fat, sugar) the
                  // reference is a limit to stay under, not a target to reach.
                  // A small qualifier says so, since the bare "x / y" reads as
                  // a goal otherwise.
                  if (excessMatters && reference != null) ...[
                    Text(
                      s.nutrientPanelLimitLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: Dimens.spacing4),
                  ],
                  Text(
                    valueLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (partial)
            Text(
              s.nutrientPartialHint(total!.unknownEntries),
              style: textTheme.labelSmall?.copyWith(color: palette.textMuted),
            ),
          if (reference != null) ...[
            const SizedBox(height: Dimens.spacing8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                value: unknown ? 0 : clamped,
                minHeight: 8.0,
                backgroundColor: palette.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorForRatio(BuildContext context, double ratio) {
    final scheme = Theme.of(context).colorScheme;
    if (excessMatters) {
      // Sodium / saturated fat / sugar: amber as you approach the reference,
      // red once you cross it, green while comfortably below.
      if (ratio >= 1.0) return scheme.error;
      if (ratio >= 0.8) return Colors.amber.shade700;
      return scheme.primary;
    } else {
      // Fibre / calcium / iron / potassium / vitamin D / B12 / magnesium:
      // amber while still well short of the reference, primary green once
      // you reach it. Going over isn't a concern at these values from food
      // alone.
      if (ratio >= 1.0) return scheme.primary;
      if (ratio >= 0.5) return Colors.amber.shade700;
      return scheme.primary.withValues(alpha: 0.6);
    }
  }
}
