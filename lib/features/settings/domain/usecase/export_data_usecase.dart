import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_export_definitions.dart';

class ExportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;

  ExportDataUsecase(this._userActivityRepository, this._intakeRepository,
      this._trackedDayRepository);

  /// Exports user activity, intake, and tracked day data to a zip of json
  /// files at a user specified location.
  Future<Uint8List?> exportData({String? exportZipFileName}) async {
    // Export user activity data to Json File Bytes
    final fullUserActivity =
        await _userActivityRepository.getAllUserActivityDBO();
    final fullUserActivityJson = jsonEncode(
        fullUserActivity.map((activity) => activity.toJson()).toList());
    final userActivityJsonBytes = utf8.encode(fullUserActivityJson);

    // Export intake data to Json File Bytes
    final fullIntake = await _intakeRepository.getAllIntakesDBO();
    final fullIntakeJson =
        jsonEncode(fullIntake.map((intake) => intake.toJson()).toList());
    final intakeJsonBytes = utf8.encode(fullIntakeJson);

    // Export tracked day data to Json File Bytes
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    final fullTrackedDayJson = jsonEncode(
        fullTrackedDay.map((trackedDay) => trackedDay.toJson()).toList());
    final trackedDayJsonBytes = utf8.encode(fullTrackedDayJson);

    // Create a zip file with the exported data
    final archive = Archive();
    archive.addFile(
      ArchiveFile(ImportExportDefinitions.userActivityJsonFileName, userActivityJsonBytes.length,
          userActivityJsonBytes),
    );
    archive.addFile(
      ArchiveFile(
          ImportExportDefinitions.userIntakeJsonFileName, intakeJsonBytes.length, intakeJsonBytes),
    );
    archive.addFile(
      ArchiveFile(ImportExportDefinitions.trackedDayJsonFileName, trackedDayJsonBytes.length,
          trackedDayJsonBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);

    if (exportZipFileName != null) {
      // Show a popup dialog and save the zip file to the user specified location
      final result = await FilePicker.saveFile(
        fileName: exportZipFileName,
        bytes: Uint8List.fromList(zipBytes),
      );

      if (result != null && result.toFilePath().isNotEmpty) {
        return Uint8List.fromList(zipBytes);
      }
    } else {
      return Uint8List.fromList(zipBytes);
    }
    return null;
  }
}
