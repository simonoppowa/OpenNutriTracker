import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ExportImportDialog extends StatelessWidget {
  final exportImportBloc = locator<ExportImportBloc>();

  final _homeBloc = locator<HomeBloc>();
  final _diaryBloc = locator<DiaryBloc>();
  final _calendarDayBloc = locator<CalendarDayBloc>();

  ExportImportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).exportImportLabel,
          overflow: TextOverflow.ellipsis, maxLines: 2),
      content: Wrap(children: [
        Column(
          children: [
            BlocBuilder<ExportImportBloc, ExportImportState>(
                bloc: exportImportBloc,
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
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 8),
                        Text(
                          S.of(context).exportImportSuccessLabel,
                        ),
                      ],
                    );
                  } else if (state is ExportImportError) {
                    return Row(
                      children: [
                        Icon(Icons.error,
                            color: Theme.of(context).colorScheme.error),
                        SizedBox(width: 8),
                        Text(
                          S.of(context).exportImportErrorLabel,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
          ],
        ),
      ]),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            exportImportBloc.add(ExportDataEvent());
          },
          child: Text(S.of(context).exportAction),
        ),
        TextButton(
          onPressed: () {
            exportImportBloc.add(ImportDataEvent());
          },
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
