import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemInfoButton extends StatelessWidget {
  final String url;

  const ItemInfoButton({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _launchUrl,
      child: Text(
        S.of(context).additionalInfoLabelOFF,
        style: Theme.of(context)
            .textTheme
            .subtitle1
            ?.copyWith(decoration: TextDecoration.underline),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {}
  }
}
