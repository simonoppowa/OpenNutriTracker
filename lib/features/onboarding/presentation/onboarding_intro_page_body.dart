import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/demo/demo_seeder.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_switch_coordinator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingIntroPageBody extends StatefulWidget {
  const OnboardingIntroPageBody({
    super.key,
    required this.setPageContent,
    this.initialAcceptedPolicy = false,
    this.initialAcceptedDataCollection = false,
  });

  final Function(bool active, bool acceptedDataCollection) setPageContent;
  final bool initialAcceptedPolicy;
  final bool initialAcceptedDataCollection;

  @override
  State<OnboardingIntroPageBody> createState() =>
      _OnboardingIntroPageBodyState();
}

class _OnboardingIntroPageBodyState extends State<OnboardingIntroPageBody> {
  late bool _acceptedPolicy = widget.initialAcceptedPolicy;
  late bool _acceptedDataCollection = widget.initialAcceptedDataCollection;
  bool _seedingDemo = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppConst.getVersionNumber(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          // Scroll so the demo CTA + checkboxes still fit on shorter
          // viewports (e.g. the 800×600 surface used by widget tests).
          return SingleChildScrollView(
            child: Column(
              children: [
                AppBannerVersion(versionNumber: snapshot.requireData),
                const SizedBox(height: 32.0),
                Text(
                  S.of(context).appDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                Text(
                  S.of(context).onboardingIntroDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                // Policy first: both Start (footer) and Try Demo require it.
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchUrl();
                            },
                        ),
                      ],
                    ),
                  ),
                  leading: Semantics(
                    identifier: 'onboarding-checkbox-privacy',
                    child: Checkbox(
                      value: _acceptedPolicy,
                      onChanged: (value) {
                        if (value != null) {
                          _togglePolicy();
                        }
                      },
                    ),
                  ),
                ),
                ListTile(
                  onTap: () => _toggleDataCollection(),
                  title: Text(
                    S.of(context).dataCollectionLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  leading: Semantics(
                    identifier: 'onboarding-checkbox-data',
                    child: Checkbox(
                      value: _acceptedDataCollection,
                      onChanged: (value) => _toggleDataCollection(),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Semantics(
                  identifier: 'onboarding-try-demo',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      // Stays tappable without the policy so the tap can
                      // explain itself; only the in-flight seed truly
                      // disables it.
                      onPressed: _seedingDemo
                          ? null
                          : (_acceptedPolicy ? _tryDemo : _policyRequired),
                      style: _acceptedPolicy
                          ? null
                          : OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.38),
                            ),
                      icon: _seedingDemo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility_outlined),
                      label: Text(S.of(context).onboardingTryDemoLabel),
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  S.of(context).onboardingTryDemoSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4.0),
                Text(
                  S.of(context).onboardingTryDemoDisclaimer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                TextButton.icon(
                  onPressed: () => _openSources(context),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(S.of(context).onboardingIntroSourcesLinkLabel),
                ),
              ],
            ),
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

  void _openSources(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SourcesScreen()));
  }

  /// Says why the demo is unavailable instead of letting the tap fall on the
  /// floor. The subtitle under the button already states the requirement;
  /// this is for the user who tapped anyway.
  void _policyRequired() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(S.of(context).onboardingBlockedDemoPolicySnack)),
      );
  }

  /// Seeds the active profile with sample data and jumps straight to Home.
  /// Requires the privacy-policy checkbox (same bar as Start) so demo entry
  /// still records legal acceptance; anonymous crash reporting stays off
  /// unless the user opts in later from Settings (and is locked while demo
  /// data is active). Data-collection checkbox is intentionally independent.
  Future<void> _tryDemo() async {
    if (!_acceptedPolicy) return;
    setState(() => _seedingDemo = true);
    try {
      await seedDemoData(DemoSeedOptions.onboarding);
      if (!mounted) return;
      // The screen-persistent tab BLoCs were created before the demo profile
      // existed (or hold another profile's data). Refresh them against the
      // freshly seeded active profile before landing on the main screen —
      // same as the normal onboarding start path (onboarding_screen.dart).
      ProfileSwitchCoordinator.reloadTabBlocs();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(NavigationOptions.mainRoute, (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _seedingDemo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).onboardingTryDemoError)),
      );
    }
  }

  Future<void> _launchUrl() async {
    // Read the locale before the await; the context must not be touched
    // afterwards without a mounted check.
    final policy = URLConst.privacyPolicyFor(
      Localizations.localeOf(context).languageCode,
    );

    // A device with no browser is the case worth reporting: this link is the
    // only way to read the policy the checkbox below asks you to accept, and
    // silently doing nothing reads as a broken tap.
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(policy),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      // No activity able to handle the intent — a failure to open, not a crash.
      opened = false;
    }

    if (opened || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).errorOpeningBrowser)));
  }
}
