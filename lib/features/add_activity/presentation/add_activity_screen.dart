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

  @override
  void didChangeDependencies() {
    _physicalActivities = _activitiesBloc.getPhysicalActivity(context);
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
            Flexible(
              child: ListView.builder(
                  itemCount: _physicalActivities.length,
                  itemBuilder: (context, index) {
                    return ActivityItemCard(
                        physicalActivityEntity: _physicalActivities[index]);
                  }),
            ),
          ],
        ));
  }
}
