import 'package:apapane/local/local_auth_session.dart';
import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

enum LoginProvider {
  google,
  apple,
}

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._authRepository, this._onLoginSuccess);

  final AuthRepository _authRepository;
  final VoidCallback _onLoginSuccess;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> loginWithGoogle({required BuildContext context}) async {
    await _login(context: context, provider: LoginProvider.google);
  }

  Future<void> loginWithApple({required BuildContext context}) async {
    await _login(context: context, provider: LoginProvider.apple);
  }

  Future<void> _login({
    required BuildContext context,
    required LoginProvider provider,
  }) async {
    if (_isLoading) {
      return;
    }

    _startLoading();
    try {
      final result = provider == LoginProvider.apple
          ? await _authRepository.signInWithApple()
          : await _authRepository.signInWithGoogle();

      await result.when(
        success: (_) async {
          _onLoginSuccess();
          if (context.mounted) {
            context.go('/home');
          }
        },
        failure: (error) async {
          final message = _messageForError(error);
          await UIHelper.showFlutterToast(message);
        },
      );
    } catch (error) {
      final message = _messageForError(error);
      await UIHelper.showFlutterToast(message);
    } finally {
      _endLoading();
    }
  }

  String _messageForError(Object? error) {
    if (error is LocalAuthException) {
      switch (error.code) {
        case 'sign_in_canceled':
          return 'ログインをキャンセルしました。';
        case 'unsupported_platform':
          return 'Appleでログインできるのは iPhone / iPad のみです。';
        default:
          return error.message;
      }
    }
    if (error is FirebaseAuthException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Firebase Auth エラー: ${error.code}';
    }
    if (error is PlatformException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return '端末エラー: ${error.code}';
    }
    return 'ログインに失敗しました。';
  }

  void _startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void _endLoading() {
    _isLoading = false;
    notifyListeners();
  }
}
