import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
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
  final log = Logger('ItemDetailScreen');

  late PhysicalActivityEntity activityEntity;
  late TextEditingController quantityTextController;

  final activityDetailBloc = ActivityDetailBloc();

  late double totalQuantity;
  late double totalKcal;

  @override
  void initState() {
    quantityTextController = TextEditingController();
    quantityTextController.text = "0";
    totalQuantity = 0; // TODO change to 60
    totalKcal = 0;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments
        as ActivityDetailScreenArguments;
    activityEntity = args.activityEntity;
    quantityTextController.addListener(() {});
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activityEntity.getName(context)),
      ),
      body: BlocBuilder<ActivityDetailBloc, ActivityDetailState>(
        bloc: activityDetailBloc,
        builder: (context, state) {
          if (state is ActivityDetailInitial) {
            activityDetailBloc
                .add(LoadActivityDetailEvent(context, activityEntity));
            return getLoadingContent();
          } else if (state is ActivityDetailLoadingState) {
            return getLoadingContent();
          } else if (state is ActivityDetailLoadedState) {
            quantityTextController.addListener(() {
              _onQuantityChanged(quantityTextController.text, state.userEntity);
            });
            return getLoadedContent(state.totalKcalBurned, state.userEntity);
          } else {
            return const SizedBox();
          }
        },
      ),
      bottomSheet: ActivityDetailBottomSheet(
        onAddButtonPressed: onAddButtonPressed,
        quantityTextController: quantityTextController,
        activityEntity: activityEntity,
        activityDetailBloc: activityDetailBloc,
      ),
    );
  }

  Widget getLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget getLoadedContent(double totalKcalBurned, UserEntity userEntity) {
    return ListView(
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
          padding: const EdgeInsets.all(16.0),
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
    );
  }

  void _onQuantityChanged(String quantityString, UserEntity userEntity) async {
    try {
      final newQuantity = double.parse(quantityString);
      final newTotalKcal = activityDetailBloc.getTotalKcalBurned(
          userEntity, activityEntity, newQuantity);
      setState(() {
        totalQuantity = newQuantity;
        totalKcal = newTotalKcal;
      });
    } on FormatException catch (e) {
      log.warning("Error while parsing: \"$quantityString\"");
    }
  }

  void onAddButtonPressed(BuildContext context) {
    activityDetailBloc.persistActivity(
        context, quantityTextController.text, totalKcal, activityEntity);

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(context)
        .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }
}

class ActivityDetailScreenArguments {
  final PhysicalActivityEntity activityEntity;

  ActivityDetailScreenArguments(this.activityEntity);
}
