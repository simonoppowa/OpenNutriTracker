import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/meal_pattern_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #150: Split the daily kcal goal across breakfast / lunch / dinner /
/// snack. Each meal has a slider and a typed whole-percent field kept in
/// sync. Editing one share never touches the others (#715): the dialog
/// shows the running total and keeps OK disabled until it is exactly
/// 100 %. Preset chips (#150 follow-up) drop in pre-authored splits for
/// IF / OMAD / five-small-meals routines without making the user dial
/// them in.
class PerMealKcalShareDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final HomeBloc homeBloc;
  final CalendarDayBloc calendarDayBloc;

  const PerMealKcalShareDialog({
    super.key,
    required this.settingsBloc,
    required this.homeBloc,
    required this.calendarDayBloc,
  });

  @override
  State<PerMealKcalShareDialog> createState() =>
      _PerMealKcalShareDialogState();
}

class _PerMealKcalShareDialogState extends State<PerMealKcalShareDialog> {
  static const _meals = [
    ConfigEntity.mealKeyBreakfast,
    ConfigEntity.mealKeyLunch,
    ConfigEntity.mealKeyDinner,
    ConfigEntity.mealKeySnack,
  ];

  static final _wholePercent = RegExp(r'^\d{1,3}$');

  /// The last valid share per meal; the sliders show these.
  final Map<String, int> _shares = Map.of(
    ConfigEntity.defaultMealKcalSharesPct,
  );

  /// Meals whose field holds something other than a whole 0-100.
  final Set<String> _invalid = {};

  final Map<String, TextEditingController> _controllers = {
    for (final meal in _meals) meal: TextEditingController(),
  };

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final stored = await widget.settingsBloc.getMealKcalSharesPct();
    if (!mounted) return;
    setState(() {
      _setAll({
        for (final meal in _meals)
          meal: stored[meal] ?? ConfigEntity.defaultMealKcalSharesPct[meal]!,
      });
      _loaded = true;
    });
  }

  /// Puts [shares] into every slider and field. A stored value outside
  /// 0-100 is shown as stored and flagged, not silently clamped.
  void _setAll(Map<String, int> shares) {
    _invalid.clear();
    for (final meal in _meals) {
      final value = shares[meal]!;
      _shares[meal] = value.clamp(0, 100);
      _setText(meal, '$value');
      if (value < 0 || value > 100) _invalid.add(meal);
    }
  }

  void _setText(String meal, String text) {
    _controllers[meal]!.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  int? _parse(String text) {
    final trimmed = text.trim();
    if (!_wholePercent.hasMatch(trimmed)) return null;
    final value = int.parse(trimmed);
    return value <= 100 ? value : null;
  }

  void _onSliderChanged(String meal, double value) {
    final rounded = value.round();
    setState(() {
      _shares[meal] = rounded;
      _invalid.remove(meal);
      _setText(meal, '$rounded');
    });
  }

  void _onTextChanged(String meal, String text) {
    final value = _parse(text);
    setState(() {
      if (value == null) {
        _invalid.add(meal);
      } else {
        _invalid.remove(meal);
        _shares[meal] = value;
      }
    });
  }

  int get _total => _shares.values.fold<int>(0, (a, b) => a + b);

  bool get _canSave => _loaded && _invalid.isEmpty && _total == 100;

  /// Presets are authored to sum to 100 already.
  void _applyPreset(MealPatternEntity pattern) {
    setState(() => _setAll(pattern.toSharesMap()));
  }

  String _presetLabel(BuildContext context, MealPatternEntity pattern) {
    final s = S.of(context);
    switch (pattern) {
      case MealPatternEntity.standard:
        return s.mealPatternStandard;
      case MealPatternEntity.mediterranean:
        return s.mealPatternMediterranean;
      case MealPatternEntity.twoMeal:
        return s.mealPatternTwoMeal;
      case MealPatternEntity.omad:
        return s.mealPatternOmad;
      case MealPatternEntity.fiveSmall:
        return s.mealPatternFiveSmall;
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    await widget.settingsBloc.setMealKcalSharesPct(Map.of(_shares));
    widget.settingsBloc.add(LoadSettingsEvent());
    widget.homeBloc.add(const LoadItemsEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() => _setAll(ConfigEntity.defaultMealKcalSharesPct));
  }

  String _mealLabel(S s, String meal) {
    switch (meal) {
      case ConfigEntity.mealKeyBreakfast:
        return s.settingsPerMealKcalShareBreakfast;
      case ConfigEntity.mealKeyLunch:
        return s.settingsPerMealKcalShareLunch;
      case ConfigEntity.mealKeyDinner:
        return s.settingsPerMealKcalShareDinner;
      default:
        return s.settingsPerMealKcalShareSnack;
    }
  }

  /// What still stands between the user and OK, or null when nothing does.
  String? _blocker(S s) {
    if (_invalid.isNotEmpty) return s.mealShareInvalidValueLabel;
    final total = _total;
    if (total > 100) return s.mealShareOverLabel(total - 100);
    if (total < 100) return s.mealShareRemainingLabel(100 - total);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final blocker = _loaded ? _blocker(s) : null;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.settingsPerMealKcalShareLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _loaded ? _reset : null,
            child: Text(s.buttonResetLabel),
          ),
        ],
      ),
      content: !_loaded
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.settingsPerMealKcalShareDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.mealPatternPresetsLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final pattern in MealPatternEntity.values)
                        Semantics(
                          identifier: 'meal-share-preset-${pattern.id}',
                          child: OutlinedButton(
                            onPressed: () => _applyPreset(pattern),
                            child: Text(_presetLabel(context, pattern)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final meal in _meals)
                    _MealShareRow(
                      label: _mealLabel(s, meal),
                      value: _shares[meal]!,
                      invalid: _invalid.contains(meal),
                      controller: _controllers[meal]!,
                      identifier: 'meal-share-$meal',
                      onSliderChanged: (v) => _onSliderChanged(meal, v),
                      onTextChanged: (t) => _onTextChanged(meal, t),
                    ),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_invalid.isEmpty)
                          Text(
                            s.mealShareTotalLabel(_total),
                            style: theme.textTheme.titleSmall,
                          ),
                        if (blocker != null)
                          Text(
                            blocker,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'meal-share-save',
          child: TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}

class _MealShareRow extends StatelessWidget {
  final String label;
  final int value;
  final bool invalid;
  final TextEditingController controller;
  final String identifier;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<String> onTextChanged;

  const _MealShareRow({
    required this.label,
    required this.value,
    required this.invalid,
    required this.controller,
    required this.identifier,
    required this.onSliderChanged,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            SizedBox(
              // Scale with the text setting so the value and its % suffix
              // stay readable at large font scales.
              width: MediaQuery.textScalerOf(context).scale(96),
              child: Semantics(
                identifier: '$identifier-input',
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  // Let a typed decimal through so it is flagged, instead of
                  // "23,5" quietly turning into 235.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    suffixText: '%',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    // Red outline only; the message sits under the total.
                    error: invalid ? const SizedBox.shrink() : null,
                  ),
                  onChanged: onTextChanged,
                ),
              ),
            ),
          ],
        ),
        Semantics(
          identifier: identifier,
          child: Slider(
            min: 0,
            max: 100,
            value: value.clamp(0, 100).toDouble(),
            divisions: 100,
            label: '$value%',
            // Read as the share it sets, not the slider's position.
            semanticFormatterCallback: (v) => '${v.round()}%',
            onChanged: onSliderChanged,
          ),
        ),
      ],
    );
  }
}
