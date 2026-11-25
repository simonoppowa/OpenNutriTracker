import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/util/meal_photo_encoder.dart';
import 'package:opennutritracker/features/edit_meal/domain/usecase/read_nutrition_label_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Takes a photo for [LabelScanButton] in [format]: null when the user
/// cancelled, and throws when the photo cannot be used.
typedef TakeLabelPhoto = Future<MealPhoto?> Function(MealPhotoFormat format);

/// "Read nutrition label" in the custom-meal form's app bar: a photo of the
/// label fills the form with the values printed on it.
///
/// Offered only while AI meal assistance can read a photo — enabled, agreed
/// to and not hidden, as [ReadNutritionLabelUseCase.photoDestination] asks —
/// and absent otherwise, like the meal photo's camera.
class LabelScanButton extends StatefulWidget {
  final ValueChanged<NutritionLabelReading> onRead;

  /// The registered one when null, and none where the app's services are not
  /// set up, which leaves the button out.
  final ReadNutritionLabelUseCase? useCase;

  /// The camera when null.
  final TakeLabelPhoto? takePhoto;

  const LabelScanButton({
    super.key,
    required this.onRead,
    this.useCase,
    this.takePhoto,
  });

  @override
  State<LabelScanButton> createState() => _LabelScanButtonState();
}

class _LabelScanButtonState extends State<LabelScanButton> {
  static final _log = Logger('LabelScanButton');

  late final ReadNutritionLabelUseCase? _useCase =
      widget.useCase ??
      (locator.isRegistered<ReadNutritionLabelUseCase>()
          ? locator<ReadNutritionLabelUseCase>()
          : null);

  bool _available = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _useCase?.photoDestination().then((destination) {
      if (mounted) setState(() => _available = destination != null);
    });
  }

  Future<void> _scan() async {
    final useCase = _useCase!;
    // Asked again: the answer may have changed since the screen opened.
    final destination = await useCase.photoDestination();
    if (destination == null || !mounted) return;
    if (await _confirm(destination.name) != true || !mounted) return;

    final s = S.of(context);
    final MealPhoto? photo;
    try {
      photo = await (widget.takePhoto ?? _takePhoto)(
        MealPhotoFormat.forProvider(destination.provider),
      );
    } catch (e, stackTrace) {
      _log.warning('Taking a label photo failed', e, stackTrace);
      _tell(s.bulkAddPhotoUnreadableLabel);
      return;
    }
    if (photo == null || !mounted) return;

    setState(() => _busy = true);
    String? message;
    try {
      final reading = await useCase.read(photo);
      if (reading == null || reading.isEmpty) {
        message = s.customMealLabelScanNothingRead;
      } else if (mounted) {
        widget.onRead(reading);
      }
    } on MealInterpreterException catch (e) {
      message = e.failure == MealInterpreterFailure.unsupported
          ? s.bulkAddPhotoUnsupportedLabel
          : s.bulkAddPhotoFailedLabel;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (message != null) _tell(message);
  }

  /// Names where the photo goes before the camera opens: the last moment
  /// the user can decline.
  Future<bool?> _confirm(String destination) => showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${S.of(sheetContext).customMealLabelScanDisclosure(destination)}'
              '\n\n${S.of(sheetContext).aiAssistExperimentalNote}',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
          ),
          Semantics(
            identifier: 'edit-meal-label-scan-camera',
            child: ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(S.of(sheetContext).mealImageTakePhoto),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
          ),
        ],
      ),
    ),
  );

  static Future<MealPhoto?> _takePhoto(MealPhotoFormat format) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return null;
    // Deletes the picker's cache copy, encoded or not: the label photo is
    // kept nowhere, as a meal photo is not.
    final photo = await MealPhotoEncoder.encodeAndDiscardSource(
      picked.path,
      format: format,
    );
    if (photo == null) throw StateError('label photo could not be encoded');
    return photo;
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return Semantics(
      identifier: 'edit-meal-label-scan',
      child: IconButton(
        tooltip: S.of(context).customMealLabelScanButton,
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.document_scanner_outlined),
        onPressed: _busy ? null : _scan,
      ),
    );
  }
}
