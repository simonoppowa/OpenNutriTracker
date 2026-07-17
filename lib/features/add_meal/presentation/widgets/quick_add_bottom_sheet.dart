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

  const QuickAddBottomSheet({
    super.key,
    required this.intakeType,
    required this.day,
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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onRequiredFieldChanged);
    _energyController.addListener(_onRequiredFieldChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onRequiredFieldChanged);
    _energyController.removeListener(_onRequiredFieldChanged);
    _titleController.dispose();
    _energyController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  void _onRequiredFieldChanged() => setState(() {});

  double? _parsed(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value < 0) return null;
    return value;
  }

  bool get _canSubmit {
    final energy = _parsed(_energyController);
    final hasTitle = _titleController.text.trim().isNotEmpty;
    return !_saving && hasTitle && energy != null && energy > 0;
  }

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);

    final usesKj = context.read<EnergyUnitProvider>().usesKilojoules;
    final enteredEnergy = _parsed(_energyController)!;
    final kcal = usesKj ? UnitCalc.kjToKcal(enteredEnergy) : enteredEnergy;
    final carbs = _parsed(_carbsController);
    final fat = _parsed(_fatController);
    final protein = _parsed(_proteinController);
    final title = _titleController.text.trim();

    try {
      final intake = _buildIntake(
        kcal: kcal,
        carbs: carbs,
        fat: fat,
        protein: protein,
        title: title,
      );
      await locator<AddIntakeUsecase>().addIntake(intake);
      await _updateTrackedDay(intake);

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
  }) {
    // Store per-100g, intake amount = 100g, so totals math returns the
    // exact values the user typed.
    final nutriments = MealNutrimentsEntity(
      energyKcal100: kcal,
      carbohydrates100: carbs,
      fat100: fat,
      proteins100: protein,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );
    final meal = MealEntity(
      code: IdGenerator.getUniqueID(),
      name: title,
      url: null,
      mealQuantity: '100',
      mealUnit: 'gml',
      servingQuantity: null,
      servingUnit: 'gml',
      servingSize: '',
      nutriments: nutriments,
      source: MealSourceEntity.custom,
    );
    return IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: 100,
      type: widget.intakeType,
      meal: meal,
      dateTime: widget.day,
    );
  }

  Future<void> _updateTrackedDay(IntakeEntity intake) async {
    final addTrackedDay = locator<AddTrackedDayUsecase>();
    final hasTrackedDay = await addTrackedDay.hasTrackedDay(widget.day);
    if (!hasTrackedDay) {
      final kcalGoal = await locator<GetKcalGoalUsecase>().getKcalGoal();
      final macroGoal = locator<GetMacroGoalUsecase>();
      await addTrackedDay.addNewTrackedDay(
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
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
            const SizedBox(height: 16),
            Semantics(
              identifier: 'quick-add-submit',
              child: FilledButton(
                onPressed: _canSubmit ? _onSubmit : null,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.quickAddSubmitLabel),
              ),
            ),
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
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
