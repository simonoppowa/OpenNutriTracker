import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #284: Dialog for setting the weekly weight change rate. The dialog
/// returns one of three [WeeklyWeightGoalResult] cases:
///
/// - [WeeklyWeightGoalCancelled] when the user dismisses or taps Cancel.
///   (This is also what the framework returns from a back-button pop,
///   so callers don't need to special-case `null`.)
/// - [WeeklyWeightGoalCleared] when the user taps Reset, asking to
///   fall back to the overall weight goal (lose / maintain / gain).
/// - [WeeklyWeightGoalSet] with a kg/week value when the user taps OK
///   on a slider position. Negative = lose, positive = gain, zero =
///   maintain.
///
/// The previous shape of this API returned a `double?` and overloaded
/// `double.nan` as a sentinel for "clear". The sealed type makes the
/// intent obvious in the caller's switch and removes a footgun where
/// any caller forgetting to check `isNaN` would silently set the user
/// to a NaN goal.
sealed class WeeklyWeightGoalResult {
  const WeeklyWeightGoalResult();
}

class WeeklyWeightGoalCancelled extends WeeklyWeightGoalResult {
  const WeeklyWeightGoalCancelled();
}

class WeeklyWeightGoalCleared extends WeeklyWeightGoalResult {
  const WeeklyWeightGoalCleared();
}

class WeeklyWeightGoalSet extends WeeklyWeightGoalResult {
  final double kgPerWeek;
  const WeeklyWeightGoalSet(this.kgPerWeek);
}

class SetWeeklyWeightGoalDialog extends StatefulWidget {
  final double? currentGoalKg;
  final BodyWeightUnit bodyWeightUnit;

  const SetWeeklyWeightGoalDialog({
    super.key,
    required this.currentGoalKg,
    required this.bodyWeightUnit,
  });

  @override
  State<SetWeeklyWeightGoalDialog> createState() =>
      _SetWeeklyWeightGoalDialogState();
}

class _SetWeeklyWeightGoalDialogState
    extends State<SetWeeklyWeightGoalDialog> {
  // Slider range in kg/week: -1.0 (lose 1 kg/wk) to +1.0 (gain 1 kg/wk)
  static const double _minKg = -1.0;
  static const double _maxKg = 1.0;
  static const int _divisions = 8; // steps of 0.25 kg

  late double _selectedKg;

  @override
  void initState() {
    super.initState();
    _selectedKg = widget.currentGoalKg ?? 0.0;
    _selectedKg = _selectedKg.clamp(_minKg, _maxKg);
  }

  double get _displayValue {
    switch (widget.bodyWeightUnit) {
      case BodyWeightUnit.kg:
        return _selectedKg;
      case BodyWeightUnit.lb:
        return _selectedKg * 2.20462;
      case BodyWeightUnit.st:
        // For rates, show as decimal stones (total lbs / 14) with 'st' label.
        return _selectedKg * 2.20462 / 14;
    }
  }

  String get _displayLabel {
    if (_selectedKg == 0.0) return S.of(context).goalMaintainWeight;
    final sign = _displayValue > 0 ? '+' : '';
    switch (widget.bodyWeightUnit) {
      case BodyWeightUnit.kg:
        final formatted = '$sign${_displayValue.toStringAsFixed(2)}';
        return S.of(context).weeklyWeightGoalKgPerWeek(formatted);
      case BodyWeightUnit.lb:
        final formatted = '$sign${_displayValue.toStringAsFixed(2)}';
        return S.of(context).weeklyWeightGoalLbsPerWeek(formatted);
      case BodyWeightUnit.st:
        final formatted = '$sign${_displayValue.toStringAsFixed(2)}';
        return '$formatted ${S.of(context).stLabel}${S.of(context).trendsPerWeekSuffix}';
    }
  }

  String get _minLabel {
    switch (widget.bodyWeightUnit) {
      case BodyWeightUnit.kg:
        return '-1.0 kg';
      case BodyWeightUnit.lb:
        return '-2.2 lbs';
      case BodyWeightUnit.st:
        return '-0.16 st';
    }
  }

  String get _maxLabel {
    switch (widget.bodyWeightUnit) {
      case BodyWeightUnit.kg:
        return '+1.0 kg';
      case BodyWeightUnit.lb:
        return '+2.2 lbs';
      case BodyWeightUnit.st:
        return '+0.16 st';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).chooseWeeklyWeightGoalLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _displayLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            min: _minKg,
            max: _maxKg,
            divisions: _divisions,
            value: _selectedKg,
            label: _displayLabel,
            onChanged: (value) => setState(() => _selectedKg = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _minLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _maxLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop<WeeklyWeightGoalResult>(const WeeklyWeightGoalCancelled()),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        // Always offer Reset — users need a way to fall back to the
        // overall weight goal (lose / maintain / gain) even if they
        // opened the slider once and never set an explicit weekly rate.
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop<WeeklyWeightGoalResult>(const WeeklyWeightGoalCleared()),
          child: Text(S.of(context).buttonResetLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop<WeeklyWeightGoalResult>(WeeklyWeightGoalSet(_selectedKg)),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
