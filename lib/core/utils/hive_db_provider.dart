import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';

class HiveDBProvider extends ChangeNotifier{
  static const intakeBoxName = 'IntakeBox';
  static const userBoxName = 'UserBox';

  late Box<IntakeDBO> intakeBox;
  late Box<UserDBO> userBox;

  Future<void> initHiveDB() async {
    await Hive.initFlutter();
    Hive.registerAdapter(IntakeDBOAdapter());
    Hive.registerAdapter(ProductDBOAdapter());
    Hive.registerAdapter(ProductNutrimentsDBOAdapter());
    Hive.registerAdapter(IntakeTypeDBOAdapter());
    Hive.registerAdapter(UserDBOAdapter());
    Hive.registerAdapter(UserGenderDBOAdapter());
    Hive.registerAdapter(UserWeightGoalDBOAdapter());
    Hive.registerAdapter(UserPALDBOAdapter());

    intakeBox = await Hive.openBox(intakeBoxName);
    userBox = await Hive.openBox(userBoxName);
  }


}
