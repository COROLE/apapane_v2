//flutter
import 'package:apapane/model_riverpod_old/bottom_nav_bar_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//domain
import 'package:apapane/domain/firestore_user/firestore_user.dart';
//constants
import 'package:apapane/constants/others.dart';
//routes
import 'package:apapane/constants/routes.dart' as routes;

final mainProvider = ChangeNotifierProvider((ref) => MainModel());

class MainModel extends ChangeNotifier {
  bool isLoading = false;
  late User? currentUser;
  late DocumentSnapshot<Map<String, dynamic>> currentUserDoc;
  late FirestoreUser firestoreUser;
  //tokens
  List<String> followingUids = [];
  List<String> likePostIds = [];

  //以下3行がMainModelが起動した時の処理
  //ユーザーの動作を必要としないモデルの関数
  MainModel() {
    init();
  }
  void setCurrentUser(bottomNavBarModel) {
    currentUser = FirebaseAuth.instance.currentUser;
    bottomNavBarModel.currentIndex = 0;
    notifyListeners();
  }

  //initの中でcurrentUserを更新すれば良い
  Future<void> init() async {
    startLoading();
    currentUser = returnAuthUser();
    currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    firestoreUser = FirestoreUser.fromJson(currentUserDoc.data()!);
    //currentUserのuidの取得が可能になる
    notifyListeners();
    endLoading();
  }

  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void endLoading() {
    isLoading = false;
    notifyListeners();
  }

  Future<void> logout({
    required BuildContext context,
    required BottomNavigationBarModel bottomNavBarModel,
  }) async {
    Navigator.of(context).pop();
    routes.toLoginSignupScreen(context: context);
    await FirebaseAuth.instance.signOut();
    setCurrentUser(bottomNavBarModel);
  }
}
