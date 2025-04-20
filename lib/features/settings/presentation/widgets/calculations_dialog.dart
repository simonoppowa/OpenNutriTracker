import 'package:flutter/material.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CalculationsDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final HomeBloc homeBloc;
  final DiaryBloc diaryBloc;
  final CalendarDayBloc calendarDayBloc;

  const CalculationsDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.homeBloc,
    required this.diaryBloc,
    required this.calendarDayBloc,
  });

  @override
  State<CalculationsDialog> createState() => _CalculationsDialogState();
}

class _CalculationsDialogState extends State<CalculationsDialog> {
  static const double _maxKcalAdjustment = 1000;
  static const double _minKcalAdjustment = -1000;
  static const int _kcalDivisions = 200;
  double _kcalAdjustmentSelection = 0;

  static const double _defaultCarbsPctSelection = 0.6;
  static const double _defaultFatPctSelection = 0.25;
  static const double _defaultProteinPctSelection = 0.15;

  // Macros percentages
  double _carbsPctSelection = _defaultCarbsPctSelection * 100;
  double _proteinPctSelection = _defaultProteinPctSelection * 100;
  double _fatPctSelection = _defaultFatPctSelection * 100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeKcalAdjustment();
  }

  void _initializeKcalAdjustment() async {
    final kcalAdjustment = await widget.settingsBloc.getKcalAdjustment() *
        1.0; // Convert to double
    final userCarbsPct = await widget.settingsBloc.getUserCarbGoalPct();
    final userProteinPct = await widget.settingsBloc.getUserProteinGoalPct();
    final userFatPct = await widget.settingsBloc.getUserFatGoalPct();

    setState(() {
      _kcalAdjustmentSelection = kcalAdjustment;
      _carbsPctSelection = (userCarbsPct ?? _defaultCarbsPctSelection) * 100;
      _proteinPctSelection =
          (userProteinPct ?? _defaultProteinPctSelection) * 100;
      _fatPctSelection = (userFatPct ?? _defaultFatPctSelection) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              S.of(context).settingsCalculationsLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8), // Add spacing between text and button
          TextButton(
            child: Text(S.of(context).buttonResetLabel),
            onPressed: () {
              setState(() {
                _kcalAdjustmentSelection = 0;
                // Reset macros to default values
                _carbsPctSelection = _defaultCarbsPctSelection * 100;
                _proteinPctSelection = _defaultProteinPctSelection * 100;
                _fatPctSelection = _defaultFatPctSelection * 100;
              });
            },
          ),
        ],
      ),
      content: Wrap(
        children: [
          DropdownButtonFormField(
              isExpanded: true,
              decoration: InputDecoration(
                enabled: false,
                filled: false,
                labelText: S.of(context).calculationsTDEELabel,
              ),
              items: [
                DropdownMenuItem(
                    child: Text(
                  '${S.of(context).calculationsTDEEIOM2006Label} ${S.of(context).calculationsRecommendedLabel}',
                  overflow: TextOverflow.ellipsis,
                )),
              ],
              onChanged: null),
          const SizedBox(height: 64),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '${S.of(context).dailyKcalAdjustmentLabel} ${!_kcalAdjustmentSelection.isNegative ? "+" : ""}${_kcalAdjustmentSelection.round()} ${S.of(context).kcalLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 280,
              child: Slider(
                min: _minKcalAdjustment,
                max: _maxKcalAdjustment,
                divisions: _kcalDivisions,
                value: _kcalAdjustmentSelection,
                label:
                    '${_kcalAdjustmentSelection.round()} ${S.of(context).kcalLabel}',
                onChanged: (value) {
                  setState(() {
                    _kcalAdjustmentSelection = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            S.of(context).macroDistributionLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          _buildMacroSlider(
            S.of(context).carbsLabel,
            _carbsPctSelection,
            Colors.orange,
            (value) {
              setState(() {
                double delta = value - _carbsPctSelection;
                _carbsPctSelection = value;

                // Adjust other percentages proportionally
                double proteinRatio = _proteinPctSelection /
                    (_proteinPctSelection + _fatPctSelection);
                double fatRatio = _fatPctSelection /
                    (_proteinPctSelection + _fatPctSelection);

                _proteinPctSelection -= delta * proteinRatio;
                _fatPctSelection -= delta * fatRatio;

                // Ensure no value goes below 5%
                if (_proteinPctSelection < 5) {
                  double overflow = 5 - _proteinPctSelection;
                  _proteinPctSelection = 5;
                  _fatPctSelection -= overflow;
                }
                if (_fatPctSelection < 5) {
                  double overflow = 5 - _fatPctSelection;
                  _fatPctSelection = 5;
                  _proteinPctSelection -= overflow;
                }
              });
            },
          ),
          _buildMacroSlider(
            S.of(context).proteinLabel,
            _proteinPctSelection,
            Colors.blue,
            (value) {
              setState(() {
                double delta = value - _proteinPctSelection;
                _proteinPctSelection = value;

                double carbsRatio = _carbsPctSelection /
                    (_carbsPctSelection + _fatPctSelection);
                double fatRatio =
                    _fatPctSelection / (_carbsPctSelection + _fatPctSelection);

                _carbsPctSelection -= delta * carbsRatio;
                _fatPctSelection -= delta * fatRatio;

                if (_carbsPctSelection < 5) {
                  double overflow = 5 - _carbsPctSelection;
                  _carbsPctSelection = 5;
                  _fatPctSelection -= overflow;
                }
                if (_fatPctSelection < 5) {
                  double overflow = 5 - _fatPctSelection;
                  _fatPctSelection = 5;
                  _carbsPctSelection -= overflow;
                }
              });
            },
          ),
          _buildMacroSlider(
            S.of(context).fatLabel,
            _fatPctSelection,
            Colors.green,
            (value) {
              setState(() {
                double delta = value - _fatPctSelection;
                _fatPctSelection = value;

                double carbsRatio = _carbsPctSelection /
                    (_carbsPctSelection + _proteinPctSelection);
                double proteinRatio = _proteinPctSelection /
                    (_carbsPctSelection + _proteinPctSelection);

                _carbsPctSelection -= delta * carbsRatio;
                _proteinPctSelection -= delta * proteinRatio;

                if (_carbsPctSelection < 5) {
                  double overflow = 5 - _carbsPctSelection;
                  _carbsPctSelection = 5;
                  _proteinPctSelection -= overflow;
                }
                if (_proteinPctSelection < 5) {
                  double overflow = 5 - _proteinPctSelection;
                  _proteinPctSelection = 5;
                  _carbsPctSelection -= overflow;
                }
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              _saveCalculationSettings();
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }

  Widget _buildMacroSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.round()}%'),
          ],
        ),
        SizedBox(
          width: 280,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              min: 5,
              max: 90,
              value: value,
              divisions: 85,
              onChanged: (value) {
                final newValue = value.round().toDouble();
                if (100 - newValue >= 10) {
                  onChanged(newValue);
                  _normalizeMacros();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _normalizeMacros() {
    setState(() {
      // First, ensure all values are rounded
      _carbsPctSelection = _carbsPctSelection.roundToDouble();
      _proteinPctSelection = _proteinPctSelection.roundToDouble();
      _fatPctSelection = _fatPctSelection.roundToDouble();

      // Calculate total
      double total =
          _carbsPctSelection + _proteinPctSelection + _fatPctSelection;

      // If total isn't 100, adjust values proportionally
      if (total != 100) {
        // Calculate adjustment factor
        double factor = 100 / total;

        // Adjust the first two values
        _carbsPctSelection = (_carbsPctSelection * factor).roundToDouble();
        _proteinPctSelection = (_proteinPctSelection * factor).roundToDouble();

        // Set the last value to make total exactly 100
        _fatPctSelection = 100 - _carbsPctSelection - _proteinPctSelection;

        // Ensure minimum values (5%)
        if (_fatPctSelection < 5) {
          _fatPctSelection = 5;
          // Distribute remaining 95% proportionally between carbs and protein
          double remaining = 95;
          double ratio =
              _carbsPctSelection / (_carbsPctSelection + _proteinPctSelection);
          _carbsPctSelection = (remaining * ratio).roundToDouble();
          _proteinPctSelection = remaining - _carbsPctSelection;
        }
      }

      // Verify final values
      assert(
          _carbsPctSelection + _proteinPctSelection + _fatPctSelection == 100,
          'Macros must total 100%');
    });
  }

  void _saveCalculationSettings() {
    // Save the calorie offset as full number
    widget.settingsBloc
        .setKcalAdjustment(_kcalAdjustmentSelection.toInt().toDouble());
    widget.settingsBloc.setMacroGoals(
        _carbsPctSelection, _proteinPctSelection, _fatPctSelection);

    widget.settingsBloc.add(LoadSettingsEvent());
    // Update other blocs that need the new calorie value
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());

    // Update tracked day entity
    widget.settingsBloc.updateTrackedDay(DateTime.now());
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());

    Navigator.of(context).pop();
  }
}
