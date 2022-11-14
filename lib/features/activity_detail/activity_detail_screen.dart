import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_info_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({Key? key}) : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late PhysicalActivityEntity activityEntity;
  late TextEditingController quantityTextController;

  final activityDetailBloc = ActivityDetailBloc();

  late double totalQuantity;
  late double totalKcal;

  @override
  void initState() {
    quantityTextController = TextEditingController();
    quantityTextController.text = "60";
    totalQuantity = 60;
    totalKcal = 0;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments
        as ActivityDetailScreenArguments;
    activityEntity = args.activityEntity;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activityEntity.getName(context)),
      ),
      body: ListView(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer),
            child: Icon(
              activityEntity.displayIcon,
              size: 48,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('~${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headline5),
                    Text(' / ${totalQuantity.toInt()} min')
                  ],
                ),
                const SizedBox(height: 8.0),
                const Divider(),
                const SizedBox(height: 48.0),
                const ActivityInfoButton(),
                const SizedBox(height: 200.0) // height added to scroll
              ],
            ),
          )
        ],
      ),
      bottomSheet: ActivityDetailBottomSheet(
        quantityTextController: quantityTextController,
        activityEntity: activityEntity,
        activityDetailBloc: activityDetailBloc,
      ),
    );
  }
}

class ActivityDetailScreenArguments {
  final PhysicalActivityEntity activityEntity;

  ActivityDetailScreenArguments(this.activityEntity);
}
