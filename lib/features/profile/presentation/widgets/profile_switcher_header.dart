import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_name.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_switcher_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Tappable header at the top of the Profile tab showing who is active
/// and opening the switcher sheet. Not `const` — the active profile may
/// have been renamed, so the header needs to rebuild after a save.
class ProfileSwitcherHeader extends StatelessWidget {
  const ProfileSwitcherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final activeProfile = locator<GetProfilesUsecase>().getActiveProfile();
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }
    return Semantics(
      identifier: 'profile-switcher',
      child: ListTile(
        leading: ProfileAvatar(profile: activeProfile, radius: 24),
        title: Text(
          profileDisplayName(context, activeProfile),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(S.of(context).switchProfileLabel),
        trailing: const Icon(Icons.unfold_more),
        onTap: () => showProfileSwitcherSheet(context),
      ),
    );
  }
}
