import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/goal_suggestion_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingFourthPageBody extends StatefulWidget {
  final Function(bool active, UserGoalSelectionEntity? selectedGoal)
  setButtonContent;
  final UserGoalSelectionEntity? initialGoal;

  /// Entered on the previous pages, and used only to derive the suggestion.
  /// Without them the page shows no suggestion.
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;

  const OnboardingFourthPageBody({
    super.key,
    required this.setButtonContent,
    this.initialGoal,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
  });

  @override
  State<OnboardingFourthPageBody> createState() =>
      _OnboardingFourthPageBodyState();
}

class _OnboardingFourthPageBodyState extends State<OnboardingFourthPageBody> {
  late UserGoalSelectionEntity? _selected = widget.initialGoal;

  /// Derived on every build rather than cached, so going back to the
  /// height/weight page and changing a value can't leave the badge marking
  /// the goal the old numbers pointed at. It is pure arithmetic on three
  /// doubles, so there is nothing to save by holding on to it.
  GoalSuggestionEntity? get _suggestion => GoalSuggestionEntity.from(
    heightCm: widget.heightCm,
    weightKg: widget.weightKg,
    targetWeightKg: widget.targetWeightKg,
  );

  String _label(UserGoalSelectionEntity goal) {
    switch (goal) {
      case UserGoalSelectionEntity.loseWeight:
        return S.of(context).goalLoseWeight;
      case UserGoalSelectionEntity.maintainWeight:
        return S.of(context).goalMaintainWeight;
      case UserGoalSelectionEntity.gainWeigh:
        return S.of(context).goalGainWeight;
    }
  }

  static const _identifierSuffix = {
    UserGoalSelectionEntity.loseWeight: 'lose',
    UserGoalSelectionEntity.maintainWeight: 'maintain',
    UserGoalSelectionEntity.gainWeigh: 'gain',
  };

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion;
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).goalLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              S.of(context).onboardingGoalQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimens.spacing16),
            for (final goal in UserGoalSelectionEntity.values) ...[
              _buildGoalRow(goal, suggestion),
              const SizedBox(height: Dimens.spacing8),
            ],
            if (suggestion != null) ...[
              const SizedBox(height: Dimens.spacing8),
              _buildSuggestionCard(suggestion),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow(
    UserGoalSelectionEntity goal,
    GoalSuggestionEntity? suggestion,
  ) {
    final isSuggested = suggestion?.goal == goal;
    return Row(
      children: [
        Semantics(
          identifier: 'onboarding-goal-${_identifierSuffix[goal]}',
          child: ChoiceChip(
            label: Text(
              _label(goal),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            selected: _selected == goal,
            onSelected: (_) => _onSelected(goal),
          ),
        ),
        if (isSuggested) ...[
          const SizedBox(width: Dimens.spacing8),
          _buildSuggestedBadge(),
        ],
      ],
    );
  }

  /// Marks the suggested option without selecting it. The user still makes
  /// the choice, with the numbers' direction stated.
  Widget _buildSuggestedBadge() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing8,
        vertical: Dimens.spacing4,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(Dimens.radiusS),
      ),
      child: Text(
        S.of(context).onboardingGoalSuggestedBadge,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.onSecondaryContainer),
      ),
    );
  }

  /// States what the suggestion rests on, so it reads as a derivation rather
  /// than an opinion the app is handing down.
  Widget _buildSuggestionCard(GoalSuggestionEntity suggestion) {
    final String reason;
    switch (suggestion.basis) {
      case GoalSuggestionBasis.targetWeight:
        reason = S.of(context).onboardingGoalSuggestionTarget;
      case GoalSuggestionBasis.bmi:
        reason = S
            .of(context)
            .onboardingGoalSuggestionBmi(
              suggestion.bmi!.toStringAsFixed(1),
              suggestion.nutritionalStatus!.getName(context),
            );
    }

    return Container(
      padding: const EdgeInsets.all(Dimens.spacing12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Dimens.radiusS),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: Dimens.spacing8),
          Expanded(
            child: Text(reason, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  void _onSelected(UserGoalSelectionEntity goal) {
    setState(() => _selected = goal);
    widget.setButtonContent(true, goal);
  }
}
