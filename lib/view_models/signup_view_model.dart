//flutter
import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';
//package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//constants
import 'package:apapane/constants/strings.dart';
//domain
import 'package:apapane/models/firestore_user/firestore_user.dart';
import 'package:go_router/go_router.dart';

class SignUpViewModel extends ChangeNotifier {
  final FirestoreRepository _firestoreRepository;
  final AuthRepository _authRepository;

  SignUpViewModel(this._firestoreRepository, this._authRepository);
  String email = "";
  String password = "";
  bool _isObscure = true;

  bool get isObscure => _isObscure;

  Future<void> _createFirestoreUser(
      {required BuildContext context, required String uid}) async {
    final Timestamp now = Timestamp.now();
    final FirestoreUser firestoreUser = FirestoreUser(
        age: 0,
        createdAt: now,
        updatedAt: now,
        userName: '',
        userImageURL: '',
        uid: uid);
    final Map<String, dynamic> userData = firestoreUser.toJson();
    final result = await _firestoreRepository.createDoc(
        ColRefCore.publicUsersColRef().doc(uid), userData);
    result.when(
        success: (_) async {
          await UIHelper.showFlutterToast(userCreatedMsg);
        },
        failure: (e) {});
  }

  Future<void> createUser(BuildContext context) async {
    final result = await _authRepository.createUserWithEmailAndPassword(
        email.trim(), password.trim());
    result.when(
      success: (res) async {
        final String uid = res.uid;
        // ignore: use_build_context_synchronously
        await _createFirestoreUser(context: context, uid: uid);
        // ignore: use_build_context_synchronously
        if (context.mounted) {
          context.pushReplacement('/login/redirection');
        }
      },
      failure: (error) async {
        String errorMessage = _getErrorMessage(error ?? 'Unknown error');
        await UIHelper.showFlutterToast(errorMessage);
      },
    );
  }

  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています。';
        case 'operation-not-allowed':
          debugPrint(error.code);
          return '予期せぬエラーが発生しました。';
        case 'invalid-email':
          return 'メールアドレスが無効です。';
        case 'weak-password':
          return 'パスワードが弱すぎます。';
        default:
          debugPrint(error.code);
          return '予期せぬエラーが発生しました。';
      }
    } else if (error is String) {
      return error;
    } else {
      debugPrint(error.toString());
      return '予期せぬエラーが発生しました。';
    }
  }

  void toggleIsObscure() {
    _isObscure = !_isObscure;
    notifyListeners();
  }
}
