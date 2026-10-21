import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_client.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/features/off_contribution/domain/off_nutrition_upload.dart';
import 'package:opennutritracker/features/scanner/data/nutrition_label_scanner.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Offers to send the nutrition values of a scanned and saved food to Open
/// Food Facts (#81): only when switched on in the settings, only after the
/// user saw and confirmed what goes out, and never over values Open Food
/// Facts already has. The food is saved before this runs, so a failed
/// upload never costs the local entry; it can be retried from the message.
///
/// With the photo of the table (#112) the dialog offers to send it as well,
/// unticked by default; a ticked photo also goes out when Open Food Facts
/// already has values, since it overwrites nothing. The flow owns the photo and deletes it on every
/// path: switched off, not sent, sent without it, after its upload, and
/// after a failure once the message closes without a retry.
class OffContributionFlow {
  final OffContributionSettingsStore _store;
  final OffContributionClient _client;

  OffContributionFlow(this._store, this._client);

  /// Whether uploads are set up, so a scanned photo is worth keeping.
  Future<bool> isReady() async => (await _store.load()).isReady;

  /// Returns once the user decided; a confirmed upload carries on in the
  /// background and reports through the app's snackbar.
  Future<void> offer(
    BuildContext context,
    String barcode,
    MealNutrimentsEntity nutriments, {
    LabelPhoto? photo,
  }) async {
    final settings = await _store.load();
    final upload = OffNutritionUpload.fromNutriments(barcode, nutriments);
    if (!settings.isReady || !context.mounted || !upload.hasValues) {
      await photo?.delete();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = S.of(context);
    final choice = await showDialog<({bool withPhoto})>(
      context: context,
      builder: (dialogContext) => _UploadPreviewDialog(
        upload: upload,
        settings: settings,
        hasPhoto: photo != null,
      ),
    );
    final kept = choice != null && choice.withPhoto ? photo : null;
    if (kept == null) await photo?.delete();
    if (choice == null) return;
    unawaited(_send(messenger, l10n, upload, kept));
  }

  /// Sends [upload] and then [photo] with the settings as they are now, so
  /// a retry after changing the account or the server uses the new ones.
  /// [valuesSent] skips the values on a retry after they already went out.
  Future<void> _send(
    ScaffoldMessengerState messenger,
    S l10n,
    OffNutritionUpload upload,
    LabelPhoto? photo, {
    bool valuesSent = false,
  }) async {
    final settings = await _store.load();
    if (!settings.isReady) {
      await photo?.delete();
      return;
    }
    var sent = valuesSent;
    String message;
    SnackBarAction? retry;
    try {
      final valuesThere =
          !sent && await _client.hasNutritionValues(settings, upload.barcode);
      if (!sent && !valuesThere) {
        await _client.upload(settings, upload);
        sent = true;
      }
      final photoSent = photo != null && await _sendPhoto(settings, upload, photo);
      message = switch ((valuesThere, photoSent)) {
        (true, true) => l10n.offUploadOnlyPhoto,
        (true, false) => l10n.offUploadAlreadyThere,
        (false, _) => l10n.offUploadDone,
      };
    } on OffContributionException catch (error) {
      message = switch (error.failure) {
        OffContributionFailure.offline => l10n.offUploadOffline,
        OffContributionFailure.rejected => l10n.offUploadRejected,
        OffContributionFailure.serverBusy => l10n.offUploadBusy,
      };
      retry = SnackBarAction(
        label: l10n.offUploadRetry,
        onPressed: () => unawaited(
          _send(messenger, l10n, upload, photo, valuesSent: sent),
        ),
      );
    }
    final shown = messenger.showSnackBar(
      SnackBar(content: Text(message), action: retry),
    );
    if (photo == null) return;
    if (retry == null) {
      await photo.delete();
    } else {
      unawaited(
        shown.closed.then((reason) async {
          if (reason != SnackBarClosedReason.action) await photo.delete();
        }),
      );
    }
  }

  /// Uploads [photo]; false when it can no longer be read (the system may
  /// have emptied its temporary folder), in which case it is skipped.
  Future<bool> _sendPhoto(
    OffContributionSettings settings,
    OffNutritionUpload upload,
    LabelPhoto photo,
  ) async {
    final List<int> bytes;
    try {
      bytes = await photo.read();
    } on FileSystemException {
      return false;
    }
    await _client.uploadNutritionPhoto(
      settings,
      upload.barcode,
      bytes,
      photo.fileName,
    );
    return true;
  }
}

class _UploadPreviewDialog extends StatefulWidget {
  final OffNutritionUpload upload;
  final OffContributionSettings settings;
  final bool hasPhoto;

  const _UploadPreviewDialog({
    required this.upload,
    required this.settings,
    required this.hasPhoto,
  });

  @override
  State<_UploadPreviewDialog> createState() => _UploadPreviewDialogState();
}

class _UploadPreviewDialogState extends State<_UploadPreviewDialog> {
  bool _withPhoto = false;

  @override
  Widget build(BuildContext context) {
    final upload = widget.upload;
    final settings = widget.settings;
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
            if (widget.hasPhoto) ...[
              Semantics(
                identifier: 'off-upload-photo',
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _withPhoto,
                  onChanged: (value) =>
                      setState(() => _withPhoto = value ?? false),
                  title: Text(l10n.offUploadPhotoCheckbox),
                ),
              ),
              Text(l10n.offUploadPhotoLicense, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        Semantics(
          identifier: 'off-upload-skip',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.offUploadSkip),
          ),
        ),
        Semantics(
          identifier: 'off-upload-send',
          child: FilledButton(
            onPressed: () =>
                Navigator.of(context).pop((withPhoto: _withPhoto)),
            child: Text(l10n.offUploadSend),
          ),
        ),
      ],
    );
  }
}
