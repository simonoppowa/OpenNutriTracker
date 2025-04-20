import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_info_button.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_title_expanded.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  static const _containerSize = 250.0;

  final log = Logger('ItemDetailScreen');
  final _scrollController = ScrollController();

  late PhysicalActivityEntity activityEntity;
  late DateTime _day;
  late TextEditingController quantityTextController;

  late ActivityDetailBloc _activityDetailBloc;

  late double totalQuantity;
  late double totalKcal;

  @override
  void initState() {
    _activityDetailBloc = locator<ActivityDetailBloc>();
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
    _day = args.day;
    quantityTextController.addListener(() {});
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ActivityDetailBloc, ActivityDetailState>(
        bloc: _activityDetailBloc,
        builder: (context, state) {
          if (state is ActivityDetailInitial) {
            _activityDetailBloc
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
        activityDetailBloc: _activityDetailBloc,
      ),
    );
  }

  Widget getLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget getLoadedContent(double totalKcalBurned, UserEntity userEntity) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                final barsHeight =
                    MediaQuery.of(context).padding.top + kToolbarHeight;
                const offset = 10;
                return FlexibleSpaceBar(
                  expandedTitleScale: 1, // don't scale title
                  background: ActivityTitleExpanded(activity: activityEntity),
                  title: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child:
                        top > barsHeight - offset && top < barsHeight + offset
                            ? Text(activityEntity.getName(context),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface))
                            : const SizedBox(),
                  ),
                );
              },
            )),
        SliverList(
            delegate: SliverChildListDelegate([
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: Container(
                width: _containerSize,
                height: _containerSize,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer),
                child: Icon(
                  activityEntity.displayIcon,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // set Focus
                    Text('~${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headlineSmall),
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
        ]))
      ],
    );
  }

  void _onQuantityChanged(String quantityString, UserEntity userEntity) async {
    try {
      final newQuantity = double.parse(quantityString);
      final newTotalKcal = _activityDetailBloc.getTotalKcalBurned(
          userEntity, activityEntity, newQuantity);
      setState(() {
        totalQuantity = newQuantity;
        totalKcal = newTotalKcal;
        scrollToCalorieText();
      });
    } on FormatException catch (_) {
      log.warning("Error while parsing: \"$quantityString\"");
    }
  }

  void scrollToCalorieText() {
    _scrollController.animateTo(_containerSize,
        duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  void onAddButtonPressed(BuildContext context) {
    _activityDetailBloc.persistActivity(
        context, quantityTextController.text, totalKcal, activityEntity, _day);

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).infoAddedActivityLabel)));
    Navigator.of(context)
        .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }
}

class ActivityDetailScreenArguments {
  final PhysicalActivityEntity activityEntity;
  final DateTime day;

  ActivityDetailScreenArguments(this.activityEntity, this.day);
}
