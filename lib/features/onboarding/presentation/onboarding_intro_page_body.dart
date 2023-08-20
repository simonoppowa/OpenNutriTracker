import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingIntroPageBody extends StatefulWidget {
  const OnboardingIntroPageBody({Key? key, required this.setPageContent})
      : super(key: key);

  final Function(bool active, bool acceptedDataCollection) setPageContent;

  @override
  State<OnboardingIntroPageBody> createState() =>
      _OnboardingIntroPageBodyState();
}

class _OnboardingIntroPageBodyState extends State<OnboardingIntroPageBody> {
  bool _acceptedPolicy = false;
  bool _acceptedDataCollection = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppConst.getVersionNumber(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              AppBannerVersion(
                versionNumber: snapshot.requireData,
              ),
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
                onTap: () => _togglePolicy(),
                title: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                        text: S.of(context).readLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                              text: ' ${S.of(context).privacyPolicyLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchUrl();
                                }),
                        ])),
                leading: Checkbox(
                  value: _acceptedPolicy,
                  onChanged: (value) {
                    if (value != null) {
                      _togglePolicy();
                    }
                  },
                ),
              ),
              ListTile(
                onTap: () => _toggleDataCollection(),
                title: Text(S.of(context).dataCollectionLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
                leading: Checkbox(
                  value: _acceptedDataCollection,
                  onChanged: (value) => _toggleDataCollection(),
                ),
              )
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  void _togglePolicy() {
    setState(() {
      _acceptedPolicy = !_acceptedPolicy;
      widget.setPageContent(_acceptedPolicy, _acceptedDataCollection);
    });
  }

  void _toggleDataCollection() {
    setState(() {
      _acceptedDataCollection = !_acceptedDataCollection;
      widget.setPageContent(_acceptedPolicy, _acceptedDataCollection);
    });
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(Uri.parse(URLConst.privacyPolicyURLEn),
        mode: LaunchMode.externalApplication)) {}
  }
}
