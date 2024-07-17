//flutter
import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apapane/views/profile_screen/components/profile_component.dart';
import 'package:go_router/go_router.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirestoreRepository _firestoreRepository;
  ProfileViewModel(this._firestoreRepository) {
    init();
  }
  List<DocumentSnapshot<Map<String, dynamic>>> favoriteStoryDocs = [];
  late List<Widget> _imagesList;
  final List<String> _imagesPictureList = [
    'assets/images/volt_boy.png',
    'assets/images/pirates.png',
    'assets/images/dragon_boy.png',
    'assets/images/fairy.png',
    'assets/images/girl_rabbit.png',
    'assets/images/venture.png',
  ]..shuffle();

  List<Widget> get imagesList => _imagesList;

  Future<void> _loadFavoriteStories() async {
    final User? currentUser = IDCore.authUser();
    if (currentUser == null) {
      return await UIHelper.showFlutterToast('ユーザーが見つかりません');
    }
    final result = await _firestoreRepository
        .getDocs(ColRefCore.favoriteStoriesColRef(currentUser.uid).limit(5));
    result.when(success: (docs) {
      docs.map((e) => favoriteStoryDocs.add(e)).toList();
    }, failure: (_) async {
      await UIHelper.showFlutterToast('取得できませんでした。');
    });
  }

  void init() {
    _imagesList =
        _imagesPictureList.map((e) => ProfileComponent(image: e)).toList();
    onReload();
  }

  void addFavoriteStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    favoriteStoryDocs.add(storyDoc);
    notifyListeners();
  }

  void removeFavoriteStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    favoriteStoryDocs
        .removeWhere((doc) => doc['titleText'] == storyDoc['titleText']);
    notifyListeners();
  }

  Future<void> onReload() async {
    await _loadFavoriteStories();
    notifyListeners();
  }

  Future<void> getMyStories(
      {required BuildContext context,
      required StoryViewModel storyViewModel,
      required DocumentSnapshot<Map<String, dynamic>> storyDoc}) async {
    final List<dynamic> myStoryMaps = storyDoc['stories'] as List<dynamic>;
    storyViewModel.getTitleTextAndImage(
        title: storyDoc['titleText'], image: storyDoc['titleImage']);
    storyViewModel.updateStoryMaps(
        newStoryMaps: myStoryMaps.cast<Map<String, dynamic>>());
    storyViewModel.toStoryPageType = ToStoryPageType.memoryStory;
    context.push('/story?isNew=false');
  }
}
