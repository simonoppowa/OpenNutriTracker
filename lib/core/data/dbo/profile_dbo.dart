import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';

part 'profile_dbo.g.dart';

@HiveType(typeId: 20)
class ProfileDBO extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String? imagePath;
  @HiveField(3)
  DateTime createdAt;

  /// Suffix appended to this profile's box names. The very first profile
  /// carries an empty suffix so it adopts the original (unsuffixed) box
  /// names already on disk — that is what lets a long-time user keep all
  /// their data with no migration when multi-profile support arrives.
  /// Every profile created afterwards gets a non-empty suffix and its own
  /// isolated set of boxes.
  @HiveField(4)
  String boxSuffix;

  ProfileDBO({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.boxSuffix,
    this.imagePath,
  });

  factory ProfileDBO.fromProfileEntity(ProfileEntity entity) {
    return ProfileDBO(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      boxSuffix: entity.boxSuffix,
      imagePath: entity.imagePath,
    );
  }
}
