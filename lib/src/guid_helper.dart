import 'package:uuid/uuid.dart';

/// Generates globabally unique IDs
class GuidHelper {
  static final _uuid = Uuid();

  static String createGuid() {
    return _uuid.v4();
  }
}
