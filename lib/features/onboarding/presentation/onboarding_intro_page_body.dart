import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingIntroPageBody extends StatelessWidget {
  const OnboardingIntroPageBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppBannerVersion(),
        const SizedBox(height: 32.0),
        Text(
            S.of(context).appDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 32.0),
        Text(
          S.of(context).onboardingIntroDescription,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}

