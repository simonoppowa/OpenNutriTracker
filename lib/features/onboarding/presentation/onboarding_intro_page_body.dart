import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingIntroPageBody extends StatefulWidget {
  const OnboardingIntroPageBody({Key? key, required this.setPageContent})
      : super(key: key);

  final Function(bool active) setPageContent;

  @override
  State<OnboardingIntroPageBody> createState() =>
      _OnboardingIntroPageBodyState();
}

class _OnboardingIntroPageBodyState extends State<OnboardingIntroPageBody> {
  bool _acceptedPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppBannerVersion(),
        const SizedBox(height: 32.0),
        Text(S.of(context).appDescription,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 32.0),
        Text(
          S.of(context).onboardingIntroDescription,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        ListTile(
          title: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: 'I have read the',
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: TextButton(
                            onPressed: _launchUrl,
                            child: Text(
                              'data protection',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            )))
                  ])),
          leading: Checkbox(
            value: _acceptedPolicy,
            onChanged: (value) {
              if (value != null) {
                _acceptedPolicy = value;
                widget.setPageContent(_acceptedPolicy);
              }
            },
          ),
        )
      ],
    );
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(Uri.parse(URLConst.privacyPolicyURL),
        mode: LaunchMode.externalApplication)) {}
  }
}
