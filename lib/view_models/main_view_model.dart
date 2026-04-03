import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/local/local_auth_session.dart';
import 'package:apapane/local/local_firestore.dart';
import 'package:apapane/models/auth/local_session_user.dart';
import 'package:apapane/models/firestore_user/firestore_user.dart';
import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/bottom_nav_bar_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainViewModel extends ChangeNotifier {
  MainViewModel(this._firestoreRepository, this._authRepository) {
    init();
  }

  final FirestoreRepository _firestoreRepository;
  final AuthRepository _authRepository;

  bool _isLoading = false;
  LocalSessionUser? _currentUser;
  DocumentSnapshot<Map<String, dynamic>>? _currentUserDoc;
  FirestoreUser? _firestoreUser;
  final List<String> _followingUids = [];

  bool get isLoading => _isLoading;
  LocalSessionUser? get currentUser => _currentUser;
  DocumentSnapshot<Map<String, dynamic>> get currentUserDoc => _currentUserDoc!;
  FirestoreUser get firestoreUser => _firestoreUser!;
  List<String> get followingUids => _followingUids;
  bool get isGuestMode => _currentUser == null || _currentUser!.isGuest;
  bool get hasSyncedAccount =>
      _currentUser != null && !_currentUser!.isGuest && _firestoreUser != null;
  String get displayName => hasSyncedAccount
      ? firestoreUser.userName
      : (_currentUser?.displayName.trim().isNotEmpty == true
          ? _currentUser!.displayName
          : 'ゲスト');

  void updateFavoriteCount(bool isLike) {
    final user = _firestoreUser;
    if (user == null) {
      return;
    }
    _firestoreUser = user.copyWith(
      favoriteMyStoryCount: isLike
          ? user.favoriteMyStoryCount + 1
          : (user.favoriteMyStoryCount - 1).clamp(0, 999999),
    );
    notifyListeners();
  }

  void setCurrentUser(BottomNavigationBarViewModel bottomNavBarModel) {
    bottomNavBarModel.resetIndex();
    _currentUser = IDCore.authUser();
    bottomNavBarModel.currentIndex = 0;
    notifyListeners();
  }

  Future<void> init() async {
    _startLoading();
    _currentUser = IDCore.authUser();
    if (_currentUser == null || _currentUser!.isGuest) {
      _currentUserDoc = null;
      _firestoreUser = null;
      _endLoading();
      return;
    }

    final result = await _firestoreRepository.getDoc(
      DocRefCore.publicUserDocRef(_currentUser!.uid),
    );

    result.when(
      success: (doc) {
        final data = doc.data();
        if (data == null) {
          _currentUserDoc = null;
          _firestoreUser = null;
          return;
        }
        _currentUserDoc = doc;
        _firestoreUser = FirestoreUser.fromJson(data);
      },
      failure: (error) async {
        await UIHelper.showFlutterToast('プロフィールの読み込みに失敗しました。');
        debugPrint(error.toString());
      },
    );

    _endLoading();
  }

  Future<void> logout({
    required BuildContext context,
    required BottomNavigationBarViewModel bottomNavBarViewModel,
  }) async {
    context.pop();
    final result = await _authRepository.signOut();
    result.when(
      success: (_) async {
        await UIHelper.showFlutterToast('ログアウトしました。');
      },
      failure: (_) async {
        await UIHelper.showFlutterToast('ログアウトに失敗しました。');
      },
    );
    await LocalAuthSession.instance.ensureGuestSession();
    _currentUser = IDCore.authUser();
    _currentUserDoc = null;
    _firestoreUser = null;
    setCurrentUser(bottomNavBarViewModel);
    if (context.mounted) {
      context.go('/home');
    }
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
