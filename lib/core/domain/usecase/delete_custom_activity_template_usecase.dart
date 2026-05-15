import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';

class DeleteCustomActivityTemplateUsecase {
  final CustomActivityTemplateRepository _repository;

  DeleteCustomActivityTemplateUsecase(this._repository);

  Future<void> deleteTemplate(String name) async {
    await _repository.deleteTemplate(name);
  }
}
