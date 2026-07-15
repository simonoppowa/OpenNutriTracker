import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Two coupled fields for entering height in feet and inches, the way it is
/// actually read ("5 ft 9 in") rather than decimal feet. Always reports a
/// centimetre value upward so storage stays metric; [onChangedCm] receives
/// null whenever the entry is empty or out of range, which callers use to gate
/// a save button.
class FeetInchesInput extends StatefulWidget {
  final double? initialCm;
  final ValueChanged<double?> onChangedCm;
  final String identifierPrefix;
  final bool autofocus;

  const FeetInchesInput({
    super.key,
    required this.initialCm,
    required this.onChangedCm,
    required this.identifierPrefix,
    this.autofocus = false,
  });

  @override
  State<FeetInchesInput> createState() => _FeetInchesInputState();
}

class _FeetInchesInputState extends State<FeetInchesInput> {
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;

  @override
  void initState() {
    super.initState();
    _feetController = TextEditingController();
    _inchesController = TextEditingController();
    final cm = widget.initialCm;
    if (cm != null) {
      final (feet, inches) = UnitCalc.cmToFeetInches(cm);
      _feetController.text = feet.toString();
      _inchesController.text = inches.toString();
    }
  }

  @override
  void dispose() {
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _emit() {
    final feet = int.tryParse(_feetController.text.trim());
    final inches = double.tryParse(_inchesController.text.trim());
    widget.onChangedCm(ValueValidator.parseFeetInchesHeightInCm(feet, inches));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            identifier: '${widget.identifierPrefix}-feet-input',
            child: TextField(
              controller: _feetController,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: S.of(context).ftLabel),
              onChanged: (_) => _emit(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            identifier: '${widget.identifierPrefix}-inches-input',
            child: TextField(
              controller: _inchesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: S.of(context).inLabel),
              onChanged: (_) => _emit(),
            ),
          ),
        ),
      ],
    );
  }
}
