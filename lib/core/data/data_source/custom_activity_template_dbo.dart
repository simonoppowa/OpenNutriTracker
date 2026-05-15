import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'custom_activity_template_dbo.g.dart';

/// A saved template for the Custom activity flow (#70 follow-up).
///
/// Reporters who do the same workout repeatedly — a thirty-minute bike
/// commute, a tracker-measured run, a regular gym session — were
/// retyping the same kcal figure every day. A template stores a
/// remembered [name] alongside the [typicalKcal] the user usually
/// burns, so a single tap on a list of saved templates pre-fills the
/// kcal field on the Custom activity form.
///
/// Templates are entirely opt-in: the "Save as template" checkbox on
/// the Custom activity form is off by default, so users who only ever
/// log one-off entries never accumulate template clutter.
@HiveType(typeId: 21)
@JsonSerializable()
class CustomActivityTemplateDBO extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double typicalKcal;

  @HiveField(2)
  final String? notes;

  CustomActivityTemplateDBO(this.name, this.typicalKcal, {this.notes});

  factory CustomActivityTemplateDBO.fromJson(Map<String, dynamic> json) =>
      _$CustomActivityTemplateDBOFromJson(json);

  Map<String, dynamic> toJson() => _$CustomActivityTemplateDBOToJson(this);
}
