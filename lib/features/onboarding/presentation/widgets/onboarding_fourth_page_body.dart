import 'package:flutter/material.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingFourthPageBody extends StatefulWidget {
  final Function(bool active, UserGoalSelectionEntity? selectedGoal)
      setButtonContent;

  const OnboardingFourthPageBody({Key? key, required this.setButtonContent})
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
              style: Theme.of(context).textTheme.headlineSmall),
          Text(S.of(context).onboardingGoalQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          ChoiceChip(
            label: Text(S.of(context).goalLoseWeight,
                style: Theme.of(context).textTheme.titleLarge),
            selected: _looseWeightSelected,
            onSelected: (bool selected) {
              setState(() {
                _setSelectedChoiceChip(looseWeight: true);
                _checkCorrectInput();
              });
            },
          ),
          const SizedBox(height: 8.0),
          ChoiceChip(
            label: Text(S.of(context).goalMaintainWeight,
                style: Theme.of(context).textTheme.titleLarge),
            selected: _maintainWeightSelected,
            onSelected: (bool selected) {
              setState(() {
                _setSelectedChoiceChip(maintainWeigh: true);
                _checkCorrectInput();
              });
            },
          ),
          const SizedBox(height: 8.0),
          ChoiceChip(
            label: Text(S.of(context).goalGainWeight,
                style: Theme.of(context).textTheme.titleLarge),
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
    UserGoalSelectionEntity? selectedGoal;
    if (_looseWeightSelected) {
      selectedGoal = UserGoalSelectionEntity.loseWeight;
    } else if (_maintainWeightSelected) {
      selectedGoal = UserGoalSelectionEntity.maintainWeight;
    } else if (_gainWeightSelected) {
      selectedGoal = UserGoalSelectionEntity.gainWeigh;
    }

    if (selectedGoal != null) {
      widget.setButtonContent(true, selectedGoal);
    } else {
      widget.setButtonContent(false, null);
    }
  }
}
