import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/meal_Intake_list.dart';
import 'package:opennutritracker/generated/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeBloc = HomeBloc();
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: homeBloc,
      builder: (context, state) {
        if (state is HomeInitial) {
          homeBloc.add(LoadItemsEvent(context: context));
          return _getLoadingContent();
        } else if (state is HomeLoadingState) {
          return _getLoadingContent();
        } else if (state is HomeLoadedState) {
          return _getLoadedContent(
              context,
              state.breakfastIntakeList,
              state.lunchIntakeList,
              state.dinnerIntakeList,
              state.snackIntakeList);
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
      List<IntakeEntity> breakfastIntakeList,
      List<IntakeEntity> lunchIntakeList,
      List<IntakeEntity> dinnerIntakeList,
      List<IntakeEntity> snackIntakeList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
      child: ListView(children: [
        const DashboardWidget(),
        MealIntakeList(
            title: S.of(context).breakfastLabel,
            intakeList: breakfastIntakeList),
        MealIntakeList(
            title: S.of(context).lunchLabel, intakeList: lunchIntakeList),
        MealIntakeList(
            title: S.of(context).dinnerLabel, intakeList: dinnerIntakeList),
        MealIntakeList(
            title: S.of(context).snackLabel, intakeList: snackIntakeList)
      ]),
    );
  }
}