import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_client.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/features/off_contribution/domain/off_nutrition_upload.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Offers to send the nutrition values of a scanned and saved food to Open
/// Food Facts (#81): only when switched on in the settings, only after the
/// user saw and confirmed what goes out, and never over values Open Food
/// Facts already has. The food is saved before this runs, so a failed
/// upload never costs the local entry; it can be retried from the message.
class OffContributionFlow {
  final OffContributionSettingsStore _store;
  final OffContributionClient _client;

  OffContributionFlow(this._store, this._client);

  /// Returns once the user decided; a confirmed upload carries on in the
  /// background and reports through the app's snackbar.
  Future<void> offer(
    BuildContext context,
    String barcode,
    MealNutrimentsEntity nutriments,
  ) async {
    final settings = await _store.load();
    if (!settings.isReady || !context.mounted) return;
    final upload = OffNutritionUpload.fromNutriments(barcode, nutriments);
    if (!upload.hasValues) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = S.of(context);
    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _UploadPreviewDialog(upload: upload, settings: settings),
    );
    if (send != true) return;
    unawaited(_send(messenger, l10n, upload));
  }

  /// Sends [upload] with the settings as they are now, so a retry after
  /// changing the account or the server uses the new ones.
  Future<void> _send(
    ScaffoldMessengerState messenger,
    S l10n,
    OffNutritionUpload upload,
  ) async {
    final settings = await _store.load();
    if (!settings.isReady) return;
    String message;
    SnackBarAction? retry;
    try {
      if (await _client.hasNutritionValues(settings, upload.barcode)) {
        message = l10n.offUploadAlreadyThere;
      } else {
        await _client.upload(settings, upload);
        message = l10n.offUploadDone;
      }
    } on OffContributionException catch (error) {
      message = switch (error.failure) {
        OffContributionFailure.offline => l10n.offUploadOffline,
        OffContributionFailure.rejected => l10n.offUploadRejected,
        OffContributionFailure.serverBusy => l10n.offUploadBusy,
      };
      retry = SnackBarAction(
        label: l10n.offUploadRetry,
        onPressed: () => unawaited(_send(messenger, l10n, upload)),
      );
    }
    messenger.showSnackBar(SnackBar(content: Text(message), action: retry));
  }
}

class _UploadPreviewDialog extends StatelessWidget {
  final OffNutritionUpload upload;
  final OffContributionSettings settings;

  const _UploadPreviewDialog({required this.upload, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final labels = {
      'energy-kcal': l10n.energyLabel,
      'fat': l10n.fatLabel,
      'saturated-fat': l10n.saturatedFatLabel,
      'carbohydrates': l10n.carbsLabel,
      'sugars': l10n.sugarLabel,
      'fiber': l10n.fiberLabel,
      'proteins': l10n.proteinLabel,
      'salt': l10n.offUploadSaltLabel,
    };
    return AlertDialog(
      title: Text(l10n.offUploadDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.offUploadDialogBody(
                upload.barcode,
                settings.useTestServer
                    ? 'world.openfoodfacts.net'
                    : 'world.openfoodfacts.org',
              ),
            ),
            const SizedBox(height: Dimens.spacing8),
            for (final MapEntry(key: name, value: label) in labels.entries)
              if (upload.fields['nutriment_$name'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimens.spacing4,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(label)),
                      Text(
                        '${upload.fields['nutriment_$name']} '
                        '${upload.fields['nutriment_${name}_unit']}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: Dimens.spacing12),
            Text(l10n.offUploadLicense, style: textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        Semantics(
          identifier: 'off-upload-skip',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.offUploadSkip),
          ),
        ),
        Semantics(
          identifier: 'off-upload-send',
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.offUploadSend),
          ),
        ),
      ],
    );
  }
}
