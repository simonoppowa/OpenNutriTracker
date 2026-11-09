import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_picker_bounds.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/body_weight_input.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Outcome of [SetTargetWeightDialog]. The dialog has three exits:
///
///   * Cancel — returns `null` from `showDialog`.
///   * OK with a value — returns a [TargetWeightDialogResult] with [value]
///     set (in kg) and [clear] false. Caller persists the new target.
///   * Clear (only offered when a target is already set) — returns a result
///     with [clear] true and [value] null. Caller writes `null` back to the
///     user record.
///
/// Keeping clear separate from "OK with value" means a user who never wanted
/// a target in the first place isn't forced to commit to an arbitrary number
/// just to back out of the dialog.
class TargetWeightDialogResult {
  /// Weight in kilograms, or null when [clear] is true.
  final double? value;
  final bool clear;

  const TargetWeightDialogResult.value(this.value) : clear = false;
  const TargetWeightDialogResult.cleared()
      : value = null,
        clear = true;
}

class SetTargetWeightDialog extends StatefulWidget {
  /// Initial weight to centre the picker on, in kilograms. When the user has
  /// no existing target the caller typically seeds this from current weight.
  final double initialKg;

  /// Whether the user already has a target set. Controls whether the
  /// "Clear target" action is offered alongside the OK / Cancel buttons.
  final bool hasExistingTarget;

  final BodyWeightUnit unit;
  final ConfigRepository? configRepository;

  const SetTargetWeightDialog({
    super.key,
    required this.initialKg,
    required this.hasExistingTarget,
    required this.unit,
    this.configRepository,
  });

  @override
  State<SetTargetWeightDialog> createState() => _SetTargetWeightDialogState();
}

class _SetTargetWeightDialogState extends State<SetTargetWeightDialog> {
  late final ConfigRepository? _configRepository =
      widget.configRepository ??
      (locator.isRegistered<ConfigRepository>()
          ? locator<ConfigRepository>()
          : null);

  // Picker display value for kg / lb paths.
  late double _pickerDisplayWeight;
  late double _pickerAnchorWeight;
  final GlobalKey _pickerKey = GlobalKey();

  // Text input path: kg from BodyWeightInput, null if invalid/empty.
  double? _textKg;

  bool _useTextInput = false;

  bool get _isTextMode => widget.unit == BodyWeightUnit.st || _useTextInput;

  @override
  void initState() {
    super.initState();
    _pickerDisplayWeight = _toDisplay(widget.initialKg);
    _pickerAnchorWeight = _pickerDisplayWeight;
    _textKg = ValueValidator.parseWeightInKg(
      _pickerDisplayWeight,
      isImperial: widget.unit == BodyWeightUnit.lb,
    );
    _loadInputPreference();
    _syncLowWeightPickerIfNeeded();
  }

  Future<void> _loadInputPreference() async {
    final useText =
        await _configRepository?.getUseTextForWeightInput() ?? false;
    if (!mounted) return;
    setState(() {
      _useTextInput = useText;
    });
  }

  Future<void> _toggleInputMode(bool useText) async {
    if (_useTextInput == useText) return;
    setState(() {
      _useTextInput = useText;
      if (useText) {
        _textKg = ValueValidator.parseWeightInKg(
          _pickerDisplayWeight,
          isImperial: widget.unit == BodyWeightUnit.lb,
        );
      } else if (_textKg != null) {
        _pickerDisplayWeight = (_toDisplay(_textKg!) * 10).round() / 10;
        _pickerAnchorWeight = _pickerDisplayWeight;
      } else {
        _pickerAnchorWeight = _pickerDisplayWeight;
      }
    });
    if (!useText) {
      _syncLowWeightPickerIfNeeded();
    }
    await _configRepository?.setUseTextForWeightInput(useText);
  }

  void _syncLowWeightPickerIfNeeded() {
    if (_isTextMode) return;
    final isImperial = widget.unit == BodyWeightUnit.lb;
    final minWeight = minSelectableWeight(_pickerAnchorWeight, isImperial);
    final maxWeight = maxSelectableWeight(_pickerAnchorWeight, isImperial);
    if ((_pickerAnchorWeight - (minWeight + maxWeight) / 2).abs() < 0.05) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _pickerKey.currentContext;
      if (ctx == null || !mounted) return;
      final divisions = ((maxWeight - minWeight) * 10).round();
      if (divisions <= 0) return;
      final targetIndex =
          (((_pickerAnchorWeight - minWeight) / (maxWeight - minWeight)) *
                  divisions)
              .round()
              .clamp(0, divisions);
      FixedExtentScrollController? controller;
      void visit(Element el) {
        if (el.widget is ListWheelScrollView) {
          final wheel = el.widget as ListWheelScrollView;
          if (wheel.controller is FixedExtentScrollController) {
            controller = wheel.controller as FixedExtentScrollController;
            return;
          }
        }
        el.visitChildren(visit);
      }

      ctx.visitChildElements(visit);
      if (controller != null && controller!.hasClients) {
        controller!.jumpToItem(targetIndex);
      }
    });
  }

  double _toDisplay(double kg) {
    switch (widget.unit) {
      case BodyWeightUnit.kg:
        return kg;
      case BodyWeightUnit.lb:
        return UnitCalc.kgToLbs(kg);
      case BodyWeightUnit.st:
        return 0; // placeholder — st uses BodyWeightInput
    }
  }

  double _pickerWeightToKg(double display) {
    switch (widget.unit) {
      case BodyWeightUnit.kg:
        return display;
      case BodyWeightUnit.lb:
        return UnitCalc.lbsToKg(display);
      case BodyWeightUnit.st:
        return display; // unreachable
    }
  }

  void _submitValue() {
    final double kg;
    if (_isTextMode) {
      // OK is disabled while the typed value is empty or out of range.
      final valid = _textKg;
      if (valid == null) return;
      kg = valid;
    } else {
      final isImperial = widget.unit == BodyWeightUnit.lb;
      final display = clampWeightSelection(
        _pickerDisplayWeight,
        minSelectableWeight(_pickerDisplayWeight, isImperial),
      );
      kg = _pickerWeightToKg(display);
    }
    Navigator.of(context).pop(TargetWeightDialogResult.value(kg));
  }

  @override
  Widget build(BuildContext context) {
    final isImperial = widget.unit == BodyWeightUnit.lb;
    final minWeight = minSelectableWeight(_pickerAnchorWeight, isImperial);
    final maxWeight = maxSelectableWeight(_pickerAnchorWeight, isImperial);
    final isLowWeight =
        (_pickerAnchorWeight - (minWeight + maxWeight) / 2).abs() >= 0.05;
    final divisions = isLowWeight
        ? ((maxWeight - minWeight) * 10).round()
        : 1000;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              S.of(context).profileTargetWeightLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.unit != BodyWeightUnit.st) ...[
            const SizedBox(width: 12),
            Semantics(
              identifier: 'target-weight-dialog-mode-toggle',
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    tooltip: S.of(context).weightInputPickerTooltip,
                    icon: const Icon(Icons.linear_scale, size: 18),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    tooltip: S.of(context).weightInputKeyboardTooltip,
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                  ),
                ],
                selected: {_useTextInput},
                onSelectionChanged: (selection) =>
                    _toggleInputMode(selection.first),
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isTextMode)
              BodyWeightInput(
                initialKg: _textKg ?? _pickerWeightToKg(_pickerDisplayWeight),
                unit: widget.unit,
                identifierPrefix: 'set-target-weight-dialog',
                autofocus: true,
                onChangedKg: (kg) => setState(() => _textKg = kg),
              )
            else
              KeyedSubtree(
                key: _pickerKey,
                child: HorizontalPicker(
                  height: 100,
                  backgroundColor: Colors.transparent,
                  minValue: minWeight,
                  maxValue: maxWeight,
                  initialPosition: InitialPosition.center,
                  divisions: divisions,
                  suffix: isImperial
                      ? S.of(context).lbsLabel
                      : S.of(context).kgLabel,
                  onChanged: (value) {
                    setState(() {
                      _pickerDisplayWeight = value;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        if (widget.hasExistingTarget)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const TargetWeightDialogResult.cleared(),
            ),
            child: Text(S.of(context).profileTargetWeightClearAction),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          // Disabled rather than closing with nothing saved, which would
          // silently drop a typo such as an extra digit.
          onPressed: _isTextMode && _textKg == null ? null : _submitValue,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
