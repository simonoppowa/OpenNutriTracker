import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/sheet_bottom_inset.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class QuickAddBottomSheet extends StatefulWidget {
  final IntakeTypeEntity intakeType;
  final DateTime day;

  /// The add-food screen's "To log" list. Once it has items, the entry goes
  /// on the list and the sheet closes, instead of logging and leaving for
  /// home — which would drop everything already on the list. While it is
  /// empty the entry is logged at once, as before the list existed, and a
  /// second button puts it on the list instead (#1520). A food still on its
  /// way onto the list counts as an item (see [LogTray.collects]).
  final LogTray? logTray;

  /// Always put the entry on [logTray], never log it on its own. For a
  /// caller with unsaved foods of its own that are not on the list yet —
  /// the review screen, whose batch joins the list only when confirmed —
  /// which logging on its own would leave and lose.
  final bool addsToListOnly;

  const QuickAddBottomSheet({
    super.key,
    required this.intakeType,
    required this.day,
    this.logTray,
    this.addsToListOnly = false,
  });

  @override
  State<QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<QuickAddBottomSheet> {
  final _log = Logger('QuickAddBottomSheet');

  final _titleController = TextEditingController();
  final _energyController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _proteinController = TextEditingController();
  final _weightController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onRequiredFieldChanged);
    _energyController.addListener(_onRequiredFieldChanged);
    // A weight that is typed but not usable blocks the entry (#705).
    _weightController.addListener(_onRequiredFieldChanged);
    // The button reads "Add" or "Add to list" from the list's state, which
    // a food arriving from a + changes while the sheet is open.
    widget.logTray?.addListener(_onTrayChanged);
  }

  @override
  void dispose() {
    widget.logTray?.removeListener(_onTrayChanged);
    _titleController.removeListener(_onRequiredFieldChanged);
    _energyController.removeListener(_onRequiredFieldChanged);
    _weightController.removeListener(_onRequiredFieldChanged);
    _titleController.dispose();
    _energyController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _proteinController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onRequiredFieldChanged() => setState(() {});

  void _onTrayChanged() => setState(() {});

  double? _parsed(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value < 0) return null;
    return value;
  }

  /// The weight typed, in grams, or null when the field is left empty.
  double? get _weight => _weightInvalid ? null : _parsed(_weightController);

  /// A weight was typed that cannot be one: zero, negative or not a number.
  /// Empty is not invalid — it means the weight is unknown (#705).
  bool get _weightInvalid {
    if (_weightController.text.trim().isEmpty) return false;
    final weight = _parsed(_weightController);
    return weight == null || weight <= 0;
  }

  bool get _canSubmit {
    final energy = _parsed(_energyController);
    final hasTitle = _titleController.text.trim().isNotEmpty;
    return !_saving &&
        hasTitle &&
        energy != null &&
        energy > 0 &&
        !_weightInvalid;
  }

  /// Whether the main button adds to the list rather than logging.
  bool get _addsToList {
    final logTray = widget.logTray;
    return logTray != null && (widget.addsToListOnly || logTray.collects);
  }

  Future<void> _onSubmit({bool toList = false}) async {
    if (!_canSubmit) return;
    setState(() => _saving = true);

    final usesKj = context.read<EnergyUnitProvider>().usesKilojoules;
    final enteredEnergy = _parsed(_energyController)!;
    final kcal = usesKj ? UnitCalc.kjToKcal(enteredEnergy) : enteredEnergy;
    final carbs = _parsed(_carbsController);
    final fat = _parsed(_fatController);
    final protein = _parsed(_proteinController);
    final title = _titleController.text.trim();
    final weight = _weight;

    try {
      final intake = _buildIntake(
        kcal: kcal,
        carbs: carbs,
        fat: fat,
        protein: protein,
        title: title,
        weight: weight,
      );
      final logTray = widget.logTray;
      // Asked again, not taken from the press: a food that reached the list
      // since must not be left behind by logging on its own.
      if (logTray != null && (toList || _addsToList)) {
        logTray.add(
          LogTrayItem(
            meal: intake.meal,
            unit: intake.unit,
            amount: intake.amount,
            amountLabel: weight == null
                ? S.of(context).quickAddCardLabel
                : logTrayAmountLabel(context, weight, intake.unit, intake.meal),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      // The entry and its row together, so no reconciliation counts the
      // entry before the row has it (#1317).
      final saved = await withTrackedDayLockOnProfile(() async {
        await locator<AddIntakeUsecase>().addIntake(intake);
        await _updateTrackedDay(intake);
        return true;
      });
      if (saved != true) {
        if (mounted) setState(() => _saving = false);
        return;
      }

      locator<HomeBloc>().add(const LoadItemsEvent());
      locator<DiaryBloc>().add(const LoadDiaryYearEvent());
      locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

      if (!mounted) return;
      final mealTypeLabel = _intakeTypeLabel(context, widget.intakeType);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      // Resolve the localized message before navigating: the push below
      // removes every route (including this sheet's), so reading from
      // context afterwards would be looking up a deactivated widget.
      final addedMessage = S.of(context).quickAddAddedSnack(mealTypeLabel);
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        NavigationOptions.mainRoute,
        (route) => false,
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(addedMessage),
        ),
      );
    } catch (e, st) {
      _log.severe('Quick Add save failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  IntakeEntity _buildIntake({
    required double kcal,
    required double? carbs,
    required double? fat,
    required double? protein,
    required String title,
    required double? weight,
  }) {
    // The values typed are totals. Nutrition is stored per 100 g, so they
    // are scaled to that basis and the intake carries the amount they are
    // totals for: the weight when there is one, otherwise 100 g/ml with the
    // meal marked as fixed totals (#705), so nothing shows or rescales that
    // made-up 100.
    final basis = weight ?? MealEntity.fixedTotalsBasis;
    double? per100(double? total) => total == null ? null : total * 100 / basis;
    final nutriments = MealNutrimentsEntity(
      energyKcal100: per100(kcal),
      carbohydrates100: per100(carbs),
      fat100: per100(fat),
      proteins100: per100(protein),
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );
    final unit = weight == null ? 'gml' : 'g';
    final meal = MealEntity(
      code: IdGenerator.getUniqueID(),
      name: title,
      url: null,
      mealQuantity: _formatWeight(basis),
      mealUnit: unit,
      servingQuantity: null,
      servingUnit: unit,
      servingSize: '',
      nutriments: nutriments,
      source: MealSourceEntity.custom,
      fixedTotals: weight == null,
    );
    return IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: basis,
      type: widget.intakeType,
      meal: meal,
      dateTime: widget.day,
    );
  }

  /// "100", "312.5": how the weight is kept as the meal's quantity.
  static String _formatWeight(double grams) => grams == grams.roundToDouble()
      ? grams.toStringAsFixed(0)
      : grams.toString();

  Future<void> _updateTrackedDay(IntakeEntity intake) async {
    final addTrackedDay = locator<AddTrackedDayUsecase>();
    final hasTrackedDay = await addTrackedDay.hasTrackedDay(widget.day);
    if (!hasTrackedDay) {
      final kcalGoal = await locator<GetKcalGoalUsecase>().getKcalGoal();
      final macroGoal = locator<GetMacroGoalUsecase>();
      await addTrackedDay.addNewTrackedDayIfAbsent(
        widget.day,
        kcalGoal,
        await macroGoal.getCarbsGoal(kcalGoal),
        await macroGoal.getFatsGoal(kcalGoal),
        await macroGoal.getProteinsGoal(kcalGoal),
      );
    }
    await addTrackedDay.addDayCaloriesTracked(widget.day, intake.totalKcal);
    await addTrackedDay.addDayMacrosTracked(
      widget.day,
      carbsTracked: intake.totalCarbsGram,
      fatTracked: intake.totalFatsGram,
      proteinTracked: intake.totalProteinsGram,
    );
  }

  String _intakeTypeLabel(BuildContext context, IntakeTypeEntity type) {
    switch (type) {
      case IntakeTypeEntity.breakfast:
        return S.of(context).breakfastLabel;
      case IntakeTypeEntity.lunch:
        return S.of(context).lunchLabel;
      case IntakeTypeEntity.dinner:
        return S.of(context).dinnerLabel;
      case IntakeTypeEntity.snack:
        return S.of(context).snackLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usesKj = context.watch<EnergyUnitProvider>().usesKilojoules;
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: sheetBottomInset(context),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                s.quickAddBottomSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            _field(
              controller: _titleController,
              identifier: 'quick-add-title',
              label: s.quickAddTitleHint,
              isRequired: true,
              numeric: false,
              autofocus: true,
            ),
            _field(
              controller: _energyController,
              identifier: 'quick-add-energy',
              label: usesKj ? s.quickAddEnergyLabelKj : s.quickAddEnergyLabelKcal,
              isRequired: true,
              numeric: true,
            ),
            _field(
              controller: _carbsController,
              identifier: 'quick-add-carbs',
              label: s.quickAddCarbsHint,
              isRequired: false,
              numeric: true,
            ),
            _field(
              controller: _fatController,
              identifier: 'quick-add-fat',
              label: s.quickAddFatHint,
              isRequired: false,
              numeric: true,
            ),
            _field(
              controller: _proteinController,
              identifier: 'quick-add-protein',
              label: s.quickAddProteinHint,
              isRequired: false,
              numeric: true,
            ),
            _field(
              controller: _weightController,
              identifier: 'quick-add-weight',
              label: s.quickAddWeightHint,
              isRequired: false,
              numeric: true,
              helperText: s.quickAddWeightHelper,
              errorText: _weightInvalid ? s.quickAddWeightInvalid : null,
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'quick-add-submit',
              child: FilledButton(
                onPressed: _canSubmit
                    ? () => _onSubmit(toList: _addsToList)
                    : null,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _addsToList ? s.addToListLabel : s.quickAddSubmitLabel,
                      ),
              ),
            ),
            if (widget.logTray != null && !_addsToList) ...[
              const SizedBox(height: 8),
              Semantics(
                identifier: 'quick-add-add-to-list',
                child: OutlinedButton(
                  onPressed: _canSubmit ? () => _onSubmit(toList: true) : null,
                  child: Text(s.addToListLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String identifier,
    required String label,
    required bool isRequired,
    required bool numeric,
    bool autofocus = false,
    String? helperText,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        identifier: identifier,
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric ? CustomTextInputFormatter.doubleOnly() : null,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            helperText: helperText,
            helperMaxLines: 3,
            errorText: errorText,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
