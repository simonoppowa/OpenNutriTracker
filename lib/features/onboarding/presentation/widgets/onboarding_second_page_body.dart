import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingSecondPageBody extends StatefulWidget {
  final Function(bool active) setButtonActive;

  const OnboardingSecondPageBody({Key? key, required this.setButtonActive})
      : super(key: key);

  @override
  State<OnboardingSecondPageBody> createState() =>
      _OnboardingSecondPageBodyState();
}

class _OnboardingSecondPageBodyState extends State<OnboardingSecondPageBody> {
  final _pageFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Form(
        key: _pageFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).heightLabel,
                style: Theme.of(context).textTheme.headline5),
            Text(S.of(context).onboardingHeightQuestionSubtitle,
                style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 16.0),
            TextFormField(
                onChanged: (text) {
                  if (_pageFormKey.currentState!.validate()) {
                    widget.setButtonActive(true);
                  } else {
                    widget.setButtonActive(false);
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
            const SizedBox(height: 32.0),
            Text(S.of(context).weightLabel,
                style: Theme.of(context).textTheme.headline5),
            Text(S.of(context).onboardingWeightQuestionSubtitle,
                style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 16.0),
            TextFormField(
                onChanged: (text) {
                  if (_pageFormKey.currentState!.validate()) {
                    widget.setButtonActive(true);
                  } else {
                    widget.setButtonActive(false);
                  }
                },
                validator: validateHeight,
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
          ],
        ),
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
}
