//flutter
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//routes
import 'package:apapane/constants/routes.dart' as routes;

final loginProvider = ChangeNotifierProvider((ref) => LoginModel());

class LoginModel extends ChangeNotifier {
  String email = "";
  String password = "";
  bool isObscure = true;

  Future<void> login({required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      routes.toMyApp(context: context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'ユーザーが見つかりません。';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'invalid-email':
      case 'invalid-credential':
        return 'メールアドレスが無効です。';
      default:
        debugPrint(errorCode);
        return 'パスワード、メールアドレスが間違っています。';
    }
  }

  void toggleIsObscure() {
    isObscure = !isObscure;
    notifyListeners();
  }
}
