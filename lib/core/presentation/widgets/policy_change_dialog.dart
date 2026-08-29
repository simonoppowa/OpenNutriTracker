import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// One-time notice that the privacy policy has materially changed (#887).
///
/// **Not a consent gate, and it must never become one.** There is no
/// checkbox and no "I agree": #874 established that the onboarding tick is an
/// acknowledgement with no legal basis resting on it, and re-gating the app to
/// collect a fresh one would rebuild exactly the problem that finding removed.
/// Dismissing costs a tap and nothing turns on it.
///
/// The substance is in the dialog rather than behind a link, because what a
/// reader needs to know is whether something started happening to them — and
/// the answer is no. The processing never changed; only the description did.
/// Sending someone to a diff to discover that would be a worse answer to a
/// question they can be given directly.
///
/// Shown by `MainScreen`, so it cannot appear during onboarding, where a user
/// is reading the current policy anyway.
class PolicyChangeDialog extends StatelessWidget {
  const PolicyChangeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // The body is several sentences, and German runs longest of the nine.
      // `scrollable` puts the title and content in one scroll view — wrapping
      // only the content is not enough, because it is the dialog's own column
      // that overflows on a short viewport (a 360x320 test overflowed by 40px
      // before this).
      scrollable: true,
      title: Text(S.of(context).policyChangeNoticeTitle),
      content: Text(S.of(context).policyChangeNoticeBody),
      actions: [
        TextButton(
          onPressed: () => _launchPolicy(context),
          child: Text(S.of(context).policyChangeNoticeReadAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).policyChangeNoticeDismissAction),
        ),
      ],
    );
  }

  /// Opens the policy in the user's language, leaving the dialog up.
  ///
  /// Deliberately does not dismiss: the browser opens over the app, and a
  /// notice that vanished while the user was reading would leave them with no
  /// way back to it. The caller records the revision when the dialog closes,
  /// so reading the policy is not what counts as being told.
  Future<void> _launchPolicy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = S.of(context).errorOpeningBrowser;
    final url = Uri.parse(
      URLConst.privacyPolicyFor(Localizations.localeOf(context).languageCode),
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}
