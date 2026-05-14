import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';

class AddCustomActivityTemplateUsecase {
  final CustomActivityTemplateRepository _repository;

  AddCustomActivityTemplateUsecase(this._repository);

  Future<void> addTemplate(CustomActivityTemplateEntity entity) async {
    await _repository.addTemplate(entity);
  }
}
