import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// Import flow for user-supplied food data. A SegmentedButton at the top
/// lets the user pick whether they're working with CSV files (meals or
/// recipes, with sample downloads) or pasting a JSON blob (with its own
/// sample). Keeping both formats under one Settings entry — rather than
/// surfacing CSV and JSON as separate top-level rows — keeps the data
/// section of Settings short and gives the two paths room to share the
/// same explanatory copy.
enum _ImportFormat { csv, json }

class ImportCustomFoodDataDialog extends StatefulWidget {
  const ImportCustomFoodDataDialog({super.key});

  @override
  State<ImportCustomFoodDataDialog> createState() =>
      _ImportCustomFoodDataDialogState();
}

class _ImportCustomFoodDataDialogState
    extends State<ImportCustomFoodDataDialog> {
  static final _offAndroidUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=org.openfoodfacts.scanner');
  static final _offIosUrl = Uri.parse(
      'https://apps.apple.com/us/app/open-food-facts-product-scan/id588797948');

  final _exportImportBloc = locator<ExportImportBloc>();
  final _homeBloc = locator<HomeBloc>();
  final _diaryBloc = locator<DiaryBloc>();
  final _calendarDayBloc = locator<CalendarDayBloc>();

  _ImportFormat _selectedFormat = _ImportFormat.csv;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        S.of(context).importCustomFoodDataLabel,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      content: Wrap(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                identifier: 'import-format-toggle',
                child: SegmentedButton<_ImportFormat>(
                  segments: const [
                    ButtonSegment(
                      value: _ImportFormat.csv,
                      label: Text('CSV'),
                    ),
                    ButtonSegment(
                      value: _ImportFormat.json,
                      label: Text('JSON'),
                    ),
                  ],
                  selected: {_selectedFormat},
                  onSelectionChanged: (next) {
                    setState(() {
                      _selectedFormat = next.first;
                    });
                    // Reset bloc chrome so a CSV success message doesn't
                    // linger when the user flips to JSON, and vice versa.
                    _exportImportBloc.add(ResetExportImportStateEvent());
                  },
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<ExportImportBloc, ExportImportState>(
                bloc: _exportImportBloc,
                builder: (context, state) {
                  if (state is ExportImportInitial) {
                    return Text(
                      S.of(context).importCustomFoodDataDescription,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 15,
                    );
                  } else if (state is ExportImportLoadingState) {
                    return const LinearProgressIndicator();
                  } else if (state is ExportImportSuccess) {
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
                  } else if (state is CsvImportResultState) {
                    refreshScreens();
                    return _buildCsvResult(context, state);
                  } else if (state is RecipeCsvImportResultState) {
                    refreshScreens();
                    locator<RecipesBloc>().add(const LoadRecipesEvent());
                    final summary = state.skipped == 0
                        ? S
                            .of(context)
                            .csvImportSuccessLabel(state.imported)
                        : S
                            .of(context)
                            .csvImportPartialLabel(
                              state.imported,
                              state.skipped,
                            );
                    return Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(summary)),
                      ],
                    );
                  } else if (state is CsvImportErrorState) {
                    return _errorRow(
                        context, S.of(context).csvImportErrorLabel);
                  } else if (state is JsonImportResultState) {
                    refreshScreens();
                    final summary = state.errorMessages.isEmpty
                        ? S.of(context).csvImportSuccessLabel(state.imported)
                        : S.of(context).csvImportPartialLabel(
                              state.imported,
                              state.errorMessages.length,
                            );
                    return _successColumnWithErrors(
                      context,
                      summary,
                      state.errorMessages,
                    );
                  } else if (state is JsonImportErrorState) {
                    return _errorColumnWithMessages(
                      context,
                      state.errorMessages,
                    );
                  } else if (state is RecipeJsonImportResultState) {
                    refreshScreens();
                    locator<RecipesBloc>().add(const LoadRecipesEvent());
                    final summary = state.skipped == 0
                        ? S.of(context).csvImportSuccessLabel(state.imported)
                        : S.of(context).csvImportPartialLabel(
                              state.imported,
                              state.skipped,
                            );
                    return _successColumnWithErrors(
                      context,
                      summary,
                      state.errorMessages,
                    );
                  } else if (state is RecipeJsonImportErrorState) {
                    return _errorColumnWithMessages(
                      context,
                      state.errorMessages,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      actions: _selectedFormat == _ImportFormat.csv
          ? _buildCsvActions(context)
          : _buildJsonActions(context),
    );
  }

  List<Widget> _buildCsvActions(BuildContext context) {
    return <Widget>[
      TextButton(
        onPressed: () => _exportImportBloc.add(DownloadSampleCsvEvent()),
        child: Text(S.of(context).downloadSampleCsvAction),
      ),
      TextButton(
        onPressed: () => _exportImportBloc.add(ImportMealsCsvEvent()),
        child: Text(S.of(context).importMealsCsvAction),
      ),
      TextButton(
        onPressed: () =>
            _exportImportBloc.add(DownloadSampleRecipesCsvEvent()),
        child: Text(S.of(context).downloadSampleRecipesCsvAction),
      ),
      TextButton(
        onPressed: () => _exportImportBloc.add(ImportRecipesCsvEvent()),
        child: Text(S.of(context).importRecipesCsvAction),
      ),
    ];
  }

  List<Widget> _buildJsonActions(BuildContext context) {
    return <Widget>[
      TextButton(
        onPressed: () => _exportImportBloc.add(DownloadSampleJsonEvent()),
        child: Text(S.of(context).downloadSampleJsonAction),
      ),
      TextButton(
        onPressed: () => _exportImportBloc.add(ImportMealsJsonEvent()),
        child: Text(S.of(context).importMealsJsonAction),
      ),
      TextButton(
        onPressed: () =>
            _exportImportBloc.add(DownloadSampleRecipesJsonEvent()),
        child: Text(S.of(context).downloadSampleRecipesJsonAction),
      ),
      TextButton(
        onPressed: () => _exportImportBloc.add(ImportRecipesJsonEvent()),
        child: Text(S.of(context).importRecipesJsonAction),
      ),
    ];
  }

  Widget _buildCsvResult(BuildContext context, CsvImportResultState state) {
    final summary = state.skipped == 0
        ? S.of(context).csvImportSuccessLabel(state.imported)
        : S
            .of(context)
            .csvImportPartialLabel(state.imported, state.skipped);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(summary)),
          ],
        ),
        if (state.anyHadBarcode) ...[
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: S.of(context).csvImportContributeOffPrefix,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: S.of(context).csvImportContributeOffAndroidLink,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(_offAndroidUrl,
                        mode: LaunchMode.externalApplication),
                ),
                const TextSpan(text: ' / '),
                TextSpan(
                  text: S.of(context).csvImportContributeOffIosLink,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(_offIosUrl,
                        mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _errorRow(BuildContext context, String message) {
    return Row(
      children: [
        Icon(Icons.error, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }

  /// Result-with-errors layout used by JSON imports. The top row is the
  /// success summary (X imported), and beneath it any per-entry parse
  /// errors are listed so the user can see exactly which inputs were
  /// rejected. [errors] may be empty, in which case only the summary
  /// row renders.
  Widget _successColumnWithErrors(
    BuildContext context,
    String summary,
    List<String> errors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(summary)),
          ],
        ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final err in errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                err,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
        ],
      ],
    );
  }

  /// All entries failed — show the parse errors as a list rather than a
  /// single message, so the user can fix each one without guessing which
  /// row in the JSON tripped the importer.
  Widget _errorColumnWithMessages(
    BuildContext context,
    List<String> errors,
  ) {
    if (errors.isEmpty) {
      return _errorRow(context, S.of(context).csvImportErrorLabel);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final err in errors)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    err,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
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
