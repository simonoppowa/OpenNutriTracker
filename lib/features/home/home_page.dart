import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_vertial_list.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/meal_Intake_list.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeBloc _homeBloc;

  @override
  void initState() {
    _homeBloc = Provider.of<HomeBloc>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: _homeBloc,
      builder: (context, state) {
        if (state is HomeInitial) {
          _homeBloc.add(LoadItemsEvent(context: context));
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
              state.userActivityList);
        } else {
          return _getLoadingContent();
        }
      },
    );
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
      List<UserActivityEntity> userActivities) {
    if (showDisclaimerDialog) {
      _showDisclaimerDialog(context);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
      child: ListView(children: [
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
        ActivityVerticalList(
            title: S.of(context).activityLabel,
            userActivityList: userActivities),
        MealIntakeList(
          title: S.of(context).breakfastLabel,
          listIcon: Icons.bakery_dining_outlined,
          intakeList: breakfastIntakeList,
          homeBloc: _homeBloc,
        ),
        MealIntakeList(
          title: S.of(context).lunchLabel,
          listIcon: Icons.lunch_dining_outlined,
          intakeList: lunchIntakeList,
          homeBloc: _homeBloc,
        ),
        MealIntakeList(
          title: S.of(context).dinnerLabel,
          listIcon: Icons.dinner_dining_outlined,
          intakeList: dinnerIntakeList,
          homeBloc: _homeBloc,
        ),
        MealIntakeList(
          title: S.of(context).snackLabel,
          listIcon: Icons.icecream_outlined,
          intakeList: snackIntakeList,
          homeBloc: _homeBloc,
        )
      ]),
    );
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
        _homeBloc.saveConfigData(context, dialogConfirmed);
        _homeBloc.add(LoadItemsEvent(context: context));
      }
    });
  }
}
