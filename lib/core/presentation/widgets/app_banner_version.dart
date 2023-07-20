import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AppBannerVersion extends StatelessWidget {
  final String versionNumber;

  const AppBannerVersion({Key? key, required this.versionNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 90,
              child: Image.asset(
                  MediaQuery.of(context).platformBrightness == Brightness.light
                      ? 'assets/icon/ont_banner_top.png'
                      : 'assets/icon/ont_banner_top_light.png'),
            ),
          ],
        ),
        Text(
          S.of(context).appVersionName(versionNumber),
          style: Theme.of(context).textTheme.titleMedium,
        )
      ],
    );
  }
}
