import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';

class GetCustomActivityTemplatesUsecase {
  final CustomActivityTemplateRepository _repository;

  GetCustomActivityTemplatesUsecase(this._repository);

  Future<List<CustomActivityTemplateEntity>> getAllTemplates() async {
    return _repository.allTemplates();
  }
}
