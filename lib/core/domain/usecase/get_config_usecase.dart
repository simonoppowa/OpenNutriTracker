import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:provider/provider.dart';

class GetConfigUsecase {
  Future<ConfigEntity> getConfig(BuildContext context) async {
    final configRepository =
        Provider.of<ConfigRepository>(context, listen: false);
    return await configRepository.getConfig();
  }
}
