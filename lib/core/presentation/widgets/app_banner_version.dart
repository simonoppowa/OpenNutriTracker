import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AppBannerVersion extends StatelessWidget {
  const AppBannerVersion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Version name needs future
      future: _getVersionNumber(context),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 90,
                    child: Image.asset('assets/icon/ont_banner_top.png'),
                  ),
                ],
              ),
              Text(
                S.of(context).appVersionName(snapshot.requireData),
                style: Theme.of(context).textTheme.titleMedium,
              )
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Future<String> _getVersionNumber(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
