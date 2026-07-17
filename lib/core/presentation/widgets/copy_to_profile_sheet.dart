import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/send_intake_to_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_name.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Bottom sheet that lets the user pick one or more *other* profiles and
/// copy the given intakes into each. Only profiles other than the active
/// one are listed. Shows a confirmation snackbar on the calling screen.
Future<void> showCopyToProfileSheet(
  BuildContext context,
  List<IntakeEntity> intakes,
) async {
  final getProfiles = locator<GetProfilesUsecase>();
  final activeId = getProfiles.activeProfileId;
  final otherProfiles =
      getProfiles.getProfiles().where((p) => p.id != activeId).toList();
  if (otherProfiles.isEmpty) return;

  final messenger = ScaffoldMessenger.of(context);
  final copiedSnackbar = S.of(context).copiedToProfileSnackbar;
  final copied = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _CopyToProfileSheet(intakes: intakes, otherProfiles: otherProfiles),
  );

  if (copied == true) {
    messenger.showSnackBar(SnackBar(content: Text(copiedSnackbar)));
  }
}

class _CopyToProfileSheet extends StatefulWidget {
  final List<IntakeEntity> intakes;
  final List<ProfileEntity> otherProfiles;

  const _CopyToProfileSheet({
    required this.intakes,
    required this.otherProfiles,
  });

  @override
  State<_CopyToProfileSheet> createState() => _CopyToProfileSheetState();
}

class _CopyToProfileSheetState extends State<_CopyToProfileSheet> {
  final _selectedIds = <String>{};
  bool _copying = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              s.copyToProfileLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final profile in widget.otherProfiles)
                  Semantics(
                    identifier: 'copy-to-profile-item',
                    child: CheckboxListTile(
                      value: _selectedIds.contains(profile.id),
                      onChanged: _copying
                          ? null
                          : (checked) => setState(() {
                                if (checked == true) {
                                  _selectedIds.add(profile.id);
                                } else {
                                  _selectedIds.remove(profile.id);
                                }
                              }),
                      secondary: ProfileAvatar(profile: profile),
                      title: Text(profileDisplayName(context, profile)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              identifier: 'copy-to-profile-confirm',
              child: FilledButton(
                onPressed:
                    _selectedIds.isEmpty || _copying ? null : _onConfirm,
                child: _copying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.copyActionLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _copying = true);
    final targets = widget.otherProfiles
        .where((p) => _selectedIds.contains(p.id))
        .toList();
    await locator<SendIntakeToProfilesUsecase>()
        .copyToProfiles(widget.intakes, targets);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
