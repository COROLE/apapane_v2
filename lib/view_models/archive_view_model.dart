//flutter
import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/firestore/query_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/models/story/story.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:apapane/view_models/abstract/base_log_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ArchiveViewModel extends BaseLogViewModel {
  final FirestoreRepository _firestoreRepository;

  ArchiveViewModel(this._firestoreRepository) : super(_firestoreRepository);

  List<String> favoriteStoryIds = [];
  List<String> publicStoryIds = [];
  int maxFavoriteCount = 5;
  bool _isFavoriteLoading = false;

  bool get isFavoriteLoading => _isFavoriteLoading;

  void _startFavoriteLoading() {
    _isFavoriteLoading = true;
    notifyListeners();
  }

  void _endFavoriteLoading() {
    _isFavoriteLoading = false;
    notifyListeners();
  }

  @override
  Future<void> onRefresh() async {
    refreshController.refreshCompleted();
    final currentUser = IDCore.authUser();
    if (currentUser == null) return;
    await addStoryDoc(
        QueryCore.newStoriesCollectionQuery(currentUser, storyDocs, true));
    updatePublicStoryIds();
    notifyListeners();
  }

  @override
  Future<void> onReload() async {
    startLoading();
    final currentUser = IDCore.authUser();
    if (currentUser == null) return;
    await addStoryDoc(QueryCore.archiveStoriesCollectionQuery(currentUser));
    updatePublicStoryIds();
    await updateFavoriteStoryIds(currentUser);
    notifyListeners();
    endLoading();
  }

  @override
  Future<void> onLoading() async {
    refreshController.loadComplete();
    final currentUser = IDCore.authUser();
    if (currentUser == null) return;
    await addStoryDoc(
        QueryCore.oldStoriesCollectionQuery(currentUser, storyDocs, true));
    updatePublicStoryIds();
    notifyListeners();
  }

  void updatePublicStoryIds() {
    publicStoryIds = storyDocs
        .where((element) => element['isPublic'] == true)
        .map((e) => e.id)
        .toList();
  }

  Future<void> updateFavoriteStoryIds(User currentUser) async {
    final result = await _firestoreRepository
        .getDocs(ColRefCore.favoriteStoriesColRef(currentUser.uid).limit(5));
    result.when(
      success: (qShot) {
        favoriteStoryIds = qShot.map((e) => e.id).toList();
      },
      failure: (_) async {
        await UIHelper.showFlutterToast('取得できませんでした。');
      },
    );
  }

  @override
  Future<void> getMyStories({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) async {
    final List<dynamic> myStoryMaps = storyDoc['stories'] as List<dynamic>;
    storyViewModel.getTitleTextAndImage(
        title: storyDoc['titleText'], image: storyDoc['titleImage']);
    storyViewModel.updateStoryMaps(
        newStoryMaps: myStoryMaps.cast<Map<String, dynamic>>());
    storyViewModel.toStoryPageType = ToStoryPageType.memoryStory;
    context.push('/story?isNew=false');
  }

  Future<void> _updateLikeFunction(
      MainViewModel mainViewModel, bool isLike) async {
    final result = await _firestoreRepository.updateDoc(
        DocRefCore.publicUserDocRef(mainViewModel.currentUser!.uid),
        {'favoriteMyStoryCount': favoriteStoryIds.length});

    result.when(success: (_) {
      mainViewModel.updateFavoriteCount(isLike);
    }, failure: (_) async {
      await UIHelper.showFlutterToast(
          isLike ? 'いいねの登録に失敗しました' : 'いいねの削除に失敗しました');
    });
  }

  Future<void> updateFavorite({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required MainViewModel mainViewModel,
    required int index,
    required bool isLike,
  }) async {
    final String storyId = storyDocs[index].id;

    if (isLike) {
      if (favoriteStoryIds.length >= maxFavoriteCount) {
        await UIHelper.showFlutterToast('おきにいりは5つまでだよ!');
        return;
      }
      _startFavoriteLoading();
      favoriteStoryIds.add(storyId);
      notifyListeners();

      final List<dynamic> storiesDynamic = storyDocs[index]['stories'];
      final List<Map<String, dynamic>> stories =
          storiesDynamic.cast<Map<String, dynamic>>();
      final story = Story(
          createdAt: Timestamp.now(),
          chatLogRef: storyDocs[index]['chatLogRef'],
          isPublic: storyDocs[index]['isPublic'],
          stories: stories,
          storyId: storyId,
          titleImage: storyDocs[index]['titleImage'],
          titleText: storyDocs[index]['titleText'],
          uid: storyDocs[index]['uid'],
          userImageURL: storyDocs[index]['userImageURL'],
          userName: storyDocs[index]['userName'],
          updatedAt: Timestamp.now());
      try {
        final result = await _firestoreRepository.createDoc(
            ColRefCore.favoriteStoriesColRef(mainViewModel.currentUser!.uid)
                .doc(storyId),
            story.toJson());
        result.when(
            success: (_) {
              _updateLikeFunction(mainViewModel, true);
            },
            failure: (_) async =>
                await UIHelper.showFlutterToast('いいねの登録に失敗しました'));
      } catch (e) {
        await UIHelper.showFlutterToast('エラーが発生しました。');
        debugPrint('Error: $e');
      }
    } else {
      if (!favoriteStoryIds.contains(storyId)) {
        await UIHelper.showFlutterToast('このストーリーはお気に入りに追加されていません。');
        return;
      }
      _startFavoriteLoading();
      favoriteStoryIds.remove(storyId);
      notifyListeners();

      try {
        final result = await _firestoreRepository.deleteDoc(
            ColRefCore.favoriteStoriesColRef(mainViewModel.currentUser!.uid)
                .doc(storyId));
        result.when(
            success: (_) {
              _updateLikeFunction(mainViewModel, false);
            },
            failure: (_) async =>
                await UIHelper.showFlutterToast('いいねの削除に失敗しました'));
      } catch (e) {
        await UIHelper.showFlutterToast('エラーが発生しました。');
        debugPrint('Error: $e');
      }
    }
    _endFavoriteLoading();
  }

  Future<void> updatePublicMode({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required int index,
    required bool isOn,
  }) async {
    if (isOn) {
      publicStoryIds.add(storyDocs[index].id);
    } else {
      publicStoryIds.remove(storyDocs[index].id);
    }
    notifyListeners();
    final String storyId = storyDocs[index].id;
    final user = IDCore.authUser();
    if (user == null) return;

    final result = await _firestoreRepository.updateDoc(
        DocRefCore.storyDocRef(user.uid, storyId),
        isOn ? {'isPublic': true} : {'isPublic': false});

    result.when(
        success: (_) async {
          if (isOn) {
            await UIHelper.showFlutterToast('みんなにみせるね！');
          } else {
            await UIHelper.showFlutterToast('みんなにはみせないようにするね！');
          }
        },
        failure: (_) async => await UIHelper.showFlutterToast('アップデートに失敗しました'));
  }
}
