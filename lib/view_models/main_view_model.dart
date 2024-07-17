//flutter
import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/view_models/bottom_nav_bar_view_model.dart';
import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//domain
import 'package:apapane/models/firestore_user/firestore_user.dart';
//routes
import 'package:go_router/go_router.dart';

class MainViewModel extends ChangeNotifier {
  final FirestoreRepository _firestoreRepository;
  final AuthRepository _authRepository;

  MainViewModel(this._firestoreRepository, this._authRepository) {
    init();
  }
  bool _isLoading = false;
  late User? _currentUser;
  late DocumentSnapshot<Map<String, dynamic>> _currentUserDoc;
  late FirestoreUser _firestoreUser;
  //tokens
  final List<String> _followingUids = [];

  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  DocumentSnapshot<Map<String, dynamic>> get currentUserDoc => _currentUserDoc;
  FirestoreUser get firestoreUser => _firestoreUser;
  List<String> get followingUids => _followingUids;
  //以下3行がMainModelが起動した時の処理
  //ユーザーの動作を必要としないモデルの関数
  void updateFavoriteCount(bool isLike) {
    if (isLike) {
      firestoreUser.favoriteMyStoryCount + 1;
    } else {
      firestoreUser.favoriteMyStoryCount - 1;
    }
  }

  void setCurrentUser(BottomNavigationBarViewModel bottomNavBarModel) {
    bottomNavBarModel.resetIndex();

    _currentUser = IDCore.authUser();
    bottomNavBarModel.currentIndex = 0;
    notifyListeners();
  }

  //initの中で_currentUserを更新すれば良い
  Future<void> init() async {
    _startLoading();
    _currentUser = IDCore.authUser();
    if (_currentUser == null) {
      _endLoading();
      return;
    }

    final result = await _firestoreRepository
        .getDoc(DocRefCore.publicUserDocRef(_currentUser!.uid));

    result.when(success: (res) {
      _currentUserDoc = res;
      _firestoreUser = FirestoreUser.fromJson(_currentUserDoc.data()!);
      notifyListeners();
    }, failure: (e) async {
      await UIHelper.showFlutterToast('ユーザーの取得に失敗しました');
      debugPrint(e.toString());
      // エラー時の処理を追加
    });

    _endLoading();
  }

  void _startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void _endLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout({
    required BuildContext context,
    required BottomNavigationBarViewModel bottomNavBarViewModel,
  }) async {
    context.pop();
    context.pushReplacement('/login');
    final result = await _authRepository.signOut();
    result.when(success: (_) async {
      await UIHelper.showFlutterToast('ログアウトを完了しました');
    }, failure: (_) async {
      await UIHelper.showFlutterToast('ログアウトに失敗しました');
    });
    setCurrentUser(bottomNavBarViewModel);
  }
}
