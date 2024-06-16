//flutter
import 'package:flutter/material.dart';
//package
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//constants
import 'package:apapane/constants/strings.dart';
//routes
import 'package:apapane/constants/routes.dart' as routes;
//domain
import 'package:apapane/domain/firestore_user/firestore_user.dart';

final signUpProvider = ChangeNotifierProvider((ref) => SignUpModel());

class SignUpModel extends ChangeNotifier {
  String email = "";
  String password = "";
  bool isObscure = true;

  Future<void> createFirestoreUser(
      {required BuildContext context, required String uid}) async {
    final Timestamp now = Timestamp.now();
    final FirestoreUser firestoreUser = FirestoreUser(
        age: 0,
        createdAt: now,
        followerCount: 0,
        followingCount: 0,
        favoriteMyStoryCount: 0,
        isAdmin: false,
        updatedAt: now,
        userName: 'Alice',
        userImageURL: '',
        uid: uid);
    final Map<String, dynamic> userData = firestoreUser.toJson();

    await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(userCreatedMsg),
      ),
    );
    notifyListeners();
  }

  Future<void> createUser({required BuildContext context}) async {
    try {
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email.trim(), password: password.trim());

      final User? user = result.user;
      final String uid = user!.uid;

      await createFirestoreUser(context: context, uid: uid);
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
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。';
      case 'operation-not-allowed':
        debugPrint(errorCode);
        return '予期せぬエラーが発生しました。';
      case 'invalid-email':
        return 'メールアドレスが無効です。';
      case 'weak-password':
        return 'パスワードが弱すぎます。';
      default:
        debugPrint(errorCode);
        return '予期せぬエラーが発生しました。';
    }
  }

  void toggleIsObscure() {
    isObscure = !isObscure;
    notifyListeners();
  }
}
