import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingSecondPageBody extends StatefulWidget {
  final Function(
    bool active,
    double? selectedHeight,
    double? selectedWeight,
    bool usesImperialUnits,
  ) setButtonContent;

  /// Already-stored height in centimetres (always metric in the parent's
  /// userSelection model). The widget converts to feet for display when
  /// [initialUsesImperial] is true.
  final double? initialHeightCm;

  /// Already-stored weight in kilograms (always metric in the parent's
  /// userSelection model). The widget converts to pounds for display when
  /// [initialUsesImperial] is true.
  final double? initialWeightKg;
  final bool initialUsesImperial;

  const OnboardingSecondPageBody({
    super.key,
    required this.setButtonContent,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialUsesImperial = false,
  });

  @override
  State<OnboardingSecondPageBody> createState() =>
      _OnboardingSecondPageBodyState();
}

class _OnboardingSecondPageBodyState extends State<OnboardingSecondPageBody> {
  final _heightFormKey = GlobalKey<FormState>();
  final _weightFormKey = GlobalKey<FormState>();
  final _heightFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  late final List<bool> _isUnitSelected = [
    !widget.initialUsesImperial,
    widget.initialUsesImperial,
  ];
  double? _parsedHeight;
  double? _parsedWeight;

  bool get _isImperialSelected => _isUnitSelected[1];

  @override
  void initState() {
    super.initState();
    _heightFocusNode.attach(context);
    _weightFocusNode.attach(context);

    // Restore state if the parent passed previously-entered values (e.g.,
    // the user navigated back then forward). Stored values are always in
    // metric units; convert to feet/lbs when the user picked imperial.
    final initialHeightCm = widget.initialHeightCm;
    final initialWeightKg = widget.initialWeightKg;
    if (initialHeightCm != null) {
      final displayHeight = widget.initialUsesImperial
          ? UnitCalc.cmToFeet(initialHeightCm)
          : initialHeightCm;
      _parsedHeight = initialHeightCm;
      _heightController.text = _formatRestoredNumber(displayHeight);
    }
    if (initialWeightKg != null) {
      final displayWeight = widget.initialUsesImperial
          ? UnitCalc.kgToLbs(initialWeightKg)
          : initialWeightKg;
      _parsedWeight = initialWeightKg;
      _weightController.text = _formatRestoredNumber(displayWeight);
    }
  }

  /// Trim a restored value to one decimal place when needed, and drop the
  /// trailing '.0' for whole numbers — matches what users typically type.
  String _formatRestoredNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).heightLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            S.of(context).onboardingHeightQuestionSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          Form(
            key: _heightFormKey,
            child: Semantics(
              identifier: 'onboarding-height-field',
              child: TextFormField(
                controller: _heightController,
                focusNode: _heightFocusNode,
                onChanged: (text) {
                  if (_heightFormKey.currentState!.validate()) {
                    _parsedHeight = ValueValidator.parseHeightInCm(
                      double.tryParse(text.replaceAll(',', '.')),
                      isImperial: _isImperialSelected,
                    );
                    checkCorrectInput();
                  } else {
                    _parsedHeight = null;
                    checkCorrectInput();
                  }
                },
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_weightFocusNode);
                },
                validator: validateHeight,
                decoration: InputDecoration(
                  labelText: _isImperialSelected ? 'ft' : 'cm',
                  hintText: _isImperialSelected
                      ? S.of(context).onboardingHeightExampleHintFt
                      : S.of(context).onboardingHeightExampleHintCm,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  !_isImperialSelected
                      ? FilteringTextInputFormatter.digitsOnly
                      : FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+([.,]\d{0,1})?$'),
                        ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              isSelected: _isUnitSelected,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < _isUnitSelected.length; i++) {
                    _isUnitSelected[i] = i == index;
                  }
                  _heightFormKey.currentState!.validate();
                  checkCorrectInput();
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(S.of(context).cmLabel),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(S.of(context).ftLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),
          Text(
            S.of(context).weightLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            S.of(context).onboardingWeightQuestionSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          Form(
            key: _weightFormKey,
            child: Semantics(
              identifier: 'onboarding-weight-field',
              child: TextFormField(
                controller: _weightController,
                focusNode: _weightFocusNode,
                onChanged: (text) {
                  if (_weightFormKey.currentState!.validate()) {
                    _parsedWeight = ValueValidator.parseWeightInKg(
                      double.tryParse(text.replaceAll(',', '.')),
                      isImperial: _isImperialSelected,
                    );
                    checkCorrectInput();
                  } else {
                    _parsedWeight = null;
                    checkCorrectInput();
                  }
                },
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                },
                validator: validateWeight,
                decoration: InputDecoration(
                  labelText: _isImperialSelected
                      ? S.of(context).lbsLabel
                      : S.of(context).kgLabel,
                  hintText: _isImperialSelected
                      ? S.of(context).onboardingWeightExampleHintLbs
                      : S.of(context).onboardingWeightExampleHintKg,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+([.,]\d{0,1})?$'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              isSelected: _isUnitSelected,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < _isUnitSelected.length; i++) {
                    _isUnitSelected[i] = i == index;
                  }
                  _weightFormKey.currentState!.validate();
                  checkCorrectInput();
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(S.of(context).kgLabel),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(S.of(context).lbsLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? validateHeight(String? value) {
    final label = S.of(context).onboardingWrongHeightLabel;
    if (ValueValidator.heightStringValidator(value, label, isImperial: _isImperialSelected) != null) {
      return label;
    }
    final parsed = double.tryParse(value!.replaceAll(',', '.'));
    if (ValueValidator.parseHeightInCm(parsed, isImperial: _isImperialSelected) == null) {
      return label;
    }
    return null;
  }

  String? validateWeight(String? value) {
    final label = S.of(context).onboardingWrongWeightLabel;
    if (ValueValidator.weightStringValidator(value, label, isImperial: _isImperialSelected) != null) {
      return label;
    }
    final parsed = double.tryParse(value!.replaceAll(',', '.'));
    if (ValueValidator.parseWeightInKg(parsed, isImperial: _isImperialSelected) == null) {
      return label;
    }
    return null;
  }

  void checkCorrectInput() {
    final isHeightValid = _heightFormKey.currentState?.validate() ?? false;
    final isWeightValid = _weightFormKey.currentState?.validate() ?? false;

    if (isHeightValid && isWeightValid && _parsedHeight != null && _parsedWeight != null) {
      widget.setButtonContent(true, _parsedHeight, _parsedWeight, _isImperialSelected);
    } else {
      widget.setButtonContent(false, null, null, _isImperialSelected);
    }
  }
}
