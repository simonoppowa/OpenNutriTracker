import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/body_weight_input.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/feet_inches_input.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingSecondPageBody extends StatefulWidget {
  final Function(
    bool active,
    double? selectedHeight,
    double? selectedWeight,
    double? selectedTargetWeight,
    bool heightImperial,
    BodyWeightUnit bodyWeightUnit,
    bool foodImperial,
  )
  setButtonContent;

  /// Already-stored height in centimetres (always metric in the parent's
  /// userSelection model). The widget converts to feet for display when
  /// [initialHeightImperial] is true.
  final double? initialHeightCm;

  /// Already-stored weight in kilograms (always metric in the parent's
  /// userSelection model). The widget converts to the display unit given by
  /// [initialBodyWeightUnit] when restoring previously entered values.
  final double? initialWeightKg;

  /// Optional already-stored target weight in kilograms. Same metric/unit
  /// convention as [initialWeightKg].
  final double? initialTargetWeightKg;

  final bool initialHeightImperial;
  final BodyWeightUnit initialBodyWeightUnit;
  final bool initialFoodImperial;

  const OnboardingSecondPageBody({
    super.key,
    required this.setButtonContent,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialTargetWeightKg,
    this.initialHeightImperial = false,
    this.initialBodyWeightUnit = BodyWeightUnit.kg,
    this.initialFoodImperial = false,
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

  late bool _isHeightImperial;
  late BodyWeightUnit _bodyWeightUnit;
  late bool _isFoodImperial;

  double? _parsedHeight;
  double? _parsedWeight;
  // Target weight is optional. Null means "user hasn't set one"; the
  // onboarding flow stays valid either way. Only populated when the
  // input parses to a sensible kg value.
  double? _parsedTargetWeight;

  bool get _isWeightLb => _bodyWeightUnit == BodyWeightUnit.lb;
  bool get _isWeightSt => _bodyWeightUnit == BodyWeightUnit.st;

  @override
  void initState() {
    super.initState();
    _isHeightImperial = widget.initialHeightImperial;
    _bodyWeightUnit = widget.initialBodyWeightUnit;
    _isFoodImperial = widget.initialFoodImperial;
    _heightFocusNode.attach(context);
    _weightFocusNode.attach(context);

    // Restore state if the parent passed previously-entered values (e.g.,
    // the user navigated back then forward). Stored values are always in
    // metric units; convert to the chosen display unit when restoring.
    final initialHeightCm = widget.initialHeightCm;
    if (initialHeightCm != null) {
      _parsedHeight = initialHeightCm;
      // The imperial path seeds the FeetInchesInput from initialCm; only the
      // metric cm field needs its controller primed here.
      if (!_isHeightImperial) {
        _heightController.text = _formatRestoredNumber(initialHeightCm);
      }
    }

    final initialWeightKg = widget.initialWeightKg;
    if (initialWeightKg != null && !_isWeightSt) {
      final displayWeight = _isWeightLb
          ? UnitCalc.kgToLbs(initialWeightKg)
          : initialWeightKg;
      _parsedWeight = initialWeightKg;
      _weightController.text = _formatRestoredNumber(displayWeight);
    }
    // For the stones unit, BodyWeightInput seeds itself from initialKg.

    final initialTargetWeightKg = widget.initialTargetWeightKg;
    if (initialTargetWeightKg != null && !_isWeightSt) {
      final displayTarget = _isWeightLb
          ? UnitCalc.kgToLbs(initialTargetWeightKg)
          : initialTargetWeightKg;
      _parsedTargetWeight = initialTargetWeightKg;
      _targetWeightController.text = _formatRestoredNumber(displayTarget);
    }
    // For the stones unit, BodyWeightInput seeds itself from initialKg.
  }

  /// Trim a restored value to one decimal place when needed, and drop the
  /// trailing '.0' for whole numbers — matches what users typically type.
  String _formatRestoredNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Called right after [_bodyWeightUnit] changes. The single kg/lb text
  /// field is shared between both units (only its label/validator differ),
  /// so switching between them needs to rewrite the displayed text to the
  /// converted value in the new unit — otherwise the field keeps showing
  /// the old number under a new label without recomputing [_parsedWeight]
  /// (form validation alone doesn't trigger onChanged). Re-seeding from the
  /// live parsed kg value (rather than the stale widget.initial*Kg prop)
  /// also makes sure a value the user just typed survives a round trip
  /// through the stones unit, whose own [BodyWeightInput] widget is
  /// unmounted/remounted on every toggle rather than updated in place.
  void _reseedWeightControllersForUnitChange() {
    if (_isWeightSt) return;
    if (_parsedWeight != null) {
      final displayWeight = _isWeightLb
          ? UnitCalc.kgToLbs(_parsedWeight!)
          : _parsedWeight!;
      _weightController.text = _formatRestoredNumber(displayWeight);
    }
    if (_parsedTargetWeight != null) {
      final displayTarget = _isWeightLb
          ? UnitCalc.kgToLbs(_parsedTargetWeight!)
          : _parsedTargetWeight!;
      _targetWeightController.text = _formatRestoredNumber(displayTarget);
    }
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
    // section doesn't overflow on short screens or in widget tests, which
    // pump straight into a Scaffold body without any outer scrollable.
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
            // Imperial height is two coupled fields (feet + inches) rather than
            // decimal feet, the way height is actually read. Metric stays a
            // single validated cm field.
            _isHeightImperial
                ? Semantics(
                    identifier: 'onboarding-height-field',
                    child: FeetInchesInput(
                      initialCm: _parsedHeight ?? widget.initialHeightCm,
                      identifierPrefix: 'onboarding-height',
                      onChangedCm: (cm) {
                        _parsedHeight = cm;
                        checkCorrectInput();
                      },
                    ),
                  )
                : Form(
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
                              isImperial: false,
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
                          labelText: S.of(context).cmLabel,
                          hintText: S.of(context).onboardingHeightExampleHintCm,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ToggleButtons(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                isSelected: [!_isHeightImperial, _isHeightImperial],
                onPressed: (int index) {
                  setState(() {
                    _isHeightImperial = index == 1;
                    // Metric is a single field; when returning to it from
                    // ft/in, rewrite the displayed cm text from the live
                    // parsed value rather than leaving whatever was typed
                    // before the last switch to imperial.
                    if (!_isHeightImperial && _parsedHeight != null) {
                      _heightController.text = _formatRestoredNumber(
                        _parsedHeight!,
                      );
                    }
                    _heightFormKey.currentState?.validate();
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
            const SizedBox(height: 8.0),
            // 3-way body-weight unit selector.
            Semantics(
              identifier: 'onboarding-body-weight-unit',
              child: SegmentedButton<BodyWeightUnit>(
                segments: [
                  ButtonSegment(
                    value: BodyWeightUnit.kg,
                    label: Text(S.of(context).kgLabel),
                  ),
                  ButtonSegment(
                    value: BodyWeightUnit.lb,
                    label: Text(S.of(context).lbsLabel),
                  ),
                  ButtonSegment(
                    value: BodyWeightUnit.st,
                    label: Text(S.of(context).stLabel),
                  ),
                ],
                selected: {_bodyWeightUnit},
                onSelectionChanged: (Set<BodyWeightUnit> selection) {
                  setState(() {
                    _bodyWeightUnit = selection.first;
                    _reseedWeightControllersForUnitChange();
                    if (!_isWeightSt) {
                      _weightFormKey.currentState?.validate();
                      _targetWeightFormKey.currentState?.validate();
                    }
                    checkCorrectInput();
                  });
                },
              ),
            ),
            const SizedBox(height: 16.0),
            _isWeightSt
                ? BodyWeightInput(
                    initialKg: _parsedWeight ?? widget.initialWeightKg,
                    unit: BodyWeightUnit.st,
                    onChangedKg: (kg) {
                      _parsedWeight = kg;
                      checkCorrectInput();
                    },
                    identifierPrefix: 'onboarding-weight',
                  )
                : Form(
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
                              isImperial: _isWeightLb,
                            );
                            checkCorrectInput();
                          } else {
                            _parsedWeight = null;
                            checkCorrectInput();
                          }
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_targetWeightFocusNode);
                        },
                        validator: validateWeight,
                        decoration: InputDecoration(
                          labelText: _isWeightLb
                              ? S.of(context).lbsLabel
                              : S.of(context).kgLabel,
                          hintText: _isWeightLb
                              ? S.of(context).onboardingWeightExampleHintLbs
                              : S.of(context).onboardingWeightExampleHintKg,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,1})?$'),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 32.0),
            // Target weight — optional. A new user can set it once in onboarding
            // instead of having to find Profile after first-run. Leaving it blank
            // keeps the user without a target and is valid.
            Text(
              S.of(context).profileTargetWeightLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              S.of(context).onboardingTargetWeightSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16.0),
            _isWeightSt
                ? BodyWeightInput(
                    initialKg:
                        _parsedTargetWeight ?? widget.initialTargetWeightKg,
                    unit: BodyWeightUnit.st,
                    onChangedKg: (kg) {
                      // null is a valid result for the target field (user left
                      // both stones and pounds empty), so we treat it as "no
                      // target" rather than blocking the Next button.
                      _parsedTargetWeight = kg;
                      checkCorrectInput();
                    },
                    identifierPrefix: 'onboarding-target-weight',
                  )
                : Form(
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
                            _parsedTargetWeight =
                                ValueValidator.parseWeightInKg(
                                  double.tryParse(text.replaceAll(',', '.')),
                                  isImperial: _isWeightLb,
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
                          labelText: _isWeightLb
                              ? S.of(context).lbsLabel
                              : S.of(context).kgLabel,
                          hintText: S
                              .of(context)
                              .onboardingTargetWeightHintOptional,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+([.,]\d{0,1})?$'),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 32.0),
            // Food units are chosen explicitly rather than inferred from the
            // height toggle, so a UK user on feet and stones can still log
            // food in grams.
            Text(
              S.of(context).settingsFoodUnitsLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              S.of(context).onboardingFoodUnitsSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Builder(
              builder: (context) {
                // Two equal-width buttons filling the row so each can show the
                // full metric / imperial unit list rather than one example.
                final buttonWidth =
                    (MediaQuery.of(context).size.width - 48) / 2;
                return Semantics(
                  identifier: 'onboarding-food-units',
                  child: ToggleButtons(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    constraints: BoxConstraints(
                      minHeight: 48,
                      minWidth: buttonWidth,
                      maxWidth: buttonWidth,
                    ),
                    isSelected: [!_isFoodImperial, _isFoodImperial],
                    onPressed: (int index) {
                      setState(() {
                        _isFoodImperial = index == 1;
                        checkCorrectInput();
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          S.of(context).settingsFoodUnitsMetric,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          S.of(context).settingsFoodUnitsImperial,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? validateHeight(String? value) {
    final label = S.of(context).onboardingWrongHeightLabel;
    if (ValueValidator.heightStringValidator(
          value,
          label,
          isImperial: _isHeightImperial,
        ) !=
        null) {
      return label;
    }
    final parsed = double.tryParse(value!.replaceAll(',', '.'));
    if (ValueValidator.parseHeightInCm(parsed, isImperial: _isHeightImperial) ==
        null) {
      return label;
    }
    return null;
  }

  String? validateWeight(String? value) {
    final label = S.of(context).onboardingWrongWeightLabel;
    if (ValueValidator.weightStringValidator(
          value,
          label,
          isImperial: _isWeightLb,
        ) !=
        null) {
      return label;
    }
    final parsed = double.tryParse(value!.replaceAll(',', '.'));
    if (ValueValidator.parseWeightInKg(parsed, isImperial: _isWeightLb) ==
        null) {
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
    // Imperial height uses the FeetInchesInput, which reports cm via its
    // callback, so gate on _parsedHeight rather than a form validator (the
    // form only exists in metric mode).
    final bool isHeightValid;
    if (_isHeightImperial) {
      isHeightValid = _parsedHeight != null;
    } else {
      isHeightValid = _heightFormKey.currentState?.validate() ?? false;
    }

    // For the stones unit, the BodyWeightInput widget manages its own
    // validation and reports via onChangedKg. We gate on _parsedWeight
    // being non-null rather than running a form validator.
    bool isWeightValid;
    if (_isWeightSt) {
      isWeightValid = _parsedWeight != null;
    } else {
      isWeightValid = _weightFormKey.currentState?.validate() ?? false;
    }

    // Target weight is always optional — block proceed only when the user has
    // typed something invalid; an empty field (or null from BodyWeightInput
    // when both stones + pounds are blank) is fine.
    bool isTargetValid;
    if (_isWeightSt) {
      // BodyWeightInput emits null when both fields are empty, which is valid
      // for an optional target. Any non-null value from it is already in-range.
      isTargetValid = true;
    } else {
      final targetText = _targetWeightController.text.trim();
      isTargetValid =
          targetText.isEmpty ||
          (_targetWeightFormKey.currentState?.validate() ?? false);
    }

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
        _isHeightImperial,
        _bodyWeightUnit,
        _isFoodImperial,
      );
    } else {
      widget.setButtonContent(
        false,
        null,
        null,
        null,
        _isHeightImperial,
        _bodyWeightUnit,
        _isFoodImperial,
      );
    }
  }
}
