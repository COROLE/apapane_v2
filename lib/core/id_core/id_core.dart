import 'package:apapane/local/local_auth_session.dart';
import 'package:apapane/models/auth/local_session_user.dart';
import 'package:uuid/uuid.dart';

class IDCore {
  static String uuidV4() {
    const uuid = Uuid();
    return uuid.v4();
  }

  static LocalSessionUser? authUser() => LocalAuthSession.instance.currentUser;

  static String jpgFileName() => '${uuidV4()}.jpg';
}
