import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingThirdPageBody extends StatefulWidget {
  final Function(bool active, UserActivitySelectionEntity? selectedActivity)
  setButtonContent;
  final UserActivitySelectionEntity? initialActivity;

  const OnboardingThirdPageBody({
    super.key,
    required this.setButtonContent,
    this.initialActivity,
  });

  @override
  State<OnboardingThirdPageBody> createState() =>
      _OnboardingThirdPageBodyState();
}

class _OnboardingThirdPageBodyState extends State<OnboardingThirdPageBody> {
  late UserActivitySelectionEntity? _selected = widget.initialActivity;

  /// Identifier suffixes are pinned to the values the UI drivers already
  /// use ('low' and 'very', not the enum's own names), so the redesign
  /// doesn't break tools/adb/walk-onboarding.sh.
  static const _identifierSuffix = {
    UserActivitySelectionEntity.sedentary: 'sedentary',
    UserActivitySelectionEntity.lowActive: 'low',
    UserActivitySelectionEntity.active: 'active',
    UserActivitySelectionEntity.veryActive: 'very',
  };

  String _title(UserActivitySelectionEntity activity) {
    switch (activity) {
      case UserActivitySelectionEntity.sedentary:
        return S.of(context).palSedentaryLabel;
      case UserActivitySelectionEntity.lowActive:
        return S.of(context).palLowLActiveLabel;
      case UserActivitySelectionEntity.active:
        return S.of(context).palActiveLabel;
      case UserActivitySelectionEntity.veryActive:
        return S.of(context).palVeryActiveLabel;
    }
  }

  String _description(UserActivitySelectionEntity activity) {
    switch (activity) {
      case UserActivitySelectionEntity.sedentary:
        return S.of(context).palSedentaryDescriptionLabel;
      case UserActivitySelectionEntity.lowActive:
        return S.of(context).palLowActiveDescriptionLabel;
      case UserActivitySelectionEntity.active:
        return S.of(context).palActiveDescriptionLabel;
      case UserActivitySelectionEntity.veryActive:
        return S.of(context).palVeryActiveDescriptionLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).activityLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              S.of(context).onboardingActivityQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimens.spacing16),
            for (final activity in UserActivitySelectionEntity.values) ...[
              _buildActivityCard(activity),
              const SizedBox(height: Dimens.spacing12),
            ],
          ],
        ),
      ),
    );
  }

  /// One full-width choice per activity level, each carrying its own
  /// description. The descriptions used to sit behind a '?' icon beside a
  /// chip, a tap away from the choice they inform.
  Widget _buildActivityCard(UserActivitySelectionEntity activity) {
    final isSelected = _selected == activity;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      identifier: 'onboarding-activity-${_identifierSuffix[activity]}',
      child: AppCard(
        onTap: () => _onSelected(activity),
        color: isSelected ? colors.primaryContainer : null,
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(activity),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? colors.onPrimaryContainer : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Dimens.spacing4),
                  Text(
                    _description(activity),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimens.spacing12),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? colors.onPrimaryContainer : colors.outline,
            ),
          ],
        ),
      ),
    );
  }

  void _onSelected(UserActivitySelectionEntity activity) {
    setState(() => _selected = activity);
    widget.setButtonContent(true, activity);
  }
}
