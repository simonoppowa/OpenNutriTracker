import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Modal bottom sheet for the JSON paste flow (#181). The reporter wanted
/// somewhere lightweight to drop a JSON blob describing one or more
/// meals — for example exported from another tracker, or pasted out of a
/// shared meal-plan doc — and have those entries land in the diary
/// without going through the full add-meal flow.
///
/// The sheet stays open while there are parse errors so the user can fix
/// them in place; on success it closes and the caller surfaces a SnackBar.
class PasteJsonMealsSheet extends StatefulWidget {
  const PasteJsonMealsSheet({super.key});

  @override
  State<PasteJsonMealsSheet> createState() => _PasteJsonMealsSheetState();

  /// Open the sheet on top of [context]. Returns the number of intakes
  /// that were written, or null if the user cancelled / wrote nothing.
  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const PasteJsonMealsSheet(),
      ),
    );
  }
}

class _PasteJsonMealsSheetState extends State<PasteJsonMealsSheet> {
  final _controller = TextEditingController();
  final _bloc = locator<ExportImportBloc>();

  @override
  void initState() {
    super.initState();
    // Reset any lingering success/error chrome from a previous flow so
    // the sheet starts clean each time.
    _bloc.add(ResetExportImportStateEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refreshScreens() {
    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: BlocConsumer<ExportImportBloc, ExportImportState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state is JsonImportResultState) {
              _refreshScreens();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop(state.imported);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    S.of(context).pasteJsonSheetParseSuccess(
                          state.imported,
                          state.savedAsCustomMeals,
                        ),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ExportImportLoadingState;
            final errors = state is JsonImportErrorState
                ? state.errorMessages
                : const <String>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  S.of(context).pasteJsonSheetTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).pasteJsonSheetHelp,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Semantics(
                  identifier: 'paste-json-input',
                  child: TextField(
                    controller: _controller,
                    minLines: 6,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final err in errors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              S.of(context).pasteJsonSheetParseError(err),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Semantics(
                      identifier: 'paste-json-sample',
                      child: TextButton.icon(
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: Text(S.of(context).downloadSampleJsonAction),
                        onPressed: isLoading
                            ? null
                            : () => _bloc.add(DownloadSampleJsonEvent()),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(S.of(context).pasteJsonSheetCancelButton),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      identifier: 'paste-json-submit',
                      child: FilledButton(
                        onPressed: isLoading
                            ? null
                            : () => _bloc.add(
                                PasteJsonMealsEvent(_controller.text)),
                        child: Text(S.of(context).pasteJsonSheetParseButton),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
