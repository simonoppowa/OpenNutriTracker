import 'package:uuid/uuid.dart';

class IdGenerator {
  static const uuid = Uuid();

  static String getUniqueID() => uuid.v4();

  /// A stable id for [content]: the same content always gets the same id.
  static String getContentID(String content) =>
      uuid.v5(Namespace.url.value, 'opennutritracker:$content');
}
