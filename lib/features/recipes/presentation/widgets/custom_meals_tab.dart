import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Embeddable list of user-created custom meals (formerly the body of
/// CustomMealsScreen in Settings). Hosted inside RecipesPage's TabBarView.
class CustomMealsTab extends StatelessWidget {
  final bool usesImperialUnits;

  const CustomMealsTab({super.key, required this.usesImperialUnits});

  static String _keyFor(MealEntity meal) => meal.code ?? meal.name ?? '';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomMealsBloc, CustomMealsState>(
      listenWhen: (prev, curr) => curr is CustomMealsMergedState,
      listener: (context, state) {
        if (state is CustomMealsMergedState) {
          final s = S.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.rewrittenIntakeCount == 1
                    ? s.customMealsMergeSuccessSnackbarOne(
                        state.winnerDisplayName,
                      )
                    : s.customMealsMergeSuccessSnackbarOther(
                        state.rewrittenIntakeCount,
                        state.winnerDisplayName,
                      ),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CustomMealsLoadingState ||
            state is CustomMealsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CustomMealsLoadedState) {
          if (state.meals.isEmpty) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final palette = isDark ? AppPalette.dark : AppPalette.light;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Dimens.spacing32),
                child: Text(
                  S.of(context).customMealsEmptyLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: palette.textMuted),
                ),
              ),
            );
          }
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final palette = isDark ? AppPalette.dark : AppPalette.light;
          final textTheme = Theme.of(context).textTheme;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Dimens.spacing8),
            itemCount: state.meals.length,
            itemBuilder: (context, index) {
              final meal = state.meals[index];
              final canMerge = state.meals.length >= 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing16, vertical: Dimens.spacing4),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: Dimens.borderRadiusL,
                    onTap: () => _openEditMeal(context, meal),
                    child: Padding(
                      padding: const EdgeInsets.all(Dimens.spacing12),
                      child: Row(
                        children: [
                          _MealLeadingThumbnail(meal: meal),
                          const SizedBox(width: Dimens.spacing12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (meal.brands != null) ...[
                                  const SizedBox(height: Dimens.spacing4),
                                  Text(
                                    meal.brands!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (canMerge)
                            Semantics(
                              identifier: 'custom-foods-merge-open',
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: palette.textMuted),
                                tooltip: S.of(context).customMealsRowMoreTooltip,
                                onSelected: (value) {
                                  if (value == 'merge') {
                                    _startMerge(context, meal, state.meals);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem<String>(
                                    value: 'merge',
                                    child: Text(
                                      S.of(context).customMealsMergeAction,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: palette.textMuted),
                            onPressed: () => _confirmDelete(context, meal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _openEditMeal(BuildContext context, MealEntity meal) async {
    final bloc = context.read<CustomMealsBloc>();
    await Navigator.of(context).pushNamed(
      NavigationOptions.editMealRoute,
      arguments: EditMealScreenArguments(
        DateTime.now(),
        meal,
        IntakeTypeEntity.breakfast,
        usesImperialUnits,
        editOnly: true,
      ),
    );
    bloc.add(LoadCustomMealsEvent());
  }

  Future<void> _confirmDelete(BuildContext context, MealEntity meal) async {
    final bloc = context.read<CustomMealsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).customMealsDeleteConfirmTitle),
        content: Text(S.of(context).customMealsDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(context).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(context).dialogDeleteLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(DeleteCustomMealEvent(meal.code ?? meal.name ?? ''));
    }
  }

  /// Two-step flow: pick the partner to merge with, then choose which of
  /// the two stays as the survivor. The row the menu was opened from is
  /// pre-selected as the survivor so the default behaviour matches the
  /// gesture (you tapped the "good" entry, then picked the duplicate).
  Future<void> _startMerge(
    BuildContext context,
    MealEntity tappedFrom,
    List<MealEntity> allMeals,
  ) async {
    final bloc = context.read<CustomMealsBloc>();
    final candidates = allMeals
        .where((m) => _keyFor(m) != _keyFor(tappedFrom))
        .toList();
    if (candidates.isEmpty) return;

    final partner = await showModalBottomSheet<MealEntity>(
      context: context,
      builder: (ctx) {
        return Semantics(
          identifier: 'custom-foods-merge-picker',
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Dimens.spacing16, Dimens.spacing24, Dimens.spacing16, Dimens.spacing8),
                  child: Text(
                    S.of(context).customMealsMergePickerTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    itemBuilder: (ctx2, i) {
                      final m = candidates[i];
                      return ListTile(
                        leading: _MealLeadingThumbnail(meal: m),
                        title: Text(
                          m.name ?? '',
                          style: Theme.of(ctx2).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: m.brands != null ? Text(m.brands!) : null,
                        onTap: () => Navigator.of(ctx).pop(m),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (partner == null || !context.mounted) return;

    final winner = await _chooseSurvivor(context, tappedFrom, partner);
    if (winner == null || !context.mounted) return;
    final loser = _keyFor(winner) == _keyFor(tappedFrom) ? partner : tappedFrom;

    final confirmed = await _confirmMerge(context, loser: loser, winner: winner);
    if (confirmed != true) return;

    bloc.add(
      MergeCustomMealsEvent(
        loserKey: _keyFor(loser),
        winnerKey: _keyFor(winner),
      ),
    );
  }

  Future<MealEntity?> _chooseSurvivor(
    BuildContext context,
    MealEntity a,
    MealEntity b,
  ) async {
    MealEntity selected = a;
    return showDialog<MealEntity>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) => AlertDialog(
            title: Text(S.of(context).customMealsMergeChooseSurvivorTitle),
            // Flutter 3.32 deprecated the per-tile `groupValue` / `onChanged`
            // pattern in favour of a single `RadioGroup` ancestor that owns
            // the selected value and the change callback. The tiles now
            // just declare their `value`.
            content: RadioGroup<MealEntity>(
              groupValue: selected,
              onChanged: (v) => setState(() => selected = v ?? selected),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    identifier: 'custom-foods-merge-successor-a',
                    child: RadioListTile<MealEntity>(
                      title: Text(a.name ?? ''),
                      value: a,
                    ),
                  ),
                  Semantics(
                    identifier: 'custom-foods-merge-successor-b',
                    child: RadioListTile<MealEntity>(
                      title: Text(b.name ?? ''),
                      value: b,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Semantics(
                identifier: 'custom-foods-merge-cancel',
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(S.of(context).dialogCancelLabel),
                ),
              ),
              Semantics(
                identifier: 'custom-foods-merge-confirm',
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: Text(S.of(context).customMealsMergeContinueAction),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmMerge(
    BuildContext context, {
    required MealEntity loser,
    required MealEntity winner,
  }) {
    final s = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.customMealsMergeConfirmTitle),
        content: Text(
          s.customMealsMergeConfirmContent(
            loser.name ?? '',
            winner.name ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.customMealsMergeConfirmAction),
          ),
        ],
      ),
    );
  }
}

/// Leading avatar for a custom meal row. Shows the user-attached photo
/// when one exists, otherwise a soft fallback icon matching the recipe
/// list's visual rhythm. Resolution is async because the absolute path
/// is recomposed against the documents directory at render time —
/// see [UserImageStorage.absolutePath] for the reasoning.
class _MealLeadingThumbnail extends StatelessWidget {
  final MealEntity meal;

  const _MealLeadingThumbnail({required this.meal});

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final relative = meal.localImagePath;
    final fallback = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: Dimens.borderRadiusS,
      ),
      child: Icon(Icons.restaurant_rounded, color: accent, size: 24),
    );
    if (relative == null) return fallback;
    return FutureBuilder<String>(
      future: UserImageStorage.absolutePath(relative),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback;
        final file = File(snapshot.data!);
        if (!file.existsSync()) return fallback;
        return ClipRRect(
          borderRadius: Dimens.borderRadiusS,
          child: Image.file(file, width: _size, height: _size, fit: BoxFit.cover),
        );
      },
    );
  }
}
