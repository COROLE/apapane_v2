import 'package:apapane/local/local_auth_session.dart';
import 'package:apapane/models/auth/local_session_user.dart';

class AuthService {
  Future<LocalSessionUser?> restoreSession() async {
    await LocalAuthSession.instance.restore();
    return LocalAuthSession.instance.currentUser;
  }

  Future<LocalSessionUser> signInWithGoogle() async {
    return LocalAuthSession.instance.signInWithGoogle();
  }

  Future<LocalSessionUser> signInWithApple() async {
    return LocalAuthSession.instance.signInWithApple();
  }

  Future<void> signOut() async {
    await LocalAuthSession.instance.signOut();
  }

  Future<void> updateCurrentUser({
    String? displayName,
    String? photoUrl,
  }) async {
    await LocalAuthSession.instance.updateCurrentUser(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  Future<void> deleteCurrentUser() async {
    await LocalAuthSession.instance.deleteCurrentUser();
  }
}
