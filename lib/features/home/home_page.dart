import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/dashboard_widget.dart';
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
          return _getLoadedContent(context, state.breakfastIntakeList);
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
      BuildContext context, List<IntakeEntity> intakeEntityList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
      child: ListView(children: [
        const DashboardWidget(),
        Container(
          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            S.of(context).breakfastLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: intakeEntityList.length,
            itemBuilder: (BuildContext context, int index) {
              final intakeEntity = intakeEntityList[index];
              return IntakeCard(
                  intakeName: intakeEntity.product.productName ?? "",
                  subtitle: '${intakeEntity.amount.toString()}${intakeEntity.unit}',
                  kcalText:
                      '${intakeEntity.product.nutriments.energyKcal100?.toInt()} kcal',
                  intakeImageUrl: intakeEntity.product.mainImageUrl);
            },
          ),
        )
      ]),
    );
  }
}
