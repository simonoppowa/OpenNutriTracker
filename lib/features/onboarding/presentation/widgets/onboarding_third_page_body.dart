import 'package:flutter/material.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingThirdPageBody extends StatefulWidget {
  final Function(bool active, UserActivitySelectionEntity? selectedActivity)
      setButtonContent;

  const OnboardingThirdPageBody({Key? key, required this.setButtonContent})
      : super(key: key);

  @override
  State<OnboardingThirdPageBody> createState() =>
      _OnboardingThirdPageBodyState();
}

class _OnboardingThirdPageBodyState extends State<OnboardingThirdPageBody> {
  bool _sedentarySelected = false;
  bool _lowActiveSelected = false;
  bool _activeSelected = false;
  bool _veryActiveSelected = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).activityLabel,
              style: Theme.of(context).textTheme.headline5),
          Text(S.of(context).onboardingActivityQuestionSubtitle,
              style: Theme.of(context).textTheme.subtitle1),
          const SizedBox(height: 16.0),
          SizedBox(
            width: 300,
            child: ChoiceChip(
              label: Column(
                children: [
                  Text(S.of(context).palSedentaryLabel,
                      style: Theme.of(context).textTheme.subtitle2),
                  Text(
                    S.of(context).palSedentaryDescriptionLabel,
                    style: Theme.of(context).textTheme.overline,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    maxLines: 3,
                  ),
                ],
              ),
              selected: _sedentarySelected,
              onSelected: (bool selected) {
                setState(() {
                  _setSelectedChoiceChip(sedentary: true);
                  checkCorrectInput();
                });
              },
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: 400,
            child: ChoiceChip(
              label: Column(
                children: [
                  Text(S.of(context).palLowLActiveLabel,
                      style: Theme.of(context).textTheme.subtitle2),
                  Text(
                    S.of(context).palLowActiveDescriptionLabel,
                    style: Theme.of(context).textTheme.overline,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    maxLines: 3,
                  ),
                ],
              ),
              selected: _lowActiveSelected,
              onSelected: (bool selected) {
                setState(() {
                  _setSelectedChoiceChip(lowActive: true);
                  checkCorrectInput();
                });
              },
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: 400,
            child: ChoiceChip(
              label: Column(
                children: [
                  Text(S.of(context).palActiveLabel,
                      style: Theme.of(context).textTheme.subtitle2),
                  Text(
                    S.of(context).palActiveDescriptionLabel,
                    style: Theme.of(context).textTheme.overline,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    maxLines: 3,
                  ),
                ],
              ),
              selected: _activeSelected,
              onSelected: (bool selected) {
                setState(() {
                  _setSelectedChoiceChip(active: true);
                  checkCorrectInput();
                });
              },
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: 400,
            child: ChoiceChip(
              label: Column(
                children: [
                  Text(S.of(context).palVeryActiveLabel,
                      style: Theme.of(context).textTheme.subtitle2),
                  Text(
                    S.of(context).palVeryActiveDescriptionLabel,
                    style: Theme.of(context).textTheme.overline,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    maxLines: 5,
                  ),
                ],
              ),
              selected: _veryActiveSelected,
              onSelected: (bool selected) {
                setState(() {
                  _setSelectedChoiceChip(veryActive: true);
                  checkCorrectInput();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _setSelectedChoiceChip(
      {sedentary = false,
      lowActive = false,
      active = false,
      veryActive = false}) {
    _sedentarySelected = sedentary;
    _lowActiveSelected = lowActive;
    _activeSelected = active;
    _veryActiveSelected = veryActive;
  }

  void checkCorrectInput() {
    UserActivitySelectionEntity? selectedActivity;
    if (_sedentarySelected) {
      selectedActivity = UserActivitySelectionEntity.sedentary;
    } else if (_lowActiveSelected) {
      selectedActivity = UserActivitySelectionEntity.lowActive;
    } else if (_activeSelected) {
      selectedActivity = UserActivitySelectionEntity.active;
    } else if (_veryActiveSelected) {
      selectedActivity = UserActivitySelectionEntity.veryActive;
    }

    if (selectedActivity != null) {
      widget.setButtonContent(true, selectedActivity);
    } else {
      widget.setButtonContent(false, null);
    }
  }
}
