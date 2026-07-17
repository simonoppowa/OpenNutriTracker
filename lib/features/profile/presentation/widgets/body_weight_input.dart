import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A body-weight text input that adapts to the user's chosen unit and always
/// reports a kilogram value upward. For kg and lb it shows a single field; for
/// stones it shows two coupled fields (whole stones + pounds) so a UK user can
/// enter "11 st 5.2 lb" the way they think of it.
///
/// Storage is always metric, so the widget converts on the way out via
/// [ValueValidator]. [onChangedKg] receives null whenever the current input is
/// empty or out of range, which callers use to gate a save button.
class BodyWeightInput extends StatefulWidget {
  final double? initialKg;
  final BodyWeightUnit unit;
  final ValueChanged<double?> onChangedKg;

  /// Prefix for the `Semantics(identifier:)` handles so each call site stays
  /// distinct for UI drivers, e.g. 'weight-history' -> 'weight-history-stones'.
  final String identifierPrefix;
  final bool autofocus;

  const BodyWeightInput({
    super.key,
    required this.initialKg,
    required this.unit,
    required this.onChangedKg,
    required this.identifierPrefix,
    this.autofocus = false,
  });

  @override
  State<BodyWeightInput> createState() => _BodyWeightInputState();
}

class _BodyWeightInputState extends State<BodyWeightInput> {
  // Single field for kg / lb.
  late final TextEditingController _singleController;
  // Two fields for stones + pounds.
  late final TextEditingController _stonesController;
  late final TextEditingController _poundsController;

  @override
  void initState() {
    super.initState();
    _singleController = TextEditingController();
    _stonesController = TextEditingController();
    _poundsController = TextEditingController();
    _seedFromInitial();
  }

  void _seedFromInitial() {
    final kg = widget.initialKg;
    if (kg == null) return;
    switch (widget.unit) {
      case BodyWeightUnit.kg:
        _singleController.text = _trim(kg);
      case BodyWeightUnit.lb:
        _singleController.text = _trim(UnitCalc.kgToLbs(kg));
      case BodyWeightUnit.st:
        final (stones, pounds) = UnitCalc.kgToStLb(kg);
        _stonesController.text = stones.toString();
        _poundsController.text = _trim(pounds);
    }
  }

  /// Drops a trailing ".0" so a whole number reads as the user would type it.
  String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  void didUpdateWidget(covariant BodyWeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the unit changes (e.g. the user flips the selector above this
    // field), reseed the controllers from the same stored kg so the value
    // carries across rather than clearing.
    if (oldWidget.unit != widget.unit) {
      _singleController.clear();
      _stonesController.clear();
      _poundsController.clear();
      _seedFromInitial();
    }
  }

  @override
  void dispose() {
    _singleController.dispose();
    _stonesController.dispose();
    _poundsController.dispose();
    super.dispose();
  }

  void _emitSingle(String text) {
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    final kg = ValueValidator.parseWeightInKg(
      parsed,
      isImperial: widget.unit == BodyWeightUnit.lb,
    );
    widget.onChangedKg(kg);
  }

  void _emitStLb() {
    final stones = int.tryParse(_stonesController.text.trim());
    final pounds = double.tryParse(
      _poundsController.text.trim().replaceAll(',', '.'),
    );
    widget.onChangedKg(ValueValidator.parseStLbWeightInKg(stones, pounds));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unit == BodyWeightUnit.st) {
      return _buildStLbFields(context);
    }
    return _buildSingleField(context);
  }

  Widget _buildSingleField(BuildContext context) {
    final label = widget.unit == BodyWeightUnit.lb
        ? S.of(context).lbsLabel
        : S.of(context).kgLabel;
    return Semantics(
      identifier: '${widget.identifierPrefix}-weight-input',
      child: TextField(
        controller: _singleController,
        autofocus: widget.autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,1})?$')),
        ],
        decoration: InputDecoration(labelText: label),
        onChanged: _emitSingle,
      ),
    );
  }

  Widget _buildStLbFields(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            identifier: '${widget.identifierPrefix}-stones-input',
            child: TextField(
              controller: _stonesController,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: S.of(context).stLabel),
              onChanged: (_) => _emitStLb(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            identifier: '${widget.identifierPrefix}-pounds-input',
            child: TextField(
              controller: _poundsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+([.,]\d{0,1})?$'),
                ),
              ],
              decoration: InputDecoration(labelText: S.of(context).lbsLabel),
              onChanged: (_) => _emitStLb(),
            ),
          ),
        ),
      ],
    );
  }
}
