import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingSecondPageBody extends StatefulWidget {
  final Function(bool active, double? selectedHeight, double? selectedWeight)
      setButtonContent;

  const OnboardingSecondPageBody({Key? key, required this.setButtonContent})
      : super(key: key);

  @override
  State<OnboardingSecondPageBody> createState() =>
      _OnboardingSecondPageBodyState();
}

class _OnboardingSecondPageBodyState extends State<OnboardingSecondPageBody> {
  final _heightFormKey = GlobalKey<FormState>();
  final _weightFormKey = GlobalKey<FormState>();
  double? _parsedHeight;
  double? _parsedWeight;

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
                  if (_heightFormKey.currentState!.validate()) {
                    _parsedHeight = double.tryParse(text);
                    checkCorrectInput();
                  } else {
                    _parsedHeight = null;
                    checkCorrectInput();
                  }
                },
                validator: validateHeight,
                decoration: InputDecoration(
                  labelText: 'cm',
                  hintText: S.of(context).onboardingHeightExampleHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
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
                  if (_weightFormKey.currentState!.validate()) {
                    _parsedWeight = double.tryParse(text);
                    checkCorrectInput();
                  } else {
                    _parsedWeight = null;
                    checkCorrectInput();
                  }
                },
                validator: validateWeight,
                decoration: InputDecoration(
                  labelText: 'kg',
                  hintText: S.of(context).onboardingWeightExampleHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          ),
        ],
      ),
    );
  }

  String? validateHeight(String? value) {
    if (value == null) return S.of(context).onboardingWrongHeightLabel;
    if (value.isEmpty || !RegExp(r'^[0-9]').hasMatch(value)) {
      return S.of(context).onboardingWrongHeightLabel;
    } else {
      return null;
    }
  }

  String? validateWeight(String? value) {
    if (value == null) return S.of(context).onboardingWrongWeightLabel;
    if (value.isEmpty || !RegExp(r'^[0-9]').hasMatch(value)) {
      return S.of(context).onboardingWrongHeightLabel;
    } else {
      return null;
    }
  }

  void checkCorrectInput() {
    if (_parsedHeight != null && _parsedWeight != null) {
      widget.setButtonContent(true, _parsedHeight, _parsedWeight);
    } else {
      widget.setButtonContent(false, null, null);
    }
  }
}
