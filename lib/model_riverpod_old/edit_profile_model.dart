//flutter
import 'dart:typed_data';

import 'package:apapane/constants/strings.dart';
import 'package:apapane/domain/firestore_user/firestore_user.dart';
import 'package:apapane/model_riverpod_old/bottom_nav_bar_model.dart';
import 'package:apapane/model_riverpod_old/main_model.dart';
import 'package:apapane/ui_core/file_core.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/others.dart';

final editProfileProvider = ChangeNotifierProvider((ref) => EditProfileModel());

class EditProfileModel extends ChangeNotifier {
  List<DocumentSnapshot<Map<String, dynamic>>> storyDocs = [];
  final TextEditingController _nameController = TextEditingController();
  TextEditingController get nameController => _nameController;
  bool isLoading = false;
  bool isChanged = false;
  String newUserName = '';
  dynamic croppedImage;
  dynamic oldCroppedImage;

  void init(MainModel mainModel) {
    isLoading = false;
    isChanged = false;
    final User? currentUser = returnAuthUser();
    if (currentUser == null) return;
    _nameController.text = currentUser.displayName ?? '';
    newUserName = currentUser.displayName ?? '';
    croppedImage = mainModel.firestoreUser.userImageURL;
    oldCroppedImage = mainModel.firestoreUser.userImageURL;
    notifyListeners();
  }

  Future<void> selectImage() async {
    croppedImage = await FileCore.getImage();
    if (croppedImage == null) {
      croppedImage = oldCroppedImage;
      isChanged = false;
      return;
    }
    isChanged = true;
    notifyListeners();
  }

  void saveButtonPressed(BuildContext context, MainModel mainModel,
      BottomNavigationBarModel bottomNavigationBarModel) async {
    startLoading();
    await _updateUserName(mainModel.firestoreUser);
    await _updateProfileImage();
    if (isChanged) {
      mainModel.init();
    }
    bottomNavigationBarModel.profileSavedAction();
    endLoading();
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  Future<void> _updateUserName(FirestoreUser firestoreUser) async {
    final User? currentUser = returnAuthUser();
    if (currentUser == null) return;
    final String newUserName = _nameController.text;
    if (newUserName.trim().isEmpty || newUserName == firestoreUser.userName) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'userName': newUserName});
    isChanged = true;
    notifyListeners();
  }

  Future<void> _updateProfileImage() async {
    final User? currentUser = returnAuthUser();
    if (currentUser == null) return;
    if (croppedImage == null) return;
    if (oldCroppedImage == croppedImage) return;
    final String fileName = returnJpgFileName();
    final downloadUrl = await _uploadImageToFirebase(
        activeUid: currentUser.uid,
        imageData: croppedImage!,
        fileName: fileName);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'userImageURL': downloadUrl});
  }

  Future<String> _uploadImageToFirebase({
    required String activeUid,
    required Uint8List imageData,
    required String fileName,
  }) async {
    Reference storageRef =
        FirebaseStorage.instance.ref().child('users/$activeUid/$fileName');
    UploadTask uploadTask = storageRef.putData(imageData);

    // アップロードが完了するのを待つ
    await uploadTask;

    // アップロードが成功したかどうかを確認
    if (uploadTask.snapshot.state == TaskState.success) {
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } else {
      // アップロードが失敗した場合の処理
      throw Exception('ファイルのアップロードに失敗しました');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void endLoading() {
    isLoading = false;
    notifyListeners();
  }
}
