import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class MealInfoButton extends StatelessWidget {
  final String? url;
  final ProductSourceEntity source;

  const MealInfoButton({Key? key, required this.url, required this.source})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _launchUrl(_getInfoUrl()),
      child: Text(
        _getInfoLabelText(context),
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(decoration: TextDecoration.underline),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getInfoUrl() {
    String siteUrl;
    switch (source) {
      case ProductSourceEntity.Unknown:
        siteUrl = "";
        break;
      case ProductSourceEntity.OFF:
        siteUrl = url ?? OFFConst.offWebsiteUrl;
        break;
      case ProductSourceEntity.FDC:
        siteUrl = url ?? FDCConst.fdcWebsiteUrl;
        break;
    }
    return siteUrl;
  }

  String _getInfoLabelText(BuildContext context) {
    String infoLabel;
    switch (source) {
      case ProductSourceEntity.Unknown:
        infoLabel = "";
        break;
      case ProductSourceEntity.OFF:
        infoLabel = S.of(context).additionalInfoLabelOFF;
        break;
      case ProductSourceEntity.FDC:
        infoLabel = S.of(context).additionalInfoLabelFDC;
    }
    return infoLabel;
  }

  Future<void> _launchUrl(String siteUrl) async {
    if (!await launchUrl(Uri.parse(siteUrl),
        mode: LaunchMode.externalApplication)) {}
  }
}
