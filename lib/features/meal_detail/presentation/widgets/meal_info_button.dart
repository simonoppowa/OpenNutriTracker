import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class MealInfoButton extends StatelessWidget {
  final String? url;
  final MealSourceEntity source;

  /// Backend food_source.code for Supabase foods ('fdc_sr_legacy',
  /// 'bls'...); lets the button name the actual database instead of the
  /// generic FoodData Central label. Null for OFF/custom meals and
  /// legacy cached entries.
  final String? backendSource;

  const MealInfoButton({
    super.key,
    required this.url,
    required this.source,
    this.backendSource,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TextButton.icon(
      onPressed: () => _launchUrl(_getInfoUrl()),
      icon: Icon(Icons.open_in_new_rounded, size: 20, color: accent),
      label: Text(
        _getInfoLabelText(context),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getInfoUrl() {
    String siteUrl;
    switch (source) {
      case MealSourceEntity.unknown:
        siteUrl = "";
        break;
      case MealSourceEntity.custom:
        siteUrl = "";
        break;
      case MealSourceEntity.off:
        siteUrl = url ?? OFFConst.offWebsiteUrl;
        break;
      case MealSourceEntity.fdc:
        // Foods without a per-item detail page (BLS, INDB, TBCA...) link
        // to their database's website instead.
        siteUrl = url ??
            SPConst.foodSourceWebsites[backendSource] ??
            FDCConst.fdcWebsiteUrl;
        break;
      case MealSourceEntity.recipe:
        siteUrl = "";
        break;
    }
    return siteUrl;
  }

  String _getInfoLabelText(BuildContext context) {
    String infoLabel;
    switch (source) {
      case MealSourceEntity.unknown:
        infoLabel = S.of(context).additionalInfoLabelUnknown;
        break;
      case MealSourceEntity.custom:
        infoLabel = S.of(context).additionalInfoLabelCustom;
        break;
      case MealSourceEntity.off:
        infoLabel = S.of(context).additionalInfoLabelOFF;
        break;
      case MealSourceEntity.fdc:
        final sourceName = SPConst.foodSourceDisplayNames[backendSource];
        infoLabel = sourceName != null
            ? S.of(context).additionalInfoLabelSource(sourceName)
            : S.of(context).additionalInfoLabelFDC;
        break;
      case MealSourceEntity.recipe:
        infoLabel = S.of(context).additionalInfoLabelRecipe;
        break;
    }
    return infoLabel;
  }

  Future<void> _launchUrl(String siteUrl) async {
    if (!await launchUrl(
      Uri.parse(siteUrl),
      mode: LaunchMode.externalApplication,
    )) {}
  }
}
