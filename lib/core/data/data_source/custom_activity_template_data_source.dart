import 'package:collection/collection.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
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
    final existing =
        _box.values.firstWhereOrNull((dbo) => dbo.name == template.name);
    if (existing != null) {
      await existing.delete();
    }
    await _box.add(template);
  }

  Future<void> addAllTemplates(
    List<CustomActivityTemplateDBO> templates,
  ) async {
    log.fine('Bulk-importing ${templates.length} custom activity templates');
    await _box.addAll(templates);
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
