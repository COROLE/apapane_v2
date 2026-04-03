import 'package:apapane/config/app_env.dart';
import 'package:apapane/enums/env_key.dart';
import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/file_core.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/bottom_nav_bar_view_model.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._firestoreRepository, this._authRepository);

  final FirestoreRepository _firestoreRepository;
  final AuthRepository _authRepository;

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
    final currentUser = IDCore.authUser();
    if (currentUser == null) {
      return;
    }
    final currentName = mainViewModel.firestoreUser.userName.trim().isEmpty
        ? currentUser.displayName
        : mainViewModel.firestoreUser.userName;
    nameController.text = currentName;
    newUserName = currentName;
    _croppedImage = mainViewModel.firestoreUser.userImageURL;
    _oldCroppedImage = mainViewModel.firestoreUser.userImageURL;
    nameController.removeListener(_onNameChanged);
    nameController.addListener(_onNameChanged);
    notifyListeners();
  }

  void _onNameChanged() {
    _isChanged = nameController.text.trim() != newUserName ||
        _croppedImage != _oldCroppedImage;
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

  Future<void> saveButtonPressed(
    BuildContext context,
    MainViewModel mainViewModel,
    BottomNavigationBarViewModel bottomNavBarViewModel,
  ) async {
    _startLoading();
    await _updateUserName(mainViewModel);
    await _updateProfileImage(mainViewModel);
    if (_isChanged) {
      await mainViewModel.init();
    }
    _endLoading();
    bottomNavBarViewModel.resetIndex();
    if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _updateUserName(MainViewModel mainViewModel) async {
    final currentUser = IDCore.authUser();
    if (currentUser == null) {
      return;
    }

    final updatedName = nameController.text.trim();
    if (updatedName.isEmpty ||
        updatedName == mainViewModel.firestoreUser.userName) {
      return;
    }

    await _updateUserDoc(
      currentUser.uid,
      {'userName': updatedName},
    );
    await _authRepository.updateCurrentUser(displayName: updatedName);
    _isChanged = true;
    notifyListeners();
  }

  Future<void> _updateProfileImage(MainViewModel mainViewModel) async {
    final currentUser = IDCore.authUser();
    if (currentUser == null || _croppedImage == null) {
      return;
    }
    if (_oldCroppedImage == _croppedImage) {
      return;
    }

    final fileName = IDCore.jpgFileName();
    final result = await _firestoreRepository.uploadImage(
      'users/${currentUser.uid}/profileImages/$fileName',
      _croppedImage,
    );
    await result.when(
      success: (path) async {
        await _updateUserDoc(currentUser.uid, {'userImageURL': path});
        await _authRepository.updateCurrentUser(photoUrl: path);
      },
      failure: (_) async {
        await UIHelper.showFlutterToast('プロフィール画像を保存できませんでした。');
      },
    );
  }

  Future<void> _updateUserDoc(String uid, SDMap data) async {
    final result = await _firestoreRepository.updateDoc(
      DocRefCore.publicUserDocRef(uid),
      data,
    );
    result.when(
      success: (_) {},
      failure: (_) async {
        await UIHelper.showFlutterToast('プロフィールを更新できませんでした。');
      },
    );
  }

  Future<void> openPrivacyPolicy() async {
    await _launchExternalUrl(EnvKey.PRIVACY_POLICY_URL);
  }

  Future<void> openTermsOfService() async {
    await _launchExternalUrl(EnvKey.TERMS_OF_SERVICE_URL);
  }

  Future<void> openSupportEmail() async {
    final email = AppEnv.get(EnvKey.SUPPORT_EMAIL).trim();
    if (email.isEmpty) {
      await UIHelper.showFlutterToast('お問い合わせ先メールアドレスが設定されていません。');
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: const {
        'subject': 'アパパネに関するお問い合わせ',
      },
    );
    final launched = await launchUrl(uri);
    if (!launched) {
      await UIHelper.showFlutterToast('メールアプリを開けませんでした。');
    }
  }

  Future<void> deleteAccountPressed(
    BuildContext context,
    MainViewModel mainViewModel,
    BottomNavigationBarViewModel bottomNavBarViewModel,
  ) async {
    _startLoading();
    final result = await _authRepository.deleteCurrentUser();
    _endLoading();

    await result.when(
      success: (_) async {
        bottomNavBarViewModel.resetIndex();
        await mainViewModel.init();
        if (context.mounted) {
          context.go('/home');
        }
      },
      failure: (error) async {
        await UIHelper.showFlutterToast(error.toString());
      },
    );
  }

  Future<void> _launchExternalUrl(EnvKey key) async {
    final raw = AppEnv.get(key).trim();
    if (raw.isEmpty) {
      await UIHelper.showFlutterToast('${_labelForKey(key)}が設定されていません。');
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      await UIHelper.showFlutterToast('${_labelForKey(key)}のURLが正しくありません。');
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await UIHelper.showFlutterToast('${_labelForKey(key)}を開けませんでした。');
    }
  }

  String _labelForKey(EnvKey key) {
    switch (key) {
      case EnvKey.PRIVACY_POLICY_URL:
        return 'プライバシーポリシー';
      case EnvKey.TERMS_OF_SERVICE_URL:
        return '利用規約';
      case EnvKey.SUPPORT_EMAIL:
        return 'お問い合わせ先';
      default:
        return key.name;
    }
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
