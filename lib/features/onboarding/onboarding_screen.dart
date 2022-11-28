import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:opennutritracker/features/onboarding/presentation/onboarding_intro_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/highlight_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
            key: _introKey,
            scrollPhysics: const NeverScrollableScrollPhysics(),
            back: const Icon(Icons.arrow_back_outlined),
            showBackButton: true,
            showNextButton: false,
            showDoneButton: false,
            pages: getPageViewModels()),
      ),
    );
  }

  List<PageViewModel> getPageViewModels() => <PageViewModel>[
        PageViewModel(
            title: S.of(context).onboardingWelcomeLabel,
            bodyWidget: const OnboardingIntroPageBody(),
            footer: HighlightButton(
              buttonLabel: S.of(context).buttonStartLabel,
            ))
      ];
}
