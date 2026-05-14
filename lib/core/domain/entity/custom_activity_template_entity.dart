import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';

/// Domain model for a saved Custom activity template (#70 follow-up).
///
/// Mirrors [CustomActivityTemplateDBO] but stays free of Hive
/// annotations so UI and BLoC layers don't have to depend on the
/// storage backend.
class CustomActivityTemplateEntity extends Equatable {
  final String name;
  final double typicalKcal;
  final String? notes;

  const CustomActivityTemplateEntity({
    required this.name,
    required this.typicalKcal,
    this.notes,
  });

  factory CustomActivityTemplateEntity.fromDBO(
    CustomActivityTemplateDBO dbo,
  ) {
    return CustomActivityTemplateEntity(
      name: dbo.name,
      typicalKcal: dbo.typicalKcal,
      notes: dbo.notes,
    );
  }

  CustomActivityTemplateDBO toDBO() {
    return CustomActivityTemplateDBO(name, typicalKcal, notes: notes);
  }

  @override
  List<Object?> get props => [name, typicalKcal, notes];
}
