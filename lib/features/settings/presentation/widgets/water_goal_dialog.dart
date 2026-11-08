import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/reload_diary_and_trends.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #32: focused entry for the daily water goal. Follows the same single-
/// purpose-dialog pattern as the other Calculations entries split out in
/// the #414 refactor — one number to change, a clear reset back to the
/// default, save closes the dialog and reloads the home chip so the new
/// goal shows up without restarting the app.
class WaterGoalDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final HomeBloc homeBloc;
  // #1306: shown and entered in fl oz with imperial food units; the goal is
  // always stored in ml.
  final bool usesImperialUnits;

  const WaterGoalDialog({
    super.key,
    required this.settingsBloc,
    required this.homeBloc,
    this.usesImperialUnits = false,
  });

  @override
  State<WaterGoalDialog> createState() => _WaterGoalDialogState();
}

class _WaterGoalDialogState extends State<WaterGoalDialog> {
  static const int _minGoalMl = 100;
  static const int _maxGoalMl = 10000;
  static const int _stepMl = 100;
  static const int _minGoalFlOz = 4;
  static const int _maxGoalFlOz = 336;
  static const int _stepFlOz = 4;

  bool get _imperial => widget.usesImperialUnits;
  int get _minDisplay => _imperial ? _minGoalFlOz : _minGoalMl;
  int get _maxDisplay => _imperial ? _maxGoalFlOz : _maxGoalMl;
  int get _stepDisplay => _imperial ? _stepFlOz : _stepMl;

  int _toDisplay(int ml) =>
      _imperial ? UnitCalc.mlToFlOz(ml.toDouble()).round() : ml;

  int _toMl(int display) => _imperial
      ? UnitCalc.flOzToMl(
          display.toDouble(),
        ).round().clamp(_minGoalMl, _maxGoalMl)
      : display;

  bool _loaded = false;
  int _goalMl = ConfigEntity.defaultDailyWaterGoalMl;
  int _seedGoalMl = ConfigEntity.defaultDailyWaterGoalMl;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stored = await widget.settingsBloc.getDailyWaterGoalMl();
    final user = await locator<GetUserUsecase>().getUserData();
    final seed = ConfigEntity.seedWaterGoalForGender(
      user.gender,
      caloriesProfile: user.caloriesProfile,
    );
    if (!mounted) return;
    final initial = stored ?? seed;
    setState(() {
      _goalMl = initial;
      _seedGoalMl = seed;
      _controller.text = _toDisplay(initial).toString();
      _loaded = true;
    });
  }

  void _applyTextInput() {
    final parsed = int.tryParse(_controller.text);
    if (parsed == null) {
      _controller.text = _toDisplay(_goalMl).toString();
      return;
    }
    // An untouched imperial field must not round-trip the stored ml value.
    // Checked before clamping: the ml range reaches past the fl oz one, so
    // 10000 ml shows as 338 fl oz and clamping it first saved 9937 ml.
    if (parsed == _toDisplay(_goalMl)) {
      // Same value typed differently ("051"): show it canonically.
      _controller.text = parsed.toString();
      return;
    }
    final clamped = parsed.clamp(_minDisplay, _maxDisplay);
    if (clamped != _toDisplay(_goalMl)) {
      setState(() => _goalMl = _toMl(clamped));
    }
    _controller.text = clamped.toString();
  }

  Future<void> _save() async {
    // Apply any value still sitting in the text field, so typing a
    // number and tapping OK works without pressing Done first.
    // Same fix as the macro split dialog (#525).
    _applyTextInput();
    await widget.settingsBloc.setDailyWaterGoalMl(_goalMl);
    widget.homeBloc.add(const LoadItemsEvent());
    locator<ProfileBloc>().add(LoadProfileEvent());
    reloadDiaryAndTrends();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.settingsWaterGoalLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: 'water-goal-reset',
            container: true,
            child: TextButton(
              onPressed: _loaded
                  ? () {
                      setState(() => _goalMl = _seedGoalMl);
                      _controller.text = _toDisplay(_goalMl).toString();
                    }
                  : null,
              child: Text(s.buttonResetLabel),
            ),
          ),
        ],
      ),
      content: !_loaded
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.settingsWaterGoalDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Semantics(
                  identifier: 'water-goal-input',
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      suffixText: _imperial ? s.flOzUnit : s.mlLabel,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyTextInput(),
                    onEditingComplete: _applyTextInput,
                  ),
                ),
                Semantics(
                  identifier: 'water-goal-slider',
                  child: Slider(
                    min: _minDisplay.toDouble(),
                    max: _maxDisplay.toDouble(),
                    divisions: (_maxDisplay - _minDisplay) ~/ _stepDisplay,
                    value: _toDisplay(_goalMl).toDouble().clamp(
                      _minDisplay.toDouble(),
                      _maxDisplay.toDouble(),
                    ),
                    label:
                        '${_toDisplay(_goalMl)} ${_imperial ? s.flOzUnit : s.mlLabel}',
                    onChanged: (value) {
                      setState(() => _goalMl = _toMl(value.round()));
                      _controller.text = value.round().toString();
                    },
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'water-goal-save',
          child: TextButton(
            onPressed: _loaded ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}
