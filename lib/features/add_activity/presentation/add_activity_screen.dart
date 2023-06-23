import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/activities_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/widgets/activity_item_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({Key? key}) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  late ActivitiesBloc _activitiesBloc;

  @override
  void initState() {
    _activitiesBloc = ActivitiesBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).activityLabel),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: S.of(context).searchLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                onChanged: (String searchString) {
                  _activitiesBloc.add(SearchActivitiesEvent(
                      context: context, searchString: searchString));
                },
              ),
            ),
            const SizedBox(height: 16.0),
            BlocBuilder<ActivitiesBloc, ActivitiesState>(
              bloc: _activitiesBloc,
              builder: (context, state) {
                if (state is ActivitiesInitial) {
                  _activitiesBloc.add(LoadActivitiesEvent(context: context));
                  return const SizedBox();
                }
                if (state is ActivitiesLoadingState) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: CircularProgressIndicator(),
                  );
                }
                if (state is ActivitiesLoadedState) {
                  final physicalActivities = state.activities;
                  return Flexible(
                    child: ListView.builder(
                        itemCount: physicalActivities.length,
                        itemBuilder: (context, index) {
                          return ActivityItemCard(
                              physicalActivityEntity:
                                  physicalActivities[index]);
                        }),
                  );
                }
                if (state is ActivitiesFailedState) {
                  return ErrorDialog(
                      errorText: S.of(context).errorLoadingActivities);
                }
                return const SizedBox();
              },
            ),
          ],
        ));
  }
}
