import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/box_upsert.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Hive-backed store for [CustomActivityTemplateDBO] entries used by the
/// Custom activity flow (#70 follow-up).
///
/// Templates are matched on [CustomActivityTemplateDBO.name]: a second
/// "Save as template" with the same name overwrites the earlier entry
/// rather than producing duplicates, which keeps the picker list tidy
/// for users who tweak a template's typical kcal over time.
class CustomActivityTemplateDataSource {
  final log = Logger('CustomActivityTemplateDataSource');
  final HiveDBProvider _db;

  CustomActivityTemplateDataSource(this._db);

  Box<CustomActivityTemplateDBO> get _box => _db.customActivityTemplateBox;

  Future<void> addTemplate(CustomActivityTemplateDBO template) async {
    log.fine('Saving custom activity template "${template.name}"');
    final keys = [
      for (final entry in _box.toMap().entries)
        if (entry.value.name == template.name) entry.key,
    ];
    // Every stored copy is rewritten, so an install the old import doubled
    // (#1357) ends up with copies that agree.
    if (keys.isEmpty) {
      await _box.add(template);
    } else {
      // A Hive object lives under one key, so further copies get their own.
      await _box.putAll({
        for (final (i, key) in keys.indexed)
          key: i == 0
              ? template
              : CustomActivityTemplateDBO(
                  template.name,
                  template.typicalKcal,
                  notes: template.notes,
                ),
      });
    }
  }

  /// Upserts by name, like [addTemplate]: an imported template replaces
  /// the saved one of the same name instead of sitting beside it (#1357).
  /// Where a bundle holds a name twice the last row wins — the old save
  /// deleted the first copy and appended the new one.
  Future<void> upsertAllTemplates(
    List<CustomActivityTemplateDBO> templates,
  ) async {
    log.fine('Bulk-importing ${templates.length} custom activity templates');
    await _box.upsertAllBy(
      templates,
      (dbo) => dbo.name,
      winner: UpsertWinner.last,
    );
  }

  Future<List<CustomActivityTemplateDBO>> allTemplates() async {
    final templates = _box.values.toList();
    templates.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return templates;
  }

  Future<void> deleteTemplate(String name) async {
    log.fine('Deleting custom activity template "$name"');
    final matches = _box.values.where((dbo) => dbo.name == name).toList();
    for (final element in matches) {
      await element.delete();
    }
  }
}
