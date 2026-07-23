import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/demo/demo_seeder.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Persistent banner shown above every tab of `MainScreen` while the
/// active profile holds seeded sample data (see
/// `lib/core/utils/demo/demo_seeder.dart` and `ConfigEntity.isDemoData`).
/// Tapping "Set up your profile" wipes the sample data (via
/// `exitDemoMode`, not just `DeleteAllUserDataUsecase` — the demo also
/// seeded recipes/custom meals/activity templates and renamed the
/// profile, none of which that usecase touches) and returns to
/// onboarding — mirrors `SettingsScreen._confirmDeleteAllData`'s
/// confirm-then-wipe-then-route pattern, just with copy about leaving the
/// demo rather than deleting real data.
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing12,
        Dimens.spacing16,
        0,
      ),
      child: Semantics(
        identifier: 'home-demo-banner',
        child: Material(
          color: Colors.transparent,
          borderRadius: Dimens.borderRadiusM,
          child: InkWell(
            borderRadius: Dimens.borderRadiusM,
            onTap: () => _confirmSetUpProfile(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.spacing16,
                vertical: Dimens.spacing12,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: Dimens.borderRadiusM,
                border: Border.all(
                  color: palette.border,
                  width: Dimens.hairline,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18, color: accent),
                  const SizedBox(width: Dimens.spacing8),
                  Expanded(
                    child: Text(
                      S.of(context).homeDemoBannerLabel,
                      style: textTheme.labelLarge?.copyWith(
                        color: palette.textStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.spacing8),
                  Text(
                    S.of(context).homeDemoBannerAction,
                    style: textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSetUpProfile(BuildContext context) async {
    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homeDemoBannerConfirmTitle),
        content: Text(l10n.homeDemoBannerConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.homeDemoBannerConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // StatelessWidget — use context.mounted (SettingsScreen uses State.mounted).
    if (!context.mounted) return;
    await exitDemoMode();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(NavigationOptions.onboardingRoute, (_) => false);
  }
}
