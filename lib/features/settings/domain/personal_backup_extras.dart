import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';

/// The data this fork adds to the JSON backup on top of upstream's files.
///
/// Kept apart from `ExportDataUsecase` / `ImportDataUsecase` so the fork's
/// additions stay in one place and upstream merges touch as little as
/// possible: the usecases only call [addTo] and [prepareRestore].
///
/// Every file here is optional on restore, so a zip from upstream or from an
/// older build of the fork still imports.
class PersonalBackupExtras {
  static const waterIntakeFileName = 'water_intake.json';

  final WaterIntakeRepository _waterIntakeRepository;

  PersonalBackupExtras(this._waterIntakeRepository);

  /// Writes the fork's JSON files into [archive].
  Future<void> addTo(Archive archive) async {
    final water = await _waterIntakeRepository.getAllEntriesDBO();
    _addJson(archive, waterIntakeFileName, [
      for (final entry in water) entry.toJson(),
    ]);
  }

  /// Decodes everything the fork restores from [archive] and returns the
  /// writes, so a malformed file throws an [ExportImportFailure] here, before
  /// the caller has written anything.
  ///
  /// Water entries are keyed by id, so restoring the same backup twice
  /// replaces them instead of adding them again.
  Future<void> Function() prepareRestore(Archive archive) {
    final water = _decodeList(
      archive.findFile(waterIntakeFileName),
      WaterIntakeDBO.fromJson,
    );

    return () async {
      if (water != null) {
        await _waterIntakeRepository.addAllEntries(water);
      }
    };
  }

  static void _addJson(Archive archive, String name, Object json) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(jsonEncode(json))));
  }

  static List<T>? _decodeList<T>(
    ArchiveFile? file,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (file == null) return null;
    return ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse ${file.name}',
      () => (jsonDecode(utf8.decode(file.content as List<int>)) as List)
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList(),
    );
  }
}
