import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/local/local_firestore.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:apapane/views/profile_screen/components/profile_component.dart';
import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._firestoreRepository) {
    init();
  }

  final FirestoreRepository _firestoreRepository;

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

  void init() {
    _imagesList =
        _imagesPictureList.map((e) => ProfileComponent(image: e)).toList();
    onReload();
  }

  Future<void> _loadFavoriteStories() async {
    final currentUser = IDCore.authUser();
    if (currentUser == null) {
      favoriteStoryDocs = [];
      return;
    }

    final result = await _firestoreRepository.getDocs(
      ColRefCore.favoriteStoriesColRef(currentUser.uid).limit(5),
    );
    result.when(
      success: (docs) {
        favoriteStoryDocs = docs;
      },
      failure: (_) async {
        await UIHelper.showFlutterToast('お気に入りの読込に失敗しました');
      },
    );
  }

  void addFavoriteStoryDocs({
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) {
    favoriteStoryDocs.removeWhere((doc) => doc.id == storyDoc.id);
    favoriteStoryDocs.add(storyDoc);
    notifyListeners();
  }

  void removeFavoriteStoryDocs({
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) {
    favoriteStoryDocs.removeWhere((doc) => doc.id == storyDoc.id);
    notifyListeners();
  }

  Future<void> onReload() async {
    await _loadFavoriteStories();
    notifyListeners();
  }

  Future<void> getMyStories({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) async {
    await storyViewModel.openSavedStory(
      context: context,
      storyDoc: storyDoc,
    );
  }
}
