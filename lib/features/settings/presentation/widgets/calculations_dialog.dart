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
  double selectedKcalAdjustment = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeKcalAdjustment();
  }

  void _initializeKcalAdjustment() async {
    final adjustment = await widget.settingsBloc.getKcalAdjustment() *
        1.0; // Convert to double
    setState(() {
      selectedKcalAdjustment = adjustment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(S.of(context).settingsCalculationsLabel),
          TextButton(
            child: Text(S.of(context).buttonResetLabel),
            onPressed: () {
              setState(() {
                selectedKcalAdjustment = 0;
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
          DropdownButtonFormField(
              isExpanded: true,
              decoration: InputDecoration(
                  enabled: false,
                  filled: false,
                  labelText: S
                      .of(context)
                      .calculationsMacronutrientsDistributionLabel),
              items: [
                DropdownMenuItem(
                    child: Text(
                  S
                      .of(context)
                      .calculationsMacrosDistribution("60", "25", "15"),
                  overflow: TextOverflow.ellipsis,
                ))
              ],
              onChanged: null),
          const SizedBox(height: 64),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '${S.of(context).dailyKcalAdjustmentLabel} ${!selectedKcalAdjustment.isNegative ? "+" : ""}${selectedKcalAdjustment.round()} ${S.of(context).kcalLabel}',
              style: Theme.of(context).textTheme.bodyMedium,
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
                value: selectedKcalAdjustment,
                label:
                    '${selectedKcalAdjustment.round()} ${S.of(context).kcalLabel}',
                onChanged: (value) {
                  setState(() {
                    selectedKcalAdjustment = value;
                  });
                },
              ),
            ),
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

  void _saveCalculationSettings() {
    // Save the calorie offset as full number
    widget.settingsBloc
        .setKcalAdjustment(selectedKcalAdjustment.toInt().toDouble());
    widget.settingsBloc.add(LoadSettingsEvent());
    // Update other blocs that need the new calorie value
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());

    // Update tracked day entity
    widget.settingsBloc.updateTrackedDay(DateTime.now());
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(LoadCalendarDayEvent(DateTime.now()));

    Navigator.of(context).pop();
  }
}
