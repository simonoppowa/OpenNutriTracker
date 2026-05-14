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
    double? selectedTargetWeight,
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

  /// Optional already-stored target weight (#119) in kilograms — set when
  /// the user has navigated back to this page after entering one. Same
  /// metric/imperial convention as [initialWeightKg].
  final double? initialTargetWeightKg;
  final bool initialUsesImperial;

  const OnboardingSecondPageBody({
    super.key,
    required this.setButtonContent,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialTargetWeightKg,
    this.initialUsesImperial = false,
  });

  @override
  State<OnboardingSecondPageBody> createState() =>
      _OnboardingSecondPageBodyState();
}

class _OnboardingSecondPageBodyState extends State<OnboardingSecondPageBody> {
  final _heightFormKey = GlobalKey<FormState>();
  final _weightFormKey = GlobalKey<FormState>();
  final _targetWeightFormKey = GlobalKey<FormState>();
  final _heightFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _targetWeightFocusNode = FocusNode();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  late final List<bool> _isUnitSelected = [
    !widget.initialUsesImperial,
    widget.initialUsesImperial,
  ];
  double? _parsedHeight;
  double? _parsedWeight;
  // Target weight is optional. Null means "user hasn't set one"; the
  // onboarding flow stays valid either way. Only populated when the
  // input parses to a sensible kg value.
  double? _parsedTargetWeight;

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
    final initialTargetWeightKg = widget.initialTargetWeightKg;
    if (initialTargetWeightKg != null) {
      final displayTarget = widget.initialUsesImperial
          ? UnitCalc.kgToLbs(initialTargetWeightKg)
          : initialTargetWeightKg;
      _parsedTargetWeight = initialTargetWeightKg;
      _targetWeightController.text = _formatRestoredNumber(displayTarget);
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
    _targetWeightFocusNode.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrapped in a SingleChildScrollView so the extra target-weight
    // section (#119 follow-up) doesn't overflow on short screens or in
    // the widget tests, which pump straight into a Scaffold body
    // without any outer scrollable.
    return SingleChildScrollView(
      child: SizedBox(
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
                  FocusScope.of(context).requestFocus(_targetWeightFocusNode);
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
                  _targetWeightFormKey.currentState?.validate();
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
          const SizedBox(height: 32.0),
          // Target weight (#119) on the same screen as the current
          // weight so a new user can set it once in onboarding instead
          // of having to find Profile after first-run. Optional: leaving
          // it blank keeps the user without a target and is valid.
          Text(
            S.of(context).profileTargetWeightLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            S.of(context).onboardingTargetWeightSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          Form(
            key: _targetWeightFormKey,
            child: Semantics(
              identifier: 'onboarding-target-weight-field',
              child: TextFormField(
                controller: _targetWeightController,
                focusNode: _targetWeightFocusNode,
                onChanged: (text) {
                  if (text.trim().isEmpty) {
                    _parsedTargetWeight = null;
                    checkCorrectInput();
                    return;
                  }
                  if (_targetWeightFormKey.currentState!.validate()) {
                    _parsedTargetWeight = ValueValidator.parseWeightInKg(
                      double.tryParse(text.replaceAll(',', '.')),
                      isImperial: _isImperialSelected,
                    );
                  } else {
                    _parsedTargetWeight = null;
                  }
                  checkCorrectInput();
                },
                onFieldSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                },
                validator: validateOptionalTargetWeight,
                decoration: InputDecoration(
                  labelText: _isImperialSelected
                      ? S.of(context).lbsLabel
                      : S.of(context).kgLabel,
                  hintText: S.of(context).onboardingTargetWeightHintOptional,
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
          ],
        ),
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

  /// Target weight is opt-in, so an empty field is valid. When the user
  /// has typed something we reuse the regular weight validator to keep
  /// the bounds consistent.
  String? validateOptionalTargetWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return validateWeight(value);
  }

  void checkCorrectInput() {
    final isHeightValid = _heightFormKey.currentState?.validate() ?? false;
    final isWeightValid = _weightFormKey.currentState?.validate() ?? false;
    // Target weight is optional. Block proceed only when the user has
    // typed something invalid; an empty field is fine.
    final targetText = _targetWeightController.text.trim();
    final isTargetValid = targetText.isEmpty ||
        (_targetWeightFormKey.currentState?.validate() ?? false);

    if (isHeightValid &&
        isWeightValid &&
        isTargetValid &&
        _parsedHeight != null &&
        _parsedWeight != null) {
      widget.setButtonContent(
        true,
        _parsedHeight,
        _parsedWeight,
        _parsedTargetWeight,
        _isImperialSelected,
      );
    } else {
      widget.setButtonContent(
        false,
        null,
        null,
        null,
        _isImperialSelected,
      );
    }
  }
}
