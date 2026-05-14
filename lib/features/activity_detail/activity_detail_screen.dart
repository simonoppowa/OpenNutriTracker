import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
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
    quantityTextController.addListener(_onQuantityChanged);
    totalQuantity = 0; // TODO change to 60
    totalKcal = 0;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments
            as ActivityDetailScreenArguments;
    activityEntity = args.activityEntity;
    _day = args.day;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    quantityTextController.removeListener(_onQuantityChanged);
    quantityTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<ActivityDetailBloc, ActivityDetailState>(
          bloc: _activityDetailBloc,
          builder: (context, state) {
            if (state is ActivityDetailInitial) {
              _activityDetailBloc.add(LoadActivityDetailEvent(activityEntity));
              return getLoadingContent();
            } else if (state is ActivityDetailLoadingState) {
              return getLoadingContent();
            } else if (state is ActivityDetailLoadedState) {
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
                  child: top > barsHeight - offset && top < barsHeight + offset
                      ? Text(
                          activityEntity.getName(context),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        )
                      : const SizedBox(),
                ),
              );
            },
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: Container(
                  width: _containerSize,
                  height: _containerSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
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
                      Text(
                        // For Custom activities the user enters kcal directly,
                        // so the leading tilde (which implies an estimate) is
                        // dropped: the figure on screen is exactly what they
                        // typed in.
                        activityEntity.isCustom
                            ? '${totalKcal.toInt()} ${S.of(context).kcalLabel}'
                            : '~${totalKcal.toInt()} ${S.of(context).kcalLabel}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      // For Custom activities the duration line would just
                      // mirror the kcal figure, which is confusing — so we
                      // hide it.
                      if (!activityEntity.isCustom)
                        Text(' / ${totalQuantity.toInt()} min'),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  const Divider(),
                  const SizedBox(height: 48.0),
                  const ActivityInfoButton(),
                  const SizedBox(height: 200.0), // height added to scroll
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  void _onQuantityChanged() {
    final state = _activityDetailBloc.state;
    if (state is! ActivityDetailLoadedState) return;
    try {
      final newQuantity = double.parse(quantityTextController.text);
      final newTotalKcal = _activityDetailBloc.getTotalKcalBurned(
        state.userEntity,
        activityEntity,
        newQuantity,
      );
      setState(() {
        totalQuantity = newQuantity;
        totalKcal = newTotalKcal;
        scrollToCalorieText();
      });
    } on FormatException catch (_) {
      log.warning("Error while parsing: \"${quantityTextController.text}\"");
    }
  }

  void scrollToCalorieText() {
    _scrollController.animateTo(
      _containerSize,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  void onAddButtonPressed(
    BuildContext context, {
    String? templateName,
    bool saveAsTemplate = false,
  }) {
    _activityDetailBloc.persistActivity(
      quantityTextController.text,
      totalKcal,
      activityEntity,
      _day,
    );

    // #70 follow-up: optionally remember the Custom activity as a
    // template the user can recall next time. The checkbox is off by
    // default so we only persist when the user has explicitly opted in
    // and provided a name to find it by later.
    if (saveAsTemplate &&
        activityEntity.isCustom &&
        templateName != null &&
        templateName.isNotEmpty) {
      _activityDetailBloc.saveCustomActivityTemplate(
        CustomActivityTemplateEntity(
          name: templateName,
          typicalKcal: totalKcal,
        ),
      );
    }

    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());

    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).infoAddedActivityLabel)),
    );
    Navigator.of(
      context,
    ).popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
  }
}

class ActivityDetailScreenArguments {
  final PhysicalActivityEntity activityEntity;
  final DateTime day;

  ActivityDetailScreenArguments(this.activityEntity, this.day);
}
