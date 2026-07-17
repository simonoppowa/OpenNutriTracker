import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/activities_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/recent_activities_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/widgets/activity_item_card.dart';
import 'package:opennutritracker/features/add_activity/presentation/widgets/quick_add_activity_bottom_sheet.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _day;

  late ActivitiesBloc _activitiesBloc;
  late RecentActivitiesBloc _recentActivitiesBloc;

  late TabController _tabController;

  @override
  void initState() {
    _activitiesBloc = locator<ActivitiesBloc>();
    _recentActivitiesBloc = locator<RecentActivitiesBloc>();
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)!.settings.arguments
        as AddActivityScreenArguments;
    _day = args.day;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.canvas,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(kToolbarHeight),
        title: Text(
          S.of(context).activityLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Semantics(
            identifier: 'add-activity-quick-add',
            child: TextButton(
              onPressed: _onQuickAddPressed,
              child: Text(S.of(context).quickAddCardLabel),
            ),
          ),
          Semantics(
            identifier: 'add-activity-custom',
            child: IconButton(
              tooltip: S.of(context).customActivityName,
              onPressed: _onCustomActivityPressed,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing12),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: palette.surface,
                prefixIcon: Icon(Icons.search_rounded, color: palette.textMuted),
                hintText: S.of(context).searchLabel,
                border: OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                  borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                  borderSide: BorderSide(color: palette.border, width: Dimens.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: Dimens.borderRadiusM,
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
              onChanged: (String searchString) {
                _activitiesBloc.add(
                  SearchActivitiesEvent(
                    context: context,
                    searchString: searchString,
                  ),
                );
              },
            ),
            const SizedBox(height: Dimens.spacing16),
            TabBar(
              tabs: [
                Tab(text: S.of(context).allItemsLabel),
                Tab(text: S.of(context).recentlyAddedLabel),
              ],
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
            ),
            const SizedBox(height: Dimens.spacing16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      BlocBuilder<ActivitiesBloc, ActivitiesState>(
                        bloc: _activitiesBloc,
                        builder: (context, state) {
                          if (state is ActivitiesInitial) {
                            _activitiesBloc.add(
                              LoadActivitiesEvent(context: context),
                            );
                            return const SizedBox();
                          }
                          if (state is ActivitiesLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is ActivitiesLoadedState) {
                            final physicalActivities = state.activities;
                            return Flexible(
                              child: ListView.builder(
                                itemCount: physicalActivities.length,
                                itemBuilder: (context, index) {
                                  return ActivityItemCard(
                                    physicalActivityEntity:
                                        physicalActivities[index],
                                    day: _day,
                                  );
                                },
                              ),
                            );
                          }
                          if (state is ActivitiesFailedState) {
                            return ErrorDialog(
                              errorText: S.of(context).errorLoadingActivities,
                              onRefreshPressed:
                                  _onActivitiesRefreshButtonPressed,
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      BlocBuilder<RecentActivitiesBloc, RecentActivitiesState>(
                        bloc: _recentActivitiesBloc,
                        builder: (context, state) {
                          if (state is RecentActivitiesInitial) {
                            _recentActivitiesBloc.add(
                              LoadRecentActivitiesEvent(context: context),
                            );
                            return const SizedBox();
                          }
                          if (state is RecentActivitiesLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is RecentActivitiesLoadedState) {
                            final recentActivities = state.recentActivities;
                            return state.recentActivities.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                      itemCount: recentActivities.length,
                                      itemBuilder: (context, index) {
                                        return ActivityItemCard(
                                          physicalActivityEntity:
                                              recentActivities[index],
                                          day: _day,
                                        );
                                      },
                                    ),
                                  )
                                : const NoResultsWidget();
                          }
                          if (state is RecentActivitiesFailedState) {
                            return ErrorDialog(
                              errorText: S.of(context).errorLoadingActivities,
                              onRefreshPressed:
                                  _onRecentActivitiesRefreshButtonPressed,
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQuickAddPressed() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => QuickAddActivityBottomSheet(day: _day),
    );
  }

  void _onCustomActivityPressed() {
    Navigator.of(context).pushNamed(
      NavigationOptions.activityDetailRoute,
      arguments: ActivityDetailScreenArguments(
        PhysicalActivityEntity.custom,
        _day,
      ),
    );
  }

  void _onActivitiesRefreshButtonPressed() {
    _activitiesBloc.add(LoadActivitiesEvent(context: context));
  }

  void _onRecentActivitiesRefreshButtonPressed() {
    _recentActivitiesBloc.add(LoadRecentActivitiesEvent(context: context));
  }
}

class AddActivityScreenArguments {
  final DateTime day;

  AddActivityScreenArguments({required this.day});
}
