//flutter
import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/models/firestore_user/firestore_user.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/bottom_nav_bar_view_model.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:apapane/ui_core/file_core.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
//constants
import 'package:go_router/go_router.dart';

class EditProfileViewModel extends ChangeNotifier {
  final FirestoreRepository _firestoreRepository;
  EditProfileViewModel(this._firestoreRepository);
  TextEditingController nameController = TextEditingController();
  bool _isLoading = false;
  bool _isChanged = false;
  String newUserName = '';
  dynamic _croppedImage;
  dynamic _oldCroppedImage;

  bool get isLoading => _isLoading;
  bool get isChanged => _isChanged;
  dynamic get croppedImage => _croppedImage;

  void init(MainViewModel mainViewModel) {
    _isLoading = false;
    _isChanged = false;
    final User? currentUser = IDCore.authUser();
    if (currentUser == null) return;
    nameController.text = currentUser.displayName ?? '';
    newUserName = currentUser.displayName ?? '';
    _croppedImage = mainViewModel.firestoreUser.userImageURL;
    _oldCroppedImage = mainViewModel.firestoreUser.userImageURL;
    nameController.addListener(_onNameChanged);
    notifyListeners();
  }

  void _onNameChanged() {
    if (nameController.text.trim() != newUserName) {
      _isChanged = true;
    } else {
      _isChanged = false;
    }
    notifyListeners();
  }

  Future<void> selectImage() async {
    _croppedImage = await FileCore.getImage();
    if (_croppedImage == null) {
      _croppedImage = _oldCroppedImage;
      _isChanged = false;
      return;
    }
    _isChanged = true;
    notifyListeners();
  }

  void saveButtonPressed(
    BuildContext context,
    MainViewModel mainViewModel,
    BottomNavigationBarViewModel bottomNavBarViewModel,
  ) async {
    _startLoading();
    await _updateUserName(mainViewModel.firestoreUser);
    await _updateProfileImage();
    if (_isChanged) {
      mainViewModel.init();
    }
    _endLoading();
    bottomNavBarViewModel.resetIndex();
    // ignore: use_build_context_synchronously
    context.pop();
  }

  Future<void> _updateUserName(FirestoreUser firestoreUser) async {
    final User? currentUser = IDCore.authUser();
    if (currentUser == null) return;
    final String newUserName = nameController.text;
    if (newUserName.trim().isEmpty || newUserName == firestoreUser.userName) {
      return;
    }
    await _updateUserDoc(currentUser.uid, {'userName': newUserName});
    _isChanged = true;
    notifyListeners();
  }

  Future<void> _updateProfileImage() async {
    final User? currentUser = IDCore.authUser();
    if (currentUser == null) return;
    final String uid = currentUser.uid;
    if (_croppedImage == null) return;
    if (_oldCroppedImage == _croppedImage) return;
    final String fileName = IDCore.jpgFileName();
    final result = await _firestoreRepository.uploadImage(
        'users/$uid/profileImages/$fileName', _croppedImage);
    result.when(success: (url) async {
      final downloadUrl = url;
      await _updateUserDoc(uid, {'userImageURL': downloadUrl});
    }, failure: (_) async {
      await UIHelper.showFlutterToast('画像のアップロードに失敗しました');
    });
  }

  Future<void> _updateUserDoc(String uid, SDMap data) async {
    final result = await _firestoreRepository.updateDoc(
        DocRefCore.publicUserDocRef(uid), data);
    result.when(
        success: (_) {},
        failure: (_) async {
          await UIHelper.showFlutterToast('プロフィールの更新に失敗しました');
        });
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    super.dispose();
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
