import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/safe_url_launcher.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ActivityInfoButton extends StatelessWidget {
  const ActivityInfoButton({super.key});

  final url = URLConst.paCompendium2011URL;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _launchUrl(context),
      child: Text(
        S.of(context).additionalInfoLabelCompendium2011,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(decoration: TextDecoration.underline),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context) async {
    // Resolve what the failure path needs before the await; the context must
    // not be touched afterwards.
    final messenger = ScaffoldMessenger.of(context);
    final errorText = S.of(context).errorOpeningBrowser;

    if (await tryLaunchExternalUrl(url)) return;

    messenger.showSnackBar(SnackBar(content: Text(errorText)));
  }
}
