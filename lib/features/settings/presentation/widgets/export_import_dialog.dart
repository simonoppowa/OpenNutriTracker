import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Export / Import App Data dialog. A SegmentedButton at the top picks
/// which format the user is working with — JSON (the canonical
/// backup-and-restore format the app round-trips through) or CSV (a
/// spreadsheet-friendly view).
///
/// Both segments support Export and Import. The asymmetry is that CSV
/// export omits recipes (the nested-ingredient shape doesn't flatten
/// cleanly) and CSV import therefore doesn't restore recipes either —
/// a user who wants their recipes in a backup should pick JSON.
class ExportImportDialog extends StatefulWidget {
  const ExportImportDialog({super.key});

  @override
  State<ExportImportDialog> createState() => _ExportImportDialogState();
}

class _ExportImportDialogState extends State<ExportImportDialog> {
  final _exportImportBloc = locator<ExportImportBloc>();
  final _homeBloc = locator<HomeBloc>();
  final _diaryBloc = locator<DiaryBloc>();
  final _calendarDayBloc = locator<CalendarDayBloc>();

  ExportFormat _exportFormat = ExportFormat.json;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        S.of(context).exportImportAppDataLabel,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      content: Wrap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ExportFormat>(
                segments: const [
                  ButtonSegment(
                    value: ExportFormat.json,
                    label: Text('JSON'),
                  ),
                  ButtonSegment(
                    value: ExportFormat.csv,
                    label: Text('CSV'),
                  ),
                ],
                selected: {_exportFormat},
                onSelectionChanged: (next) {
                  setState(() => _exportFormat = next.first);
                  // Clear any success/error chrome left over from a
                  // previous export so the description re-appears under
                  // the new format selection.
                  _exportImportBloc.add(ResetExportImportStateEvent());
                },
              ),
              if (_exportFormat == ExportFormat.csv) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        S.of(context).exportImportCsvRecipesNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              BlocBuilder<ExportImportBloc, ExportImportState>(
                bloc: _exportImportBloc,
                builder: (context, state) {
                  if (state is ExportImportInitial) {
                    return Text(
                      S.of(context).exportImportDescription,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 15,
                    );
                  } else if (state is ExportImportLoadingState) {
                    return const LinearProgressIndicator();
                  } else if (state is ExportImportSuccess) {
                    refreshScreens();
                    return Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(S.of(context).exportImportSuccessLabel),
                      ],
                    );
                  } else if (state is ExportImportError) {
                    return Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(S.of(context).exportImportErrorLabel),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => _exportImportBloc.add(
            ExportDataEvent(format: _exportFormat),
          ),
          child: Text(S.of(context).exportAction),
        ),
        TextButton(
          onPressed: () => _exportImportBloc.add(
            ImportDataEvent(format: _exportFormat),
          ),
          child: Text(S.of(context).importAction),
        ),
      ],
    );
  }

  void refreshScreens() {
    _homeBloc.add(const LoadItemsEvent());
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(RefreshCalendarDayEvent());
  }
}
