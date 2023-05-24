import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/activities_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/widgets/activity_item_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({Key? key}) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final ActivitiesBloc _activitiesBloc = ActivitiesBloc();

  late List<PhysicalActivityEntity> _physicalActivities;
  late List<PhysicalActivityEntity> _activitySuggestions;

  @override
  void didChangeDependencies() {
    _physicalActivities = _activitiesBloc.getPhysicalActivity(context);
    _activitySuggestions = _physicalActivities;
    super.didChangeDependencies();
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
                onChanged: _onSearchTextChanged,
              ),
            ),
            const SizedBox(height: 16.0),
            Flexible(
              child: ListView.builder(
                  itemCount: _activitySuggestions.length,
                  itemBuilder: (context, index) {
                    return ActivityItemCard(
                        physicalActivityEntity: _activitySuggestions[index]);
                  }),
            ),
          ],
        ));
  }

  void _onSearchTextChanged(String query) {
    setState(() {
      if (query == "") {
        _activitySuggestions = _physicalActivities;
      } else {
        final formattedQuery = query.toLowerCase();
        _activitySuggestions = _physicalActivities.where((activity) {
          final formattedActivityName = activity.getName(context).toLowerCase();
          final formattedActivityDescription =
              activity.getDescription(context).toLowerCase();
          final containsQuery =
              formattedActivityName.contains(formattedQuery) ||
                  formattedActivityDescription.contains(formattedQuery);

          return containsQuery;
        }).toList();
      }
    });
  }
}
