//flutter
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
//constants
import 'package:apapane/constants/enums.dart';
import 'package:apapane/constants/routes.dart' as routes;
import 'package:apapane/constants/voids.dart' as voids;
import 'package:apapane/constants/others.dart';
//models
import 'package:apapane/model/story_model.dart';

final editProfileProvider = ChangeNotifierProvider((ref) => EditProfileModel());

class EditProfileModel extends ChangeNotifier {
  List<DocumentSnapshot<Map<String, dynamic>>> storyDocs = [];
  final RefreshController refreshController = RefreshController();
  bool isLoading = false;

  Future<void> updateUserName(String newUserName) async {
    final User? currentUser = returnAuthUser();
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'userName': newUserName});
    }
  }

  // Future<void> updateProfileImage() async {
  //   final User? currentUser = returnAuthUser();
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     final CroppedFile? croppedImage = await ImageCropper.cropImage(
  //       sourcePath: image.path,
  //       aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
  //     );
  //     if (croppedImage != null) {
  //       final String fileName = 'profile_${currentUser!.uid}';
  //       final Reference firebaseStorageRef =
  //           FirebaseStorage.instance.ref().child('profile_images/$fileName');
  //       final UploadTask uploadTask =
  //           firebaseStorageRef.putFile(File(croppedImage.path));
  //       final TaskSnapshot taskSnapshot = await uploadTask;
  //       final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(currentUser.uid)
  //           .update({'imageURL': downloadUrl});
  //     }
  //   }
  // }

  Query<Map<String, dynamic>> returnQuery() {
    final User? currentUser = returnAuthUser();
    return FirebaseFirestore.instance
        .collectionGroup('stories')
        .where('uid', isEqualTo: currentUser!.uid)
        .orderBy('createdAt', descending: true);
  }

  editProfileModel() {
    init();
  }

  void init() {
    onReload();
  }

  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void endLoading() {
    isLoading = false;
    notifyListeners();
  }

  Future<void> onRefresh() async {
    refreshController.refreshCompleted();
    await voids.processNewDocs(docs: storyDocs, query: returnQuery());
    notifyListeners();
  }

  Future<void> onReload() async {
    startLoading();
    await voids.processBasicDocs(docs: storyDocs, query: returnQuery());
    endLoading();
  }

  Future<void> onLoading() async {
    refreshController.loadComplete();
    await voids.processOldDocs(docs: storyDocs, query: returnQuery());
    notifyListeners();
  }

  Future<void> getMyStories(
      {required BuildContext context,
      required StoryModel storyModel,
      required DocumentSnapshot<Map<String, dynamic>> storyDoc}) async {
    final List<dynamic> myStoryMaps = storyDoc['stories'] as List<dynamic>;
    storyModel.getTitleTextAndImage(
        title: storyDoc['titleText'], image: storyDoc['titleImage']);
    storyModel.updateStoryMaps(
        newStoryMaps: myStoryMaps.cast<Map<String, dynamic>>());
    storyModel.toStoryPageType = ToStoryPageType.memoryStory;
    routes.toStoryScreen(context: context, isNew: false);
  }
}
