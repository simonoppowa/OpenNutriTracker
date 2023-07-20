import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';

part 'app_theme_dbo.g.dart';

@HiveType(typeId: 15)
enum AppThemeDBO {
  @HiveField(0)
  light,
  @HiveField(1)
  dark,
  @HiveField(2)
  system;

  static AppThemeDBO get defaultTheme => AppThemeDBO.system;

  factory AppThemeDBO.fromAppThemeEntity(AppThemeEntity entity) {
    AppThemeDBO dbo;
    switch (entity) {
      case AppThemeEntity.light:
        dbo = AppThemeDBO.light;
        break;
      case AppThemeEntity.dark:
        dbo = AppThemeDBO.dark;
        break;
      case AppThemeEntity.system:
        dbo = AppThemeDBO.system;
        break;
      default:
        return AppThemeDBO.system;
    }
    return dbo;
  }
}
