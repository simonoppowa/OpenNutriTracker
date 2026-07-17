import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/update_profile_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/core/presentation/widgets/user_image_picker_tile.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Edits a single profile's name and picture. The picture is imported the
/// moment it's picked (the profile already has an id to key the file by),
/// mirroring the recipe builder's image flow.
class ProfileEditorScreen extends StatefulWidget {
  final ProfileEntity profile;

  const ProfileEditorScreen({super.key, required this.profile});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController _nameController;
  late String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _imagePath = widget.profile.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(kToolbarHeight),
        title: Text(
          s.editProfileTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Semantics(
            identifier: 'profile-editor-save',
            child: TextButton(
              onPressed: _onSave,
              child: Text(s.buttonSaveLabel),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: UserImagePickerTile(
              kind: UserImageKind.profile,
              imagePath: _imagePath,
              onPickFromGallery: () =>
                  _onPickImage(source: ImageSource.gallery),
              onTakePhoto: () => _onPickImage(source: ImageSource.camera),
              onRemove: _onRemoveImage,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            identifier: 'profile-editor-name',
            child: TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: s.profileNameLabel,
                hintText: s.profileNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPickImage({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    final relative = await UserImageStorage.importFrom(
      kind: UserImageKind.profile,
      ownerId: widget.profile.id,
      sourcePath: picked.path,
    );
    FileImage(File(await UserImageStorage.absolutePath(relative))).evict();
    setState(() => _imagePath = relative);
  }

  Future<void> _onRemoveImage() async {
    final current = _imagePath;
    if (current == null) return;
    await UserImageStorage.delete(current);
    setState(() => _imagePath = null);
  }

  Future<void> _onSave() async {
    final toSave = ProfileEntity(
      id: widget.profile.id,
      name: _nameController.text.trim(),
      createdAt: widget.profile.createdAt,
      boxSuffix: widget.profile.boxSuffix,
      imagePath: _imagePath,
    );
    await locator<UpdateProfileUsecase>().updateProfile(toSave);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
