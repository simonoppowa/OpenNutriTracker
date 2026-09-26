import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/explode_recipe_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/recipe_swipe_scope.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A left swipe reveals the recipe action without making a horizontal swipe
/// elsewhere on the diary stop navigating between days.
class ExplodableIntakeRow extends StatefulWidget {
  final IntakeEntity intake;
  final bool usesImperialUnits;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;

  const ExplodableIntakeRow({
    super.key,
    required this.intake,
    required this.usesImperialUnits,
    this.onItemLongPressed,
    this.onItemTapped,
  });

  @override
  State<ExplodableIntakeRow> createState() => _ExplodableIntakeRowState();
}

class _ExplodableIntakeRowState extends State<ExplodableIntakeRow>
    with SingleTickerProviderStateMixin {
  static const _actionWidth = 104.0;
  late final AnimationController _slide;
  RecipeSwipeController? _group;
  bool _busy = false;

  double get _offset => _slide.value;

  void _onSlide() => setState(() {});

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      lowerBound: -_actionWidth,
      upperBound: 0,
      value: 0,
      duration: const Duration(milliseconds: 200),
    )..addListener(_onSlide);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = RecipeSwipeScope.maybeOf(context);
    if (group != _group) {
      _group?.release(_close);
      _group = group;
      _slide.value = 0;
    }
  }

  @override
  void didUpdateWidget(ExplodableIntakeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intake.id != widget.intake.id ||
        oldWidget.intake.dateTime != widget.intake.dateTime ||
        oldWidget.intake.meal.source != widget.intake.meal.source) {
      _group?.release(_close);
      _slide.value = 0;
    }
  }

  @override
  void dispose() {
    _group?.release(_close);
    _slide.dispose();
    super.dispose();
  }

  void _settle(double target) {
    if (target == 0) _group?.release(_close);
    if (MediaQuery.disableAnimationsOf(context)) {
      _slide.value = target;
    } else {
      _slide.animateTo(target, curve: Curves.easeOut);
    }
  }

  void _close() {
    if (_offset != 0 || _slide.isAnimating) _settle(0);
  }

  @override
  Widget build(BuildContext context) {
    final card = IntakeCard(
      key: ValueKey('card-${widget.intake.id}'),
      intake: widget.intake,
      onItemLongPressed: widget.onItemLongPressed,
      onItemTapped: widget.intake.meal.source == MealSourceEntity.recipe
          ? (context, intake, imperial) {
              if (_offset != 0) {
                _close();
              } else {
                widget.onItemTapped?.call(context, intake, imperial);
              }
            }
          : widget.onItemTapped,
      firstListElement: false,
      usesImperialUnits: widget.usesImperialUnits,
    );
    if (widget.intake.meal.source != MealSourceEntity.recipe) return card;

    final available = widget.intake.recipeSnapshot != null;
    final color = Theme.of(context).colorScheme.primary;
    final actionEnabled = _offset == -_actionWidth && !_slide.isAnimating;
    return TapRegion(
      onTapOutside: (_) => _close(),
      child: Semantics(
        identifier: 'recipe-intake-swipe',
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _busy
              ? null
              : (_) {
                  _slide.stop();
                  _group?.open(_close);
                },
          onHorizontalDragUpdate: _busy
              ? null
              : (details) {
                  _slide.value = (_offset + details.delta.dx).clamp(
                    -_actionWidth,
                    0.0,
                  );
                },
          onHorizontalDragEnd: _busy
              ? null
              : (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  _settle(
                    velocity < -250 ||
                            (velocity <= 250 && _offset < -_actionWidth / 2)
                        ? -_actionWidth
                        : 0,
                  );
                },
          onHorizontalDragCancel: _busy ? null : _close,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  right: Dimens.spacing16,
                  top: Dimens.spacing4,
                  bottom: Dimens.spacing4,
                  child: SizedBox(
                    width: _actionWidth,
                    child: IgnorePointer(
                      ignoring: !actionEnabled || _busy,
                      child: ExcludeSemantics(
                        excluding: !actionEnabled,
                        child: Semantics(
                          identifier: 'explode-recipe-action',
                          child: Material(
                            color: available
                                ? color
                                : Theme.of(context).disabledColor,
                            borderRadius: BorderRadius.circular(Dimens.radiusM),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                Dimens.radiusM,
                              ),
                              onTap: _busy ? null : _onExplode,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.call_split_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    S.of(context).explodeRecipeLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(offset: Offset(_offset, 0), child: card),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onExplode() async {
    if (_busy) return;
    _close();
    if (widget.intake.recipeSnapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).explodeRecipeOldEntryMessage)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const _ExplodeConfirmDialog(),
      );
      if (confirmed != true) return;
      await locator<ExplodeRecipeIntakeUsecase>().explode(widget.intake.id);
      locator<HomeBloc>().add(const LoadItemsEvent());
      locator<DiaryBloc>().add(const LoadDiaryYearEvent());
      locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).explodeRecipeSuccessMessage)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).explodeRecipeFailedMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ExplodeConfirmDialog extends StatelessWidget {
  const _ExplodeConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.explodeRecipeConfirmTitle),
      content: Text(s.explodeRecipeOneWayHint),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'explode-recipe-confirm',
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.explodeRecipeLabel),
          ),
        ),
      ],
    );
  }
}
