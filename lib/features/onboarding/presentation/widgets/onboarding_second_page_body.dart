import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingSecondPageBody extends StatefulWidget {
  final Function(bool active, double? selectedHeight, double? selectedWeight,
      bool usesImperialUnits) setButtonContent;

  const OnboardingSecondPageBody({super.key, required this.setButtonContent});

  @override
  State<OnboardingSecondPageBody> createState() =>
      _OnboardingSecondPageBodyState();
}

class _OnboardingSecondPageBodyState extends State<OnboardingSecondPageBody> {
  final _heightFormKey = GlobalKey<FormState>();
  final _weightFormKey = GlobalKey<FormState>();
  final _isUnitSelected = [true, false];
  double? _parsedHeight;
  double? _parsedWeight;

  bool get _isImperialSelected => _isUnitSelected[1];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).heightLabel,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(S.of(context).onboardingHeightQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          Form(
            key: _heightFormKey,
            child: TextFormField(
                onChanged: (text) {
                  _heightFormKey.currentState!.validate();
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  !_isImperialSelected
                      ? FilteringTextInputFormatter.digitsOnly
                      : FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+([.,]\d{0,1})?$'))
                ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              isSelected: _isUnitSelected,
              onPressed: (int index) {
                setState(() {
                  // Toggle height unit
                  for (int i = 0; i < _isUnitSelected.length; i++) {
                    _isUnitSelected[i] = i == index;
                  }
                  _heightFormKey.currentState!.validate();
                  _weightFormKey.currentState!.validate();
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
          Text(S.of(context).weightLabel,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(S.of(context).onboardingWeightQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          Form(
            key: _weightFormKey,
            child: TextFormField(
                onChanged: (text) {
                  _weightFormKey.currentState!.validate();
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
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              isSelected: _isUnitSelected,
              onPressed: (int index) {
                setState(() {
                  // Toggle height unit
                  for (int i = 0; i < _isUnitSelected.length; i++) {
                    _isUnitSelected[i] = i == index;
                  }
                  _weightFormKey.currentState!.validate();
                  _heightFormKey.currentState!.validate();
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
    return tryParseValidValue(value,
        ValueValidator.heightStringValidator(value, S.of(context).onboardingWrongHeightLabel, isImperial: _isImperialSelected),
        (String value, bool isImperial) => {
          _parsedHeight = ValueValidator.parseHeightInCm(double.tryParse(value), isImperial: _isImperialSelected)
        });
  }

  String? validateWeight(String? value) {
    return tryParseValidValue(value,
        ValueValidator.weightStringValidator(value, S.of(context).onboardingWrongHeightLabel, isImperial: _isImperialSelected),
            (String value, bool isImperial) => {
          _parsedWeight = ValueValidator.parseWeightInKg(double.tryParse(value), isImperial: _isImperialSelected)
        });
  }

  String? tryParseValidValue(String? value, String? errorLabel, Function(String, bool) parseValue){
    if(errorLabel != null) {
      widget.setButtonContent(false, null, null, _isImperialSelected);
      return errorLabel;
    }
    parseValue(value!, _isImperialSelected);
    _parsedWeight != null && _parsedHeight != null
        ? widget.setButtonContent(true, _parsedHeight, _parsedWeight, _isImperialSelected)
        : widget.setButtonContent(false, null, null, _isImperialSelected);
    return null;
  }
}
