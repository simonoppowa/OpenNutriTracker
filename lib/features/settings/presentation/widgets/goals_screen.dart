import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_store.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Settings → Goals (#33): the kcal goal calculated or fixed, the macro
/// goals as a split or in grams, and optionally a second set for training
/// days with the weekdays that are training days (#35). Each mode keeps its
/// own values while the user switches; switching to grams for the first
/// time converts the split. The split itself is edited in the existing
/// split dialog ([onEditSplit]) and shared by both sets.
class GoalsScreen extends StatefulWidget {
  final GoalSettingsStore? store;
  final Future<void> Function(BuildContext context) onEditSplit;

  const GoalsScreen({super.key, this.store, required this.onEditSplit});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

/// The editable state of one goal set.
class _GoalForm {
  KcalGoalMode kcalMode = KcalGoalMode.calculated;
  MacroGoalMode macroMode = MacroGoalMode.percent;
  final fixedKcal = TextEditingController();
  final carbs = TextEditingController();
  final fat = TextEditingController();
  final protein = TextEditingController();
  String? kcalError;
  String? gramsError;

  List<TextEditingController> get grams => [carbs, fat, protein];

  void fill(GoalTargets targets) {
    kcalMode = targets.kcalMode;
    macroMode = targets.macroMode;
    fixedKcal.text = _format(targets.fixedKcal);
    carbs.text = _format(targets.carbsG);
    fat.text = _format(targets.fatG);
    protein.text = _format(targets.proteinG);
  }

  void dispose() {
    for (final controller in [fixedKcal, carbs, fat, protein]) {
      controller.dispose();
    }
  }

  static String _format(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

class _GoalsScreenState extends State<GoalsScreen> {
  /// How far the macros' kcal may be off the kcal goal before the screen
  /// points it out.
  static const _kcalMismatchTolerance = 0.1;

  late final GoalSettingsStore _store =
      widget.store ?? locator<GoalSettingsStore>();
  final _rest = _GoalForm();
  final _training = _GoalForm();

  bool _loaded = false;
  bool _loadFailed = false;
  bool _saving = false;
  bool _trainingEnabled = false;
  bool _editingTraining = false;
  Set<int> _trainingWeekdays = {};
  AutoTrainingDay _autoTrainingDay = AutoTrainingDay.off;
  TrainingPlan _plan = const TrainingPlan();
  double _calculatedKcal = 0;
  ({double carbs, double fat, double protein}) _split = (
    carbs: 0,
    fat: 0,
    protein: 0,
  );

  _GoalForm get _form => _editingTraining ? _training : _rest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rest.dispose();
    _training.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final targets = await _store.loadTargets();
      final plan = await _store.loadTrainingPlan();
      final split = await _store.loadSplit();
      final calculated = await _store.calculatedKcal();
      if (!mounted) return;
      setState(() {
        _rest.fill(targets);
        _training.fill(plan.trainingTargets ?? targets);
        _trainingEnabled = plan.isEnabled;
        _trainingWeekdays = {...plan.trainingWeekdays};
        _autoTrainingDay = plan.autoTrainingDay;
        _plan = plan;
        _split = split;
        _calculatedKcal = calculated;
        _loaded = true;
      });
    } catch (error, stackTrace) {
      Logger(
        'GoalsScreen',
      ).warning('Could not load the goals', error, stackTrace);
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// The kcal goal the split and the grams of [form] are measured against:
  /// its fixed goal while one is typed in, else the calculated one.
  double _baseKcal(_GoalForm form) {
    final fixed = _parse(form.fixedKcal.text);
    return form.kcalMode == KcalGoalMode.fixed && fixed != null && fixed > 0
        ? fixed
        : _calculatedKcal;
  }

  void _onMacroModeChanged(MacroGoalMode mode) {
    final form = _form;
    setState(() {
      form.macroMode = mode;
      form.gramsError = null;
      if (mode == MacroGoalMode.grams &&
          form.grams.every((c) => c.text.trim().isEmpty)) {
        final goals = MacroGoalResolver.macros(
          const GoalTargets(),
          kcalGoal: _baseKcal(form),
          carbsPct: _split.carbs / 100,
          fatPct: _split.fat / 100,
          proteinPct: _split.protein / 100,
        );
        form.carbs.text = goals.carbsG.round().toString();
        form.fat.text = goals.fatG.round().toString();
        form.protein.text = goals.proteinG.round().toString();
      }
    });
  }

  Future<void> _editSplit() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = S.of(context).goalsLoadFailed;
    await widget.onEditSplit(context);
    try {
      final split = await _store.loadSplit();
      if (mounted) setState(() => _split = split);
    } catch (error, stackTrace) {
      Logger(
        'GoalsScreen',
      ).warning('Could not reload the split', error, stackTrace);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  /// Checks what [form]'s modes show and sets its errors; returns the
  /// targets, or null when something shown is invalid. A value the other
  /// mode would use is kept when valid and dropped when not, so nothing
  /// hidden blocks the save.
  GoalTargets? _validate(_GoalForm form, S s) {
    final fixed = _parse(form.fixedKcal.text);
    final fixedValid =
        fixed != null &&
        fixed >= GoalTargets.minFixedKcal &&
        fixed <= GoalTargets.maxFixedKcal;
    final typed = [for (final c in form.grams) _parse(c.text)];
    final grams = [for (final g in typed) _validGrams(g)];
    form.kcalError = form.kcalMode == KcalGoalMode.fixed && !fixedValid
        ? s.goalsKcalRangeError(
            GoalTargets.minFixedKcal.toInt(),
            GoalTargets.maxFixedKcal.toInt(),
          )
        : null;
    form.gramsError = null;
    if (form.macroMode == MacroGoalMode.grams) {
      if (typed.any((g) => g == null)) {
        form.gramsError = s.goalsGramsMissing;
      } else if (grams.any((g) => g == null)) {
        form.gramsError = s.goalsGramsRangeError(GoalTargets.maxMacroG.toInt());
      }
    }
    if (form.kcalError != null || form.gramsError != null) return null;
    return GoalTargets(
      kcalMode: form.kcalMode,
      fixedKcal: fixedValid ? fixed : null,
      macroMode: form.macroMode,
      carbsG: grams[0],
      fatG: grams[1],
      proteinG: grams[2],
    );
  }

  static double? _validGrams(double? grams) =>
      grams != null && grams >= 0 && grams <= GoalTargets.maxMacroG
      ? grams
      : null;

  Future<void> _save() async {
    if (_saving) return;
    final s = S.of(context);
    final rest = _validate(_rest, s);
    final training = _trainingEnabled ? _validate(_training, s) : null;
    if (rest == null || _trainingEnabled && training == null) {
      setState(() => _editingTraining = rest != null);
      return;
    }

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _store.save(
        rest,
        _plan
            .withTrainingTargets(training)
            .withTrainingWeekdays(
              _trainingEnabled ? _trainingWeekdays : _plan.trainingWeekdays,
            )
            .withAutoTrainingDay(
              _trainingEnabled ? _autoTrainingDay : _plan.autoTrainingDay,
            ),
      );
    } catch (error, stackTrace) {
      Logger(
        'GoalsScreen',
      ).warning('Could not save the goals', error, stackTrace);
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(s.goalsSaveFailed)));
      return;
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(s.goalsSaved)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.goalsTitle),
        actions: [
          Semantics(
            identifier: 'goals-save',
            child: TextButton(
              onPressed: _loaded && !_saving ? _save : null,
              child: Text(s.buttonSaveLabel),
            ),
          ),
        ],
      ),
      body: _loadFailed
          ? Center(child: Text(s.goalsLoadFailed))
          : !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Dimens.spacing16),
              children: [
                ..._trainingSection(context),
                _sectionTitle(context, s.goalsKcalSection),
                _kcalSection(context),
                const SizedBox(height: Dimens.spacing24),
                _sectionTitle(context, s.goalsMacroSection),
                _macroSection(context),
              ],
            ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: Dimens.spacing8),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  List<Widget> _trainingSection(BuildContext context) {
    final s = S.of(context);
    final weekdayNames = DateFormat.E(
      Localizations.localeOf(context).toString(),
    );
    return [
      Semantics(
        identifier: 'goals-training-enabled',
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.goalsTrainingEnabled),
          subtitle: Text(s.goalsTrainingEnabledHint),
          value: _trainingEnabled,
          onChanged: (value) => setState(() {
            _trainingEnabled = value;
            if (!value) _editingTraining = false;
          }),
        ),
      ),
      if (_trainingEnabled) ...[
        const SizedBox(height: Dimens.spacing8),
        Text(s.goalsTrainingWeekdays),
        const SizedBox(height: Dimens.spacing8),
        Wrap(
          spacing: Dimens.spacing8,
          runSpacing: Dimens.spacing8,
          children: [
            for (var day = DateTime.monday; day <= DateTime.sunday; day++)
              Semantics(
                identifier: 'goals-weekday-$day',
                child: FilterChip(
                  label: Text(weekdayNames.format(DateTime(2024, 1, day))),
                  selected: _trainingWeekdays.contains(day),
                  onSelected: (selected) => setState(() {
                    selected
                        ? _trainingWeekdays.add(day)
                        : _trainingWeekdays.remove(day);
                  }),
                ),
              ),
          ],
        ),
        const SizedBox(height: Dimens.spacing16),
        Text(s.autoTrainingDayLabel),
        const SizedBox(height: Dimens.spacing8),
        Semantics(
          identifier: 'goals-auto-training-day',
          child: SegmentedButton<AutoTrainingDay>(
            segments: [
              ButtonSegment(
                value: AutoTrainingDay.off,
                label: Text(s.autoTrainingDayOff),
              ),
              ButtonSegment(
                value: AutoTrainingDay.suggest,
                label: Text(s.autoTrainingDaySuggest),
              ),
              ButtonSegment(
                value: AutoTrainingDay.automatic,
                label: Text(s.autoTrainingDayAutomatic),
              ),
            ],
            selected: {_autoTrainingDay},
            onSelectionChanged: (selection) =>
                setState(() => _autoTrainingDay = selection.first),
          ),
        ),
        const SizedBox(height: Dimens.spacing16),
        Semantics(
          identifier: 'goals-day-set',
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(s.goalsRestDay)),
              ButtonSegment(value: true, label: Text(s.goalsTrainingDay)),
            ],
            selected: {_editingTraining},
            onSelectionChanged: (selection) =>
                setState(() => _editingTraining = selection.first),
          ),
        ),
      ],
      const SizedBox(height: Dimens.spacing24),
    ];
  }

  Widget _kcalSection(BuildContext context) {
    final s = S.of(context);
    final form = _form;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'goals-kcal-mode',
          child: SegmentedButton<KcalGoalMode>(
            segments: [
              ButtonSegment(
                value: KcalGoalMode.calculated,
                label: Text(s.goalsKcalCalculated),
              ),
              ButtonSegment(
                value: KcalGoalMode.fixed,
                label: Text(s.goalsKcalFixed),
              ),
            ],
            selected: {form.kcalMode},
            onSelectionChanged: (selection) => setState(() {
              form.kcalMode = selection.first;
              form.kcalError = null;
            }),
          ),
        ),
        const SizedBox(height: Dimens.spacing12),
        if (form.kcalMode == KcalGoalMode.calculated)
          Text(s.goalsKcalCalculatedHint(_calculatedKcal.round()))
        else
          Semantics(
            identifier: 'goals-kcal-fixed',
            child: TextField(
              key: ValueKey('fixed-kcal-$_editingTraining'),
              controller: form.fixedKcal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.goalsKcalFixedLabel,
                suffixText: s.kcalLabel,
                helperText: s.goalsKcalFixedHint,
                helperMaxLines: 2,
                errorText: form.kcalError,
                border: const OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                ),
              ),
              onChanged: (_) => setState(() => form.kcalError = null),
            ),
          ),
      ],
    );
  }

  Widget _macroSection(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'goals-macro-mode',
          child: SegmentedButton<MacroGoalMode>(
            segments: [
              ButtonSegment(
                value: MacroGoalMode.percent,
                label: Text(s.goalsMacroPercent),
              ),
              ButtonSegment(
                value: MacroGoalMode.grams,
                label: Text(s.goalsMacroGrams),
              ),
            ],
            selected: {_form.macroMode},
            onSelectionChanged: (selection) =>
                _onMacroModeChanged(selection.first),
          ),
        ),
        const SizedBox(height: Dimens.spacing12),
        if (_form.macroMode == MacroGoalMode.percent)
          ..._percentRows(context)
        else
          ..._gramFields(context),
      ],
    );
  }

  List<Widget> _percentRows(BuildContext context) {
    final s = S.of(context);
    final base = _baseKcal(_form);
    String grams(double pct, double kcalPerGram) =>
        (base * pct / 100 / kcalPerGram).round().toString();
    final rows = [
      (s.carbsLabel, _split.carbs, MacroCalc.carbsKcalPerGram),
      (s.fatLabel, _split.fat, MacroCalc.fatKcalPerGram),
      (s.proteinLabel, _split.protein, MacroCalc.proteinKcalPerGram),
    ];
    return [
      for (final (label, pct, kcalPerGram) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text('${pct.round()} % ≈ ${grams(pct, kcalPerGram)} g'),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          identifier: 'goals-split-edit',
          child: TextButton.icon(
            icon: const Icon(Icons.pie_chart_rounded),
            label: Text(s.goalsSplitEdit),
            onPressed: _editSplit,
          ),
        ),
      ),
    ];
  }

  List<Widget> _gramFields(BuildContext context) {
    final s = S.of(context);
    final form = _form;
    final carbs = _parse(form.carbs.text);
    final fat = _parse(form.fat.text);
    final protein = _parse(form.protein.text);
    final complete = carbs != null && fat != null && protein != null;
    final split = complete
        ? MacroGoalResolver.percentOfGrams(
            carbsG: carbs,
            fatG: fat,
            proteinG: protein,
          )
        : null;
    final macroKcal = complete
        ? MacroGoalResolver.kcalOfGrams(
            carbsG: carbs,
            fatG: fat,
            proteinG: protein,
          )
        : null;
    final base = _baseKcal(form);
    final mismatch =
        macroKcal != null &&
        base > 0 &&
        (macroKcal - base).abs() > base * _kcalMismatchTolerance;
    final fields = [
      ('goals-carbs-g', s.carbsLabel, form.carbs, split?.carbs),
      ('goals-fat-g', s.fatLabel, form.fat, split?.fat),
      ('goals-protein-g', s.proteinLabel, form.protein, split?.protein),
    ];
    return [
      for (final (id, label, controller, share) in fields)
        Padding(
          padding: const EdgeInsets.only(bottom: Dimens.spacing12),
          child: Semantics(
            identifier: id,
            child: TextField(
              key: ValueKey('$id-$_editingTraining'),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: label,
                suffixText: 'g',
                helperText: share == null
                    ? null
                    : '≈ ${(share * 100).round()} %',
                border: const OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                ),
              ),
              onChanged: (_) => setState(() => form.gramsError = null),
            ),
          ),
        ),
      if (form.gramsError != null)
        Text(
          form.gramsError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (mismatch)
        Text(
          s.goalsGramsKcalHint(macroKcal.round(), base.round()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ];
  }
}
