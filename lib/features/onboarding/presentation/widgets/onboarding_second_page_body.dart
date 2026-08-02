import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/core/utils/calc/healthy_weight_calc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
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

  /// Ticked by the parent when the user taps a blocked "Next", so the page
  /// paints its errors for fields the user never left. Without it, someone
  /// who types an invalid weight and goes straight for the button gets only
  /// the footer snackbar and no indication of which field is at fault.
  final ValueListenable<int>? showErrorsSignal;

  const OnboardingSecondPageBody({
    super.key,
    required this.setButtonContent,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialTargetWeightKg,
    this.initialHeightImperial = false,
    this.initialBodyWeightUnit = BodyWeightUnit.kg,
    this.initialFoodImperial = false,
    this.showErrorsSignal,
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

  /// Anchors the healthy-range card so focusing the target field can scroll
  /// it into view. The card sits below that field, so the keyboard covers it
  /// while the user is deciding what to type.
  final _healthyRangeKey = GlobalKey();

  late bool _isHeightImperial;
  late BodyWeightUnit _bodyWeightUnit;
  late bool _isFoodImperial;

  double? _parsedHeight;
  double? _parsedWeight;
  // Target weight is optional. Null means "user hasn't set one"; the
  // onboarding flow stays valid either way. Only populated when the
  // input parses to a sensible kg value.
  double? _parsedTargetWeight;

  // Whether each field's error text is allowed on screen yet. Validation
  // runs on every keystroke, since that is what gates the Next button, but
  // the red text only appears once the user has left the field or tried to
  // move on. Typing "1" on the way to "180" produces no error.
  bool _showHeightError = false;
  bool _showWeightError = false;
  bool _showTargetError = false;

  // Values the user has explicitly confirmed as intentional in the
  // plausibility dialog, so leaving the field again doesn't re-ask.
  double? _confirmedHeightCm;
  double? _confirmedWeightKg;
  double? _confirmedTargetKg;

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
    _heightFocusNode.addListener(_onHeightFocusChange);
    _weightFocusNode.addListener(_onWeightFocusChange);
    _targetWeightFocusNode.addListener(_onTargetFocusChange);
    widget.showErrorsSignal?.addListener(_onShowErrorsRequested);

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

  void _onHeightFocusChange() {
    if (_heightFocusNode.hasFocus) return;
    _revealHeightError();
    _confirmHeightIfImplausible();
  }

  void _onWeightFocusChange() {
    if (_weightFocusNode.hasFocus) return;
    _revealWeightError();
    _confirmWeightIfImplausible();
  }

  void _onTargetFocusChange() {
    if (_targetWeightFocusNode.hasFocus) {
      _scrollSuggestionIntoView();
      return;
    }
    _revealTargetError();
    _confirmTargetIfImplausible();
  }

  /// Brings the suggestion card above the keyboard when the user moves into
  /// the target field. Runs after a short delay so the scroll is measured
  /// against the viewport the keyboard has already shrunk.
  Future<void> _scrollSuggestionIntoView() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final cardContext = _healthyRangeKey.currentContext;
    // Null when there is no height/weight yet, so no card; unmounted when
    // the page went away during the delay.
    if (cardContext == null || !cardContext.mounted) return;
    await Scrollable.ensureVisible(
      cardContext,
      // 1.0 lines the card's bottom up with the bottom of what's visible,
      // so the chip clears the keyboard.
      alignment: 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// The composite ft/in and stones widgets own their inner fields, so a
  /// [Focus] wrapper is how this page learns the whole group was left.
  void _onHeightGroupFocusChange(bool hasFocus) {
    if (hasFocus) return;
    _revealHeightError();
    _confirmHeightIfImplausible();
  }

  void _onWeightGroupFocusChange(bool hasFocus) {
    if (hasFocus) return;
    _revealWeightError();
    _confirmWeightIfImplausible();
  }

  void _onTargetGroupFocusChange(bool hasFocus) {
    if (hasFocus) {
      _scrollSuggestionIntoView();
      return;
    }
    _confirmTargetIfImplausible();
  }

  void _revealHeightError() {
    if (_showHeightError) return;
    setState(() => _showHeightError = true);
    _heightFormKey.currentState?.validate();
  }

  void _revealWeightError() {
    if (_showWeightError) return;
    setState(() => _showWeightError = true);
    _weightFormKey.currentState?.validate();
  }

  void _revealTargetError() {
    if (_showTargetError) return;
    setState(() => _showTargetError = true);
    _targetWeightFormKey.currentState?.validate();
  }

  /// The parent asks for this when a blocked Next is tapped.
  void _onShowErrorsRequested() {
    _revealHeightError();
    _revealWeightError();
    _revealTargetError();
  }

  /// Asks about a value that cleared the hard bounds but sits outside the
  /// ordinary range. 45 kg is a real weight, 4.5 kg is a typo, and both pass
  /// [Ranges]. Answering "Keep" records the value so the question isn't
  /// repeated for it.
  Future<void> _confirmHeightIfImplausible() async {
    final cm = _parsedHeight;
    if (cm == null) return; // hard-invalid: the inline error already says so
    if (ValueValidator.isPlausibleHeightCm(cm)) return;
    if (_confirmedHeightCm == cm) return;

    final display = formatHeight(
      cm,
      _isHeightImperial,
      cmLabel: S.of(context).cmLabel,
      ftLabel: S.of(context).ftLabel,
      inLabel: S.of(context).inLabel,
    );
    final keep = await _askKeepValue(
      S.of(context).onboardingImplausibleHeightBody(display),
    );
    if (!mounted) return;
    if (keep) {
      _confirmedHeightCm = cm;
    } else if (!_isHeightImperial) {
      // Only the single metric field has a focus node here; the ft/in
      // group manages its own, so the user taps back into it themselves.
      FocusScope.of(context).requestFocus(_heightFocusNode);
    }
  }

  Future<void> _confirmWeightIfImplausible() async {
    final kg = _parsedWeight;
    if (kg == null) return;
    if (ValueValidator.isPlausibleWeightKg(kg)) return;
    if (_confirmedWeightKg == kg) return;

    final keep = await _askKeepValue(
      S.of(context).onboardingImplausibleWeightBody(_formatKg(kg)),
    );
    if (!mounted) return;
    if (keep) {
      _confirmedWeightKg = kg;
    } else if (!_isWeightSt) {
      FocusScope.of(context).requestFocus(_weightFocusNode);
    }
  }

  Future<void> _confirmTargetIfImplausible() async {
    final kg = _parsedTargetWeight;
    if (kg == null) return; // empty is a valid "no target"
    if (ValueValidator.isPlausibleWeightKg(kg)) return;
    if (_confirmedTargetKg == kg) return;

    final keep = await _askKeepValue(
      S.of(context).onboardingImplausibleWeightBody(_formatKg(kg)),
    );
    if (!mounted) return;
    if (keep) {
      _confirmedTargetKg = kg;
    } else if (!_isWeightSt) {
      FocusScope.of(context).requestFocus(_targetWeightFocusNode);
    }
  }

  /// Returns whether the user chose to keep the value. Dismissing the
  /// dialog counts as keeping, since the value is legal.
  Future<bool> _askKeepValue(String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(dialogContext).onboardingImplausibleTitle),
        content: Text(body),
        actions: [
          Semantics(
            identifier: 'onboarding-implausible-change',
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(S.of(dialogContext).onboardingImplausibleChange),
            ),
          ),
          Semantics(
            identifier: 'onboarding-implausible-keep',
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(S.of(dialogContext).onboardingImplausibleKeep),
            ),
          ),
        ],
      ),
    );
    return result ?? true;
  }

  String _formatKg(double kg) => formatBodyWeight(
    kg,
    _bodyWeightUnit,
    kgLabel: S.of(context).kgLabel,
    lbLabel: S.of(context).lbsLabel,
    stLabel: S.of(context).stLabel,
  );

  /// Fills the optional target field with the suggested weight. The stones
  /// input seeds itself from `initialKg`, so it is rebuilt via its key to
  /// pick the new value up.
  void _applySuggestedTarget(double kg) {
    setState(() {
      _parsedTargetWeight = kg;
      _confirmedTargetKg = null;
      if (!_isWeightSt) {
        final display = _isWeightLb ? UnitCalc.kgToLbs(kg) : kg;
        _targetWeightController.text = _formatRestoredNumber(display);
      }
      checkCorrectInput();
    });
  }

  /// The WHO healthy-weight band for the entered height, with the figure it
  /// comes from stated next to it. Shown only once height and weight both
  /// parse, since the suggestion depends on both.
  Widget _buildHealthyRangeCard() {
    final heightCm = _parsedHeight!;
    final weightKg = _parsedWeight!;
    final range = HealthyWeightRange.forHeightCm(heightCm);
    final suggestion = range.suggestionFor(weightKg);
    final rangeText = '${_formatKg(range.minKg)} – ${_formatKg(range.maxKg)}';
    final heightText = formatHeight(
      heightCm,
      _isHeightImperial,
      cmLabel: S.of(context).cmLabel,
      ftLabel: S.of(context).ftLabel,
      inLabel: S.of(context).inLabel,
    );

    return Container(
      key: _healthyRangeKey,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.straighten_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  S
                      .of(context)
                      .onboardingHealthyRangeLabel(heightText, rangeText),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            S.of(context).onboardingHealthyRangeSource,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8.0),
          // A Wrap, so the citation link drops onto its own line instead of
          // overflowing when the chip carries a long stones-and-pounds label.
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                identifier: 'onboarding-target-weight-suggestion',
                child: ActionChip(
                  avatar: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(
                    S
                        .of(context)
                        .onboardingHealthyRangeApply(_formatKg(suggestion)),
                  ),
                  onPressed: () => _applySuggestedTarget(suggestion),
                ),
              ),
              // The line above names the rule; this links to the citation,
              // the WHO adult BMI classification the Sources screen lists.
              Semantics(
                identifier: 'onboarding-healthy-range-sources',
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SourcesScreen()),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(S.of(context).settingsSourcesLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    widget.showErrorsSignal?.removeListener(_onShowErrorsRequested);
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
                ? Focus(
                    canRequestFocus: false,
                    onFocusChange: _onHeightGroupFocusChange,
                    child: Semantics(
                      identifier: 'onboarding-height-field',
                      child: FeetInchesInput(
                        initialCm: _parsedHeight ?? widget.initialHeightCm,
                        identifierPrefix: 'onboarding-height',
                        errorText: _showHeightError && _parsedHeight == null
                            ? S.of(context).onboardingWrongHeightLabel
                            : null,
                        onChangedCm: (cm) {
                          setState(() => _parsedHeight = cm);
                          checkCorrectInput();
                        },
                      ),
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
                          setState(() {
                            _parsedHeight = ValueValidator.parseHeightInCm(
                              double.tryParse(text.replaceAll(',', '.')),
                              isImperial: false,
                            );
                          });
                          // Keep an already-visible error in step with the
                          // fix in progress; stay silent until then.
                          if (_showHeightError) {
                            _heightFormKey.currentState?.validate();
                          }
                          checkCorrectInput();
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
                ? Focus(
                    canRequestFocus: false,
                    onFocusChange: _onWeightGroupFocusChange,
                    child: BodyWeightInput(
                      initialKg: _parsedWeight ?? widget.initialWeightKg,
                      unit: BodyWeightUnit.st,
                      errorText: _showWeightError && _parsedWeight == null
                          ? S.of(context).onboardingWrongWeightLabel
                          : null,
                      onChangedKg: (kg) {
                        setState(() => _parsedWeight = kg);
                        checkCorrectInput();
                      },
                      identifierPrefix: 'onboarding-weight',
                    ),
                  )
                : Form(
                    key: _weightFormKey,
                    child: Semantics(
                      identifier: 'onboarding-weight-field',
                      child: TextFormField(
                        controller: _weightController,
                        focusNode: _weightFocusNode,
                        onChanged: (text) {
                          setState(() {
                            _parsedWeight = ValueValidator.parseWeightInKg(
                              double.tryParse(text.replaceAll(',', '.')),
                              isImperial: _isWeightLb,
                            );
                          });
                          if (_showWeightError) {
                            _weightFormKey.currentState?.validate();
                          }
                          checkCorrectInput();
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
                ? Focus(
                    canRequestFocus: false,
                    onFocusChange: _onTargetGroupFocusChange,
                    child: BodyWeightInput(
                      // Keyed on the applied suggestion so tapping the chip
                      // re-seeds the stones/pounds pair, which reads its
                      // value from initialKg only when it is built.
                      key: ValueKey(_parsedTargetWeight),
                      initialKg:
                          _parsedTargetWeight ?? widget.initialTargetWeightKg,
                      unit: BodyWeightUnit.st,
                      onChangedKg: (kg) {
                        // null is a valid result for the target field (user
                        // left both stones and pounds empty), so treat it as
                        // "no target" rather than blocking the Next button.
                        _parsedTargetWeight = kg;
                        checkCorrectInput();
                      },
                      identifierPrefix: 'onboarding-target-weight',
                    ),
                  )
                : Form(
                    key: _targetWeightFormKey,
                    child: Semantics(
                      identifier: 'onboarding-target-weight-field',
                      child: TextFormField(
                        controller: _targetWeightController,
                        focusNode: _targetWeightFocusNode,
                        onChanged: (text) {
                          setState(() {
                            _parsedTargetWeight = text.trim().isEmpty
                                ? null
                                : ValueValidator.parseWeightInKg(
                                    double.tryParse(text.replaceAll(',', '.')),
                                    isImperial: _isWeightLb,
                                  );
                          });
                          if (_showTargetError) {
                            _targetWeightFormKey.currentState?.validate();
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
            if (_parsedHeight != null && _parsedWeight != null) ...[
              const SizedBox(height: 16.0),
              _buildHealthyRangeCard(),
            ],
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
    // Silence until the field has been left or Next was tried: the button
    // is gated on the parsed value, so nothing depends on this returning
    // an error while the user is still typing.
    if (!_showHeightError) return null;
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
    if (!_showWeightError) return null;
    return _weightErrorFor(value);
  }

  String? _weightErrorFor(String? value) {
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

  /// Target weight is opt-in, so an empty field is valid. When the user has
  /// typed something we reuse the regular weight bounds check, but not
  /// [validateWeight] itself, whose silence is tied to the current weight
  /// field's reveal flag instead of this one's.
  String? validateOptionalTargetWeight(String? value) {
    if (!_showTargetError) return null;
    if (value == null || value.trim().isEmpty) return null;
    return _weightErrorFor(value);
  }

  void checkCorrectInput() {
    // Every path gates on the parsed value, not on a form validator. The
    // parse applies the same bounds the validator does, and keeping the two
    // apart lets the error text stay hidden while the button state tracks
    // the input keystroke by keystroke. It also removes the old asymmetry
    // where ft/in and stones were gated one way and the metric fields
    // another.

    // Target weight is always optional, so block only when the user has
    // typed something that doesn't parse. Empty (or null from
    // BodyWeightInput when both stones and pounds are blank) means
    // "no target".
    final bool isTargetValid;
    if (_isWeightSt) {
      isTargetValid = true;
    } else {
      final targetText = _targetWeightController.text.trim();
      isTargetValid = targetText.isEmpty || _parsedTargetWeight != null;
    }

    if (isTargetValid && _parsedHeight != null && _parsedWeight != null) {
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
