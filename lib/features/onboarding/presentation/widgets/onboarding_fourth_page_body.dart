import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingFourthPageBody extends StatefulWidget {
  final Function(bool active) setButtonActive;

  const OnboardingFourthPageBody({Key? key, required this.setButtonActive})
      : super(key: key);

  @override
  State<OnboardingFourthPageBody> createState() =>
      _OnboardingFourthPageBodyState();
}

class _OnboardingFourthPageBodyState extends State<OnboardingFourthPageBody> {
  bool _looseWeightSelected = false;
  bool _maintainWeightSelected = false;
  bool _gainWeightSelected = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).goalLabel,
              style: Theme.of(context).textTheme.headline5),
          Text(S.of(context).onboardingGoalQuestionSubtitle,
              style: Theme.of(context).textTheme.subtitle1),
          const SizedBox(height: 16.0),
          ChoiceChip(
            label: Text(S.of(context).goalLooseWeight),
            selected: _looseWeightSelected,
            onSelected: (bool selected) {
              setState(() {
                _setSelectedChoiceChip(looseWeight: true);
                _checkCorrectInput();
              });
            },
          ),
          ChoiceChip(
            label: Text(S.of(context).goalMaintainWeight),
            selected: _maintainWeightSelected,
            onSelected: (bool selected) {
              setState(() {
                _setSelectedChoiceChip(maintainWeigh: true);
                _checkCorrectInput();
              });
            },
          ),
          ChoiceChip(
            label: Text(S.of(context).goalGainWeight),
            selected: _gainWeightSelected,
            onSelected: (bool selected) {
              setState(() {
                _setSelectedChoiceChip(gainWeight: true);
                _checkCorrectInput();
              });
            },
          ),
        ],
      ),
    );
  }

  void _setSelectedChoiceChip(
      {looseWeight = false, maintainWeigh = false, gainWeight = false}) {
    _looseWeightSelected = looseWeight;
    _maintainWeightSelected = maintainWeigh;
    _gainWeightSelected = gainWeight;
  }

  void _checkCorrectInput() {
    if (_looseWeightSelected ||
        _maintainWeightSelected ||
        _gainWeightSelected) {
      widget.setButtonActive(true);
    } else {
      widget.setButtonActive(false);
    }
  }
}
