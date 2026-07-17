import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String? imagePath;
  final DateTime createdAt;
  final String boxSuffix;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.boxSuffix,
    this.imagePath,
  });

  bool get isDefault => boxSuffix.isEmpty;

  factory ProfileEntity.fromProfileDBO(ProfileDBO dbo) {
    return ProfileEntity(
      id: dbo.id,
      name: dbo.name,
      createdAt: dbo.createdAt,
      boxSuffix: dbo.boxSuffix,
      imagePath: dbo.imagePath,
    );
  }

  @override
  List<Object?> get props => [id, name, imagePath, createdAt, boxSuffix];
}
