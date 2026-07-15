import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Fast path for logging an activity by typing the time spent and the
/// calories burned directly, for people whose tracker (a step counter,
/// a watch) already gives them a kcal figure that the MET-based presets
/// don't match (#472). Mirrors the food Quick Add sheet: the burned
/// energy is required, the duration is an optional note, and the activity
/// is stored as a Custom one so the entered kcal is used verbatim rather
/// than recomputed.
class QuickAddActivityBottomSheet extends StatefulWidget {
  final DateTime day;

  const QuickAddActivityBottomSheet({super.key, required this.day});

  @override
  State<QuickAddActivityBottomSheet> createState() =>
      _QuickAddActivityBottomSheetState();
}

class _QuickAddActivityBottomSheetState
    extends State<QuickAddActivityBottomSheet> {
  final _log = Logger('QuickAddActivityBottomSheet');

  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _energyController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _energyController.addListener(_onRequiredFieldChanged);
  }

  @override
  void dispose() {
    _energyController.removeListener(_onRequiredFieldChanged);
    _nameController.dispose();
    _durationController.dispose();
    _energyController.dispose();
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
    return !_saving && energy != null && energy > 0;
  }

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);

    final usesKj = context.read<EnergyUnitProvider>().usesKilojoules;
    final enteredEnergy = _parsed(_energyController)!;
    final kcal = usesKj ? UnitCalc.kjToKcal(enteredEnergy) : enteredEnergy;
    final duration = _parsed(_durationController) ?? 0;
    final name = _nameController.text.trim();

    try {
      final activity = UserActivityEntity(
        IdGenerator.getUniqueID(),
        duration,
        kcal,
        widget.day,
        name.isEmpty
            ? PhysicalActivityEntity.custom
            : PhysicalActivityEntity.customNamed(name),
        userKcal: kcal,
      );
      await locator<AddUserActivityUsecase>().addUserActivity(activity);
      await _updateTrackedDay(kcal);

      locator<HomeBloc>().add(const LoadItemsEvent());
      locator<DiaryBloc>().add(const LoadDiaryYearEvent());
      locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      // Resolve the message before navigating: the push below tears down
      // this sheet, so reading from context afterwards is unsafe.
      final addedMessage = S.of(context).quickAddActivityAddedSnack;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        NavigationOptions.mainRoute,
        (route) => false,
      );
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(addedMessage)));
    } catch (e, st) {
      _log.severe('Quick Add activity save failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  /// Burned calories raise the day's goal ceiling, mirroring
  /// `ActivityDetailBloc._updateTrackedDay`.
  Future<void> _updateTrackedDay(double caloriesBurned) async {
    final addTrackedDay = locator<AddTrackedDayUsecase>();
    final hasTrackedDay = await addTrackedDay.hasTrackedDay(widget.day);
    if (!hasTrackedDay) {
      final kcalGoal = await locator<GetKcalGoalUsecase>().getKcalGoal(
        totalKcalActivitiesParam: 0,
      );
      final macroGoal = locator<GetMacroGoalUsecase>();
      await addTrackedDay.addNewTrackedDay(
        widget.day,
        kcalGoal,
        await macroGoal.getCarbsGoal(kcalGoal),
        await macroGoal.getFatsGoal(kcalGoal),
        await macroGoal.getProteinsGoal(kcalGoal),
      );
    }
    await addTrackedDay.increaseDayCalorieGoal(widget.day, caloriesBurned);
    await addTrackedDay.increaseDayMacroGoals(
      widget.day,
      carbsAmount: MacroCalc.getTotalCarbsGoal(caloriesBurned),
      fatAmount: MacroCalc.getTotalFatsGoal(caloriesBurned),
      proteinAmount: MacroCalc.getTotalProteinsGoal(caloriesBurned),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usesKj = context.watch<EnergyUnitProvider>().usesKilojoules;
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Dimens.spacing24,
          Dimens.spacing8,
          Dimens.spacing24,
          Dimens.spacing24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing16),
              child: Text(
                s.quickAddActivityTitleLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            _field(
              controller: _nameController,
              identifier: 'quick-add-activity-name',
              label: s.quickAddActivityNameLabel,
              isRequired: false,
              numeric: false,
              autofocus: true,
            ),
            _field(
              controller: _energyController,
              identifier: 'quick-add-activity-energy',
              label: usesKj
                  ? s.quickAddActivityEnergyLabelKj
                  : s.quickAddActivityEnergyLabelKcal,
              isRequired: true,
            ),
            _field(
              controller: _durationController,
              identifier: 'quick-add-activity-duration',
              label: s.quickAddActivityDurationLabel,
              isRequired: false,
            ),
            const SizedBox(height: Dimens.spacing16),
            Semantics(
              identifier: 'quick-add-activity-submit',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: Dimens.shapeM,
                  padding: const EdgeInsets.symmetric(vertical: Dimens.spacing16),
                ),
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
    bool numeric = true,
    bool autofocus = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spacing12),
      child: Semantics(
        identifier: identifier,
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          textCapitalization:
              numeric ? TextCapitalization.none : TextCapitalization.sentences,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            filled: true,
            fillColor: palette.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: Dimens.borderRadiusM,
              borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: Dimens.borderRadiusM,
              borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Dimens.borderRadiusM,
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
