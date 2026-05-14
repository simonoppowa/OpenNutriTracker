import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';

/// Repository for saved Custom activity templates (#70 follow-up).
///
/// Mediates between BLoC-level [CustomActivityTemplateEntity] objects
/// and the Hive-backed [CustomActivityTemplateDataSource]. The export
/// and import pipelines work directly with [CustomActivityTemplateDBO]
/// so the JSON shape stays the same as the on-disk shape.
class CustomActivityTemplateRepository {
  final CustomActivityTemplateDataSource _dataSource;

  CustomActivityTemplateRepository(this._dataSource);

  Future<void> addTemplate(CustomActivityTemplateEntity entity) async {
    await _dataSource.addTemplate(entity.toDBO());
  }

  Future<void> addAllTemplateDBOs(
    List<CustomActivityTemplateDBO> templates,
  ) async {
    await _dataSource.addAllTemplates(templates);
  }

  Future<List<CustomActivityTemplateEntity>> allTemplates() async {
    final dbos = await _dataSource.allTemplates();
    return dbos
        .map(CustomActivityTemplateEntity.fromDBO)
        .toList(growable: false);
  }

  Future<List<CustomActivityTemplateDBO>> allTemplateDBOs() async {
    return _dataSource.allTemplates();
  }

  Future<void> deleteTemplate(String name) async {
    await _dataSource.deleteTemplate(name);
  }
}
