import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #281: Quick weight update chip on the home screen.
///
/// Reads `weightKg` from `HomeLoadedState` (single source of truth) instead
/// of doing its own DB read; that read used to race with onboarding's user
/// write and silently displayed the dummy 80 kg fallback.
class QuickWeightWidget extends StatelessWidget {
  final double weightKg;
  final BodyWeightUnit bodyWeightUnit;

  const QuickWeightWidget({
    super.key,
    required this.weightKg,
    required this.bodyWeightUnit,
  });

  @override
  Widget build(BuildContext context) {
    final displayStr = formatBodyWeight(
      weightKg,
      bodyWeightUnit,
      kgLabel: S.of(context).kgLabel,
      lbLabel: S.of(context).lbsLabel,
      stLabel: S.of(context).stLabel,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      identifier: 'home-weight-chip',
      child: Material(
        color: Colors.transparent,
        borderRadius: Dimens.borderRadiusM,
        child: InkWell(
          borderRadius: Dimens.borderRadiusM,
          onTap: () => _showWeightDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.spacing12,
              vertical: Dimens.spacing8,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: Dimens.borderRadiusM,
              border: Border.all(color: palette.border, width: Dimens.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monitor_weight_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: Dimens.spacing8),
                Text(
                  displayStr,
                  style: textTheme.labelLarge?.copyWith(
                    color: palette.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: Dimens.spacing4),
                Icon(Icons.edit_rounded, size: 15, color: palette.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWeightDialog(BuildContext context) async {
    final newKg = await showDialog<double>(
      context: context,
      builder: (context) => SetWeightDialog(
        initialKg: weightKg,
        unit: bodyWeightUnit,
      ),
    );

    if (newKg == null || !context.mounted) return;

    final now = DateTime.now();
    await locator<AddWeightLogUsecase>().addEntry(
      WeightLogEntity(
        date: DateTime(now.year, now.month, now.day),
        weightKg: newKg,
      ),
    );

    // addEntry already persisted today's weight onto the user record, so
    // re-load it and route through ProfileBloc.updateUser purely so the
    // profile screen, diary, and home all refresh in one go. Going through
    // AddUserUsecase directly would update Hive but leave the profile
    // screen showing the pre-edit weight until the next manual reload.
    final user = await locator<GetUserUsecase>().getUserData();
    await locator<ProfileBloc>().updateUser(user);
  }
}
