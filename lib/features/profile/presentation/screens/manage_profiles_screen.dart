import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_profile_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/screens/profile_editor_screen.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_name.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_switch_coordinator.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_switcher_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  late List<ProfileEntity> _profiles;
  late String _activeId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final getProfiles = locator<GetProfilesUsecase>();
    _profiles = getProfiles.getProfiles();
    _activeId = getProfiles.activeProfileId;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.manageProfilesLabel)),
      floatingActionButton: Semantics(
        identifier: 'manage-profiles-add',
        child: FloatingActionButton.extended(
          onPressed: () async {
            await showAddProfileDialog(context);
            if (mounted) setState(_reload);
          },
          icon: const Icon(Icons.add),
          label: Text(s.addProfileLabel),
        ),
      ),
      body: ListView(
        children: [
          for (final profile in _profiles)
            ListTile(
              leading: ProfileAvatar(profile: profile),
              title: Text(profileDisplayName(context, profile)),
              subtitle: profile.id == _activeId
                  ? Text(s.profileActiveLabel)
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    identifier: 'manage-profiles-edit',
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _onEdit(profile),
                    ),
                  ),
                  if (_profiles.length > 1)
                    Semantics(
                      identifier: 'manage-profiles-delete',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _onDelete(profile),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onEdit(ProfileEntity profile) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(profile: profile),
      ),
    );
    if (saved == true && mounted) setState(_reload);
  }

  Future<void> _onDelete(ProfileEntity profile) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteProfileConfirmTitle),
        content: Text(s.deleteProfileConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.dialogDeleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Deleting the active profile switches to another first, which routes
    // away from this screen — so let the coordinator take over and stop.
    final wasActive = profile.id == _activeId;
    await locator<DeleteProfileUsecase>().deleteProfile(profile);
    if (!mounted) return;
    if (wasActive) {
      final fallback = locator<GetProfilesUsecase>().getActiveProfile();
      if (fallback != null) {
        await locator<ProfileSwitchCoordinator>().switchTo(context, fallback);
        return;
      }
    }
    setState(_reload);
  }
}
