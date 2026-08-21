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

  /// Error to show beneath the pair. The widget has no validator of its own.
  /// It reports null upward and lets the caller decide when an invalid entry
  /// is worth complaining about, which is how the onboarding page keeps
  /// quiet until the user leaves the field.
  final String? errorText;

  const FeetInchesInput({
    super.key,
    required this.initialCm,
    required this.onChangedCm,
    required this.identifierPrefix,
    this.autofocus = false,
    this.errorText,
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
    final errorText = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFields(context),
        // The message belongs to the feet/inches pair rather than to either
        // field, so it is rendered once beneath them, styled the way a
        // TextField renders its own error.
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFields(BuildContext context) {
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
