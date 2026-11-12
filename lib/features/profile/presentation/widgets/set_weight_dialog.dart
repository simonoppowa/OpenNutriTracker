import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_picker_bounds.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/body_weight_input.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetWeightDialog extends StatefulWidget {
  /// The user's current weight in kilograms. All display and input are handled
  /// internally per [unit]; callers always work in kg.
  final double initialKg;
  final BodyWeightUnit unit;

  /// When true, the dialog shows a date selector so a reading can be logged
  /// against a past day (backfilling history from the Trends view), and it
  /// pops `(weight: ..., date: ...)` where weight is kg. When false — the
  /// default, used by the home chip — it logs against today and pops just the
  /// kg double, so existing callers are unaffected.
  final bool allowDateSelection;

  const SetWeightDialog({
    super.key,
    required this.initialKg,
    required this.unit,
    this.allowDateSelection = false,
  });

  @override
  State<SetWeightDialog> createState() => _SetWeightDialogState();
}

class _SetWeightDialogState extends State<SetWeightDialog> {
  // Picker-based selection in display units (kg or lb). Null when using the
  // BodyWeightInput path for stones, which owns the kg directly.
  late double _pickerDisplayWeight;

  // Typed path: kg reported by BodyWeightInput, null if invalid/empty. Always
  // used for stones; for kg / lb only when [_typedLast] is set.
  double? _stKg;

  // For kg / lb the ruler takes a drag that screen-reader users cannot make,
  // so a typed field sits under it. The field follows the ruler; whichever
  // was moved last is the value saved.
  bool _typedLast = false;

  // Date-only (midnight) so it never sits after the date-only lastDate bound.
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _pickerDisplayWeight = _toDisplay(widget.initialKg);
    _stKg = widget.initialKg;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  double _toDisplay(double kg) {
    switch (widget.unit) {
      case BodyWeightUnit.kg:
        return kg;
      case BodyWeightUnit.lb:
        return UnitCalc.kgToLbs(kg);
      case BodyWeightUnit.st:
        // Picker not used for st; return 0 as a placeholder.
        return 0;
    }
  }

  double _pickerWeightToKg(double display) {
    switch (widget.unit) {
      case BodyWeightUnit.kg:
        return display;
      case BodyWeightUnit.lb:
        return UnitCalc.lbsToKg(display);
      case BodyWeightUnit.st:
        return display; // unreachable — st uses BodyWeightInput
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    final double kg;
    if (widget.unit == BodyWeightUnit.st || _typedLast) {
      final valid = _stKg;
      if (valid == null) {
        Navigator.of(context).pop();
        return;
      }
      kg = valid;
    } else {
      final display = clampWeightSelection(
        _pickerDisplayWeight,
        minSelectableWeight(_pickerDisplayWeight, widget.unit == BodyWeightUnit.lb),
      );
      kg = _pickerWeightToKg(display);
    }

    if (widget.allowDateSelection) {
      Navigator.pop(context, (weight: kg, date: _selectedDate));
    } else {
      Navigator.pop(context, kg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImperial = widget.unit == BodyWeightUnit.lb;
    final minWeight = minSelectableWeight(_pickerDisplayWeight, isImperial);
    final maxWeight = maxSelectableWeight(_pickerDisplayWeight, isImperial);

    final invalid =
        (widget.unit == BodyWeightUnit.st || _typedLast) && _stKg == null;
    final error = invalid ? S.of(context).onboardingWrongWeightLabel : null;

    return AlertDialog(
      title: Text(S.of(context).selectWeightDialogLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              if (widget.unit == BodyWeightUnit.st)
                BodyWeightInput(
                  initialKg: widget.initialKg,
                  unit: BodyWeightUnit.st,
                  identifierPrefix: 'set-weight-dialog',
                  autofocus: true,
                  errorText: error,
                  onChangedKg: (kg) => setState(() => _stKg = kg),
                )
              else
                // The typed field below says the weight; the ruler is dimmed
                // while a typed weight is the one that will be saved.
                ExcludeSemantics(
                  child: Opacity(
                    opacity: _typedLast ? 0.38 : 1,
                    child: HorizontalPicker(
                      height: 100,
                      backgroundColor: Colors.transparent,
                      minValue: minWeight,
                      maxValue: maxWeight,
                      initialPosition: InitialPosition.center,
                      divisions: 1000, // Supports decimal values (#244)
                      suffix: isImperial
                          ? S.of(context).lbsLabel
                          : S.of(context).kgLabel,
                      onChanged: (value) {
                        setState(() {
                          _pickerDisplayWeight = value;
                          _typedLast = false;
                        });
                      },
                    ),
                  ),
                ),
              if (widget.unit != BodyWeightUnit.st)
                BodyWeightInput(
                  // Reseeded each time the ruler moves.
                  key: ValueKey(_pickerDisplayWeight.toStringAsFixed(1)),
                  initialKg: _pickerWeightToKg(
                    double.parse(_pickerDisplayWeight.toStringAsFixed(1)),
                  ),
                  unit: widget.unit,
                  identifierPrefix: 'set-weight-dialog',
                  errorText: error,
                  onChangedKg: (kg) => setState(() {
                    _stKg = kg;
                    _typedLast = true;
                  }),
                ),
              if (widget.allowDateSelection) ...[
                const SizedBox(height: 8),
                Semantics(
                  identifier: 'weight-date-picker',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(MaterialLocalizations.of(context)
                        .formatMediumDate(_selectedDate)),
                    onPressed: _pickDate,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: invalid ? null : _submit,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
