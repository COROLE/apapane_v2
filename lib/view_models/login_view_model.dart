//flutter
import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
//routes
import 'package:go_router/go_router.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);
  String email = "";
  String password = "";
  bool _isObscure = true;

  bool get isObscure => _isObscure;

  Future<void> login({required BuildContext context}) async {
    final result = await _authRepository.signInWithEmailAndPassword(
        email.trim(), password.trim());
    result.when(success: (_) {
      if (context.mounted) {
        context.pushReplacement('/login/redirection');
      }
    }, failure: (error) async {
      final errorMessage = _getErrorMessage(error ?? 'Unknown error');

      await UIHelper.showFlutterToast(errorMessage);
    });
  }

  String _getErrorMessage(Object? error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'ユーザーが見つかりません。';
        case 'wrong-password':
          return '無効なパスワードです';
        case 'invalid-email':
          return '無効なメールアドレスです';
        case 'invalid-credential':
          return 'パスワード、メールアドレスが間違っています。';
        default:
          debugPrint(error.code);
          return 'エラーが発生しました';
      }
    }
    return '不明なエラーが発生しました。';
  }

  void toggleIsObscure() {
    _isObscure = !_isObscure;
    notifyListeners();
  }
}
