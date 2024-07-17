import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class IDCore {
  static String uuidV4() {
    const uuid = Uuid();
    final result = uuid.v4();
    return result;
  }

  static User? authUser() => FirebaseAuth.instance.currentUser;

  static String jpgFileName() => "${uuidV4()}.jpg";
}
