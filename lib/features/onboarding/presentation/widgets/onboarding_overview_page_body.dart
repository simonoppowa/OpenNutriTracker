import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingOverviewPageBody extends StatelessWidget {
  final Function(bool active) setButtonActive;
  const OnboardingOverviewPageBody({Key? key, required this.setButtonActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).onboardingOverviewLabel,
              style: Theme.of(context).textTheme.headline5),
        ],
      ),
    );
  }
}
