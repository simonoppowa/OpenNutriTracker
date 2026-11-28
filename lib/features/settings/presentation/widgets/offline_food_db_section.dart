import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/offline_food_db/offline_food_db.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Status of the offline food database, with Download/Update, Cancel and
/// Remove. The state lives on [OfflineFoodDb], so a download keeps going —
/// and is shown again — when the user leaves the screen and comes back.
class OfflineFoodDbSection extends StatelessWidget {
  const OfflineFoodDbSection({super.key, this.database});

  /// The database to show; the app's registered one by default.
  final OfflineFoodDb? database;

  OfflineFoodDb get _db => database ?? locator<OfflineFoodDb>();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final db = _db;
    return ValueListenableBuilder<OfflineFoodDbState>(
      valueListenable: db.state,
      builder: (context, state, _) {
        final info = state.info;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                s.offlineFoodDbTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.offlineFoodDbDescription,
                style: theme.textTheme.bodySmall,
              ),
            ),
            ListTile(
              leading: Icon(
                info == null
                    ? Icons.cloud_download_outlined
                    : Icons.offline_pin_outlined,
              ),
              title: Text(
                info == null
                    ? s.offlineFoodDbNotInstalled
                    : s.offlineFoodDbInstalled,
              ),
              subtitle: info == null
                  ? null
                  : Text(
                      '${_details(context, info)}\n${s.offlineFoodDbActive}',
                    ),
              isThreeLine: info != null,
            ),
            if (state.busy) _progress(context, state),
            if (state.failed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s.offlineFoodDbFailed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.busy)
                    Semantics(
                      identifier: 'food-sources-offline-cancel',
                      child: OutlinedButton(
                        onPressed: db.cancel,
                        child: Text(s.offlineFoodDbCancelDownload),
                      ),
                    )
                  else
                    Semantics(
                      identifier: 'food-sources-offline-download',
                      child: FilledButton.tonalIcon(
                        onPressed: db.download,
                        icon: const Icon(Icons.download_outlined),
                        label: Text(
                          info == null
                              ? s.offlineFoodDbDownload
                              : s.offlineFoodDbUpdate,
                        ),
                      ),
                    ),
                  if (info != null) ...[
                    Semantics(
                      identifier: 'food-sources-offline-sources',
                      child: TextButton(
                        onPressed: state.busy
                            ? null
                            : () => _showSources(context, db),
                        child: Text(s.offlineFoodDbSources),
                      ),
                    ),
                    Semantics(
                      identifier: 'food-sources-offline-remove',
                      child: TextButton(
                        onPressed: state.busy
                            ? null
                            : () => _confirmRemove(context, db),
                        child: Text(s.offlineFoodDbRemove),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _details(BuildContext context, OfflineFoodDbInfo info) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = info.buildDate == null
        ? '—'
        : DateFormat.yMMMd(locale).format(info.buildDate!.toLocal());
    return S
        .of(context)
        .offlineFoodDbDetails(
          date,
          _megabytes(locale, info.sizeBytes),
          NumberFormat.decimalPattern(locale).format(info.foodCount),
        );
  }

  static String _megabytes(String locale, int bytes) =>
      '${NumberFormat('0.0', locale).format(bytes / (1024 * 1024))} MB';

  Widget _progress(BuildContext context, OfflineFoodDbState state) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final total = state.total;
    final downloading = state.phase == OfflineFoodDbPhase.downloading;
    final received = _megabytes(locale, state.received);
    final amount = total == null
        ? received
        : s.offlineFoodDbDownloadProgress(received, _megabytes(locale, total));
    final label = downloading
        ? '${s.offlineFoodDbDownloading} $amount'
        : s.offlineFoodDbVerifying;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: downloading && total != null && total > 0
                ? state.received / total
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, OfflineFoodDb db) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.offlineFoodDbRemoveTitle),
        content: Text(s.offlineFoodDbRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.offlineFoodDbRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) await db.remove();
  }

  /// The licence notes the database carries, which CC BY asks to show.
  Future<void> _showSources(BuildContext context, OfflineFoodDb db) {
    final s = S.of(context);
    final sources = db.sources();
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.offlineFoodDbSources),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final source in sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (source.licence != null)
                        Text(
                          source.licence!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.dialogCloseLabel),
          ),
        ],
      ),
    );
  }
}
