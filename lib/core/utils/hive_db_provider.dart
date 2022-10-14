import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_dbo.dart';
import 'package:opennutritracker/core/data/dbo/product_nutriments_dbo.dart';

class HiveDBProvider extends ChangeNotifier{
  static const userBoxName = 'IntakeBox';

  late Box<IntakeDBO> intakeBox;

  Future<void> initHiveDB() async {
    await Hive.initFlutter();
    Hive.registerAdapter(IntakeDBOAdapter());
    Hive.registerAdapter(ProductDBOAdapter());
    Hive.registerAdapter(ProductNutrimentsDBOAdapter());
    Hive.registerAdapter(IntakeTypeDBOAdapter());
    intakeBox = await Hive.openBox(userBoxName);
  }


}
