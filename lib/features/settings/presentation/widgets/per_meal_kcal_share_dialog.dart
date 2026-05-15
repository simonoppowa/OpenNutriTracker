import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/meal_pattern_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #150: Split the daily kcal goal across breakfast / lunch / dinner /
/// snack. Moving any one slider rebalances the other three
/// proportionally so the four percentages always sum to 100. Preset
/// chips (#150 follow-up) drop in pre-authored splits for IF / OMAD /
/// five-small-meals routines without making the user dial them in.
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
  double _breakfastPct = 30;
  double _lunchPct = 40;
  double _dinnerPct = 20;
  double _snackPct = 10;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shares = await widget.settingsBloc.getMealKcalSharesPct();
    if (!mounted) return;
    setState(() {
      _breakfastPct = (shares[ConfigEntity.mealKeyBreakfast] ?? 30).toDouble();
      _lunchPct = (shares[ConfigEntity.mealKeyLunch] ?? 40).toDouble();
      _dinnerPct = (shares[ConfigEntity.mealKeyDinner] ?? 20).toDouble();
      _snackPct = (shares[ConfigEntity.mealKeySnack] ?? 10).toDouble();
      _loaded = true;
    });
  }

  /// Move one slider, rebalance the other three to fill the remainder.
  /// Integer rounding can leave a 1-2% drift after the redistribution;
  /// we absorb it into whichever "other" share was largest so the trio
  /// always sums exactly to 100 with the moved slider held fixed.
  void _rebalance({required String changed, required double newValue}) {
    final clamped = newValue.clamp(0, 100).toDouble();
    final shares = {
      ConfigEntity.mealKeyBreakfast: _breakfastPct,
      ConfigEntity.mealKeyLunch: _lunchPct,
      ConfigEntity.mealKeyDinner: _dinnerPct,
      ConfigEntity.mealKeySnack: _snackPct,
    };
    shares[changed] = clamped;
    final others = shares.keys.where((k) => k != changed).toList();
    final remaining = 100 - clamped;
    final othersTotal =
        others.fold<double>(0, (acc, k) => acc + shares[k]!);
    if (remaining <= 0) {
      for (final k in others) {
        shares[k] = 0;
      }
    } else if (othersTotal == 0) {
      final even = remaining / others.length;
      for (final k in others) {
        shares[k] = even;
      }
    } else {
      for (final k in others) {
        shares[k] = (shares[k]! / othersTotal) * remaining;
      }
    }
    final rounded = {for (final k in shares.keys) k: shares[k]!.round()};
    final drift = 100 - rounded.values.fold<int>(0, (a, b) => a + b);
    if (drift != 0) {
      final adjustTarget = others.reduce(
        (a, b) => rounded[a]! >= rounded[b]! ? a : b,
      );
      rounded[adjustTarget] = rounded[adjustTarget]! + drift;
    }
    setState(() {
      _breakfastPct = rounded[ConfigEntity.mealKeyBreakfast]!.toDouble();
      _lunchPct = rounded[ConfigEntity.mealKeyLunch]!.toDouble();
      _dinnerPct = rounded[ConfigEntity.mealKeyDinner]!.toDouble();
      _snackPct = rounded[ConfigEntity.mealKeySnack]!.toDouble();
    });
  }

  /// Presets are authored to sum to 100 already, so we drop them in
  /// without running them through the rebalance pass.
  void _applyPreset(MealPatternEntity pattern) {
    setState(() {
      _breakfastPct = pattern.breakfastPct.toDouble();
      _lunchPct = pattern.lunchPct.toDouble();
      _dinnerPct = pattern.dinnerPct.toDouble();
      _snackPct = pattern.snackPct.toDouble();
    });
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
    await widget.settingsBloc.setMealKcalSharesPct({
      ConfigEntity.mealKeyBreakfast: _breakfastPct.round(),
      ConfigEntity.mealKeyLunch: _lunchPct.round(),
      ConfigEntity.mealKeyDinner: _dinnerPct.round(),
      ConfigEntity.mealKeySnack: _snackPct.round(),
    });
    widget.settingsBloc.add(LoadSettingsEvent());
    widget.homeBloc.add(const LoadItemsEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _breakfastPct = (ConfigEntity
              .defaultMealKcalSharesPct[ConfigEntity.mealKeyBreakfast]!)
          .toDouble();
      _lunchPct = (ConfigEntity
              .defaultMealKcalSharesPct[ConfigEntity.mealKeyLunch]!)
          .toDouble();
      _dinnerPct = (ConfigEntity
              .defaultMealKcalSharesPct[ConfigEntity.mealKeyDinner]!)
          .toDouble();
      _snackPct = (ConfigEntity
              .defaultMealKcalSharesPct[ConfigEntity.mealKeySnack]!)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final totalPct = _breakfastPct.round() +
        _lunchPct.round() +
        _dinnerPct.round() +
        _snackPct.round();
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.settingsPerMealKcalShareLabel,
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.mealPatternPresetsLabel,
                    style: Theme.of(context).textTheme.bodySmall,
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
                  Text(
                    '$totalPct% total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _MealShareRow(
                    label: s.settingsPerMealKcalShareBreakfast,
                    value: _breakfastPct,
                    identifier: 'meal-share-breakfast',
                    onChanged: (v) => _rebalance(
                      changed: ConfigEntity.mealKeyBreakfast,
                      newValue: v,
                    ),
                  ),
                  _MealShareRow(
                    label: s.settingsPerMealKcalShareLunch,
                    value: _lunchPct,
                    identifier: 'meal-share-lunch',
                    onChanged: (v) => _rebalance(
                      changed: ConfigEntity.mealKeyLunch,
                      newValue: v,
                    ),
                  ),
                  _MealShareRow(
                    label: s.settingsPerMealKcalShareDinner,
                    value: _dinnerPct,
                    identifier: 'meal-share-dinner',
                    onChanged: (v) => _rebalance(
                      changed: ConfigEntity.mealKeyDinner,
                      newValue: v,
                    ),
                  ),
                  _MealShareRow(
                    label: s.settingsPerMealKcalShareSnack,
                    value: _snackPct,
                    identifier: 'meal-share-snack',
                    onChanged: (v) => _rebalance(
                      changed: ConfigEntity.mealKeySnack,
                      newValue: v,
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
            onPressed: _loaded ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}

class _MealShareRow extends StatelessWidget {
  final String label;
  final double value;
  final String identifier;
  final ValueChanged<double> onChanged;

  const _MealShareRow({
    required this.label,
    required this.value,
    required this.identifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${value.round()}%'),
          ],
        ),
        Semantics(
          identifier: identifier,
          child: Slider(
            min: 0,
            max: 100,
            value: value.clamp(0, 100),
            divisions: 100,
            label: '${value.round()}%',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
