import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/presentation/widgets/weight_vertical_list.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/generated/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final log = Logger('HomePage');

  late HomeBloc _homeBloc;
  bool _isDragging = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _homeBloc = locator<HomeBloc>();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: _homeBloc,
      builder: (context, state) {
        if (state is HomeInitial) {
          _homeBloc.add(const LoadItemsEvent());
          return _getLoadingContent();
        } else if (state is HomeLoadingState) {
          return _getLoadingContent();
        } else if (state is HomeLoadedState) {
          return _getLoadedContent(
              context,
              state.showDisclaimerDialog,
              state.totalKcalDaily,
              state.totalKcalLeft,
              state.totalKcalSupplied,
              state.totalKcalBurned,
              state.totalCarbsIntake,
              state.totalFatsIntake,
              state.totalProteinsIntake,
              state.totalCarbsGoal,
              state.totalFatsGoal,
              state.totalProteinsGoal,
              state.breakfastIntakeList,
              state.lunchIntakeList,
              state.dinnerIntakeList,
              state.snackIntakeList,
              state.userActivityList,
              state.usesImperialUnits);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.info('App resumed');
      _refreshPageOnDayChange();
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget _getLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _getLoadedContent(
      BuildContext context,
      bool showDisclaimerDialog,
      double totalKcalDaily,
      double totalKcalLeft,
      double totalKcalSupplied,
      double totalKcalBurned,
      double totalCarbsIntake,
      double totalFatsIntake,
      double totalProteinsIntake,
      double totalCarbsGoal,
      double totalFatsGoal,
      double totalProteinsGoal,
      List<IntakeEntity> breakfastIntakeList,
      List<IntakeEntity> lunchIntakeList,
      List<IntakeEntity> dinnerIntakeList,
      List<IntakeEntity> snackIntakeList,
      List<UserActivityEntity> userActivities,
      bool usesImperialUnits) {
    if (showDisclaimerDialog) {
      _showDisclaimerDialog(context);
    }

    double weightDaily = 0;

    return Stack(children: [
      ListView(children: [
        DashboardWidget(
          totalKcalDaily: totalKcalDaily,
          totalKcalLeft: totalKcalLeft,
          totalKcalSupplied: totalKcalSupplied,
          totalKcalBurned: totalKcalBurned,
          totalCarbsIntake: totalCarbsIntake,
          totalFatsIntake: totalFatsIntake,
          totalProteinsIntake: totalProteinsIntake,
          totalCarbsGoal: totalCarbsGoal,
          totalFatsGoal: totalFatsGoal,
          totalProteinsGoal: totalProteinsGoal,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).breakfastLabel,
          listIcon: IntakeTypeEntity.breakfast.getIconData(),
          addMealType: AddMealType.breakfastType,
          intakeList: breakfastIntakeList,
          onItemDragCallback: onIntakeItemDrag,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).lunchLabel,
          listIcon: IntakeTypeEntity.lunch.getIconData(),
          addMealType: AddMealType.lunchType,
          intakeList: lunchIntakeList,
          onItemDragCallback: onIntakeItemDrag,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).dinnerLabel,
          addMealType: AddMealType.dinnerType,
          listIcon: IntakeTypeEntity.dinner.getIconData(),
          intakeList: dinnerIntakeList,
          onItemDragCallback: onIntakeItemDrag,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        IntakeVerticalList(
          day: DateTime.now(),
          title: S.of(context).snackLabel,
          listIcon: IntakeTypeEntity.snack.getIconData(),
          addMealType: AddMealType.snackType,
          intakeList: snackIntakeList,
          onItemDragCallback: onIntakeItemDrag,
          onItemTappedCallback: onIntakeItemTapped,
          usesImperialUnits: usesImperialUnits,
        ),
        ActivityVerticalList(
          day: DateTime.now(),
          title: S.of(context).activityLabel,
          userActivityList: userActivities,
          onItemLongPressedCallback: onActivityItemLongPressed,
        ),
        WeightVerticalList(
          day: DateTime.now(),
          title: S.of(context).weightLabel,
          weight: weightDaily,
        ),
        const SizedBox(height: 48.0)
      ]),
      Align(
          alignment: Alignment.bottomCenter,
          child: Visibility(
              visible: _isDragging,
              child: Container(
                height: 70,
                color: Theme.of(context).colorScheme.error
                  ..withValues(alpha: 0.3),
                child: DragTarget<IntakeEntity>(
                  onAcceptWithDetails: (data) {
                    _confirmDelete(context, data.data);
                  },
                  onLeave: (data) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return const Center(
                      child: Icon(
                        Icons.delete_outline,
                        size: 36,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              )))
    ]);
  }

  void onActivityItemLongPressed(
      BuildContext context, UserActivityEntity activityEntity) async {
    final deleteIntake = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (deleteIntake != null) {
      _homeBloc.deleteUserActivityItem(activityEntity);
      _homeBloc.add(const LoadItemsEvent());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
      }
    }
  }

  void onIntakeItemLongPressed(
      BuildContext context, IntakeEntity intakeEntity) async {
    final deleteIntake = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (deleteIntake != null) {
      _homeBloc.deleteIntakeItem(intakeEntity);
      _homeBloc.add(const LoadItemsEvent());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
      }
    }
  }

  void onIntakeItemDrag(bool isDragging) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDragging = isDragging;
      });
    });
  }

  void onIntakeItemTapped(BuildContext context, IntakeEntity intakeEntity,
      bool usesImperialUnits) async {
    final changeIntakeAmount = await showDialog<double>(
        context: context,
        builder: (context) => EditDialog(
            intakeEntity: intakeEntity, usesImperialUnits: usesImperialUnits));
    if (changeIntakeAmount != null) {
      _homeBloc
          .updateIntakeItem(intakeEntity.id, {'amount': changeIntakeAmount});
      _homeBloc.add(const LoadItemsEvent());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).itemUpdatedSnackbar)));
      }
    }
  }

  void _confirmDelete(BuildContext context, IntakeEntity intake) async {
    bool? delete = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (delete == true) {
      _homeBloc.deleteIntakeItem(intake);
      _homeBloc.add(const LoadItemsEvent());
    }
    setState(() {
      _isDragging = false;
    });
  }

  /// Show disclaimer dialog after build method
  void _showDisclaimerDialog(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dialogConfirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return const DisclaimerDialog();
          });
      if (dialogConfirmed != null) {
        _homeBloc.saveConfigData(dialogConfirmed);
        _homeBloc.add(const LoadItemsEvent());
      }
    });
  }

  /// Refresh page when day changes
  void _refreshPageOnDayChange() {
    if (!DateUtils.isSameDay(_homeBloc.currentDay, DateTime.now())) {
      _homeBloc.add(const LoadItemsEvent());
    }
  }
}
