import 'package:uuid/uuid.dart';

class IdGenerator {
  static const uuid = Uuid();

  static String getUniqueID() => uuid.v4();
}
