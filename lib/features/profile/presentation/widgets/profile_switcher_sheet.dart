import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/usecase/create_profile_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_name.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_switch_coordinator.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Bottom sheet that lists every profile, switches to the tapped one, and
/// offers shortcuts to add a profile or open the management screen.
Future<void> showProfileSwitcherSheet(BuildContext pageContext) async {
  await showModalBottomSheet<void>(
    context: pageContext,
    showDragHandle: true,
    builder: (sheetContext) {
      final getProfiles = locator<GetProfilesUsecase>();
      final profiles = getProfiles.getProfiles();
      final activeId = getProfiles.activeProfileId;
      final s = S.of(sheetContext);

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                s.switchProfileLabel,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final profile in profiles)
                    Semantics(
                      identifier: 'profile-switcher-item',
                      child: ListTile(
                        leading: ProfileAvatar(profile: profile),
                        title: Text(profileDisplayName(sheetContext, profile)),
                        trailing: profile.id == activeId
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          if (profile.id != activeId) {
                            locator<ProfileSwitchCoordinator>()
                                .switchTo(pageContext, profile);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Semantics(
              identifier: 'profile-switcher-add',
              child: ListTile(
                leading: const Icon(Icons.add),
                title: Text(s.addProfileLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showAddProfileDialog(pageContext);
                },
              ),
            ),
            Semantics(
              identifier: 'profile-switcher-manage',
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(s.manageProfilesLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(pageContext)
                      .pushNamed(NavigationOptions.manageProfilesRoute);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Prompts for a name, creates the profile, and switches to it — which
/// routes into onboarding so the new profile's body stats are collected.
/// A picture can be added afterwards from the management screen.
Future<void> showAddProfileDialog(BuildContext pageContext) async {
  final controller = TextEditingController();
  final created = await showDialog<bool>(
    context: pageContext,
    builder: (dialogContext) {
      final s = S.of(dialogContext);
      return AlertDialog(
        title: Text(s.addProfileLabel),
        content: Semantics(
          identifier: 'profile-name-field',
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: s.profileNameLabel,
              hintText: s.profileNameHint,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          Semantics(
            identifier: 'profile-add-confirm',
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(s.addLabel),
            ),
          ),
        ],
      );
    },
  );

  if (created != true) return;

  final profile = await locator<CreateProfileUsecase>()
      .createProfile(name: controller.text.trim());
  if (!pageContext.mounted) return;
  await locator<ProfileSwitchCoordinator>().switchTo(pageContext, profile);
}
