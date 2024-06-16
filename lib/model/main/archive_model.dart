//flutter
import 'package:apapane/domain/story/story.dart';
import 'package:apapane/model/main_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
//constants
import 'package:apapane/constants/enums.dart';
import 'package:apapane/constants/routes.dart' as routes;
import 'package:apapane/constants/voids.dart' as voids;
import 'package:apapane/constants/others.dart';
//models
import 'package:apapane/model/story_model.dart';

final archiveProvider = ChangeNotifierProvider((ref) => ArchiveModel());

class ArchiveModel extends ChangeNotifier {
  List<DocumentSnapshot<Map<String, dynamic>>> storyDocs = [];
  List<String> favoriteStoryIds = [];
  List<String> muteUids = [];
  final RefreshController refreshController = RefreshController();
  bool isLoading = false;
  int maxFavoriteCount = 5;
  bool isFavoriteLoading = false;

  Query<Map<String, dynamic>> returnQuery() {
    final User? currentUser = returnAuthUser();
    // ユーザーのchatLogs内の全てのstoriesを取得するために、
    // FirebaseFirestore.instanceから直接.collectionGroup('stories')を使用します。
    return FirebaseFirestore.instance
        .collectionGroup('stories') // ここを修正しました
        .where('uid', isEqualTo: currentUser!.uid) // userIdフィールドでフィルタリング
        .orderBy('createdAt', descending: true);
  }

  Query<Map<String, dynamic>> returnFavoriteQuery() {
    final User? currentUser = returnAuthUser();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('favoriteStories');
  }

  ArchiveModel() {
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

  void startFavoriteLoading() {
    isFavoriteLoading = true;
    notifyListeners();
  }

  void endFavoriteLoading() {
    isFavoriteLoading = false;
    notifyListeners();
  }

  Future<void> onRefresh() async {
    refreshController.refreshCompleted();
    await voids.processNewDocs(
        muteUids: muteUids, docs: storyDocs, query: returnQuery());
    notifyListeners();
  }

  Future<void> onReload() async {
    startLoading();
    await voids.processBasicDocs(
        muteUids: muteUids, docs: storyDocs, query: returnQuery());
    final query = returnFavoriteQuery();
    final qshot = await query.limit(5).get();
    qshot.docs
        .map((e) => favoriteStoryIds.add(e.id))
        .toList(); // Changed from adding the whole document to just the storyId
    notifyListeners();
    endLoading();
  }

  Future<void> onLoading() async {
    refreshController.loadComplete();
    await voids.processOldDocs(
        muteUids: muteUids, docs: storyDocs, query: returnQuery());
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

  Future<void> like(
      {required BuildContext context,
      required StoryModel storyModel,
      required MainModel mainModel,
      required int index}) async {
    // Optionally, perform the backend update asynchronously without waiting for it
    try {
      if (favoriteStoryIds.length < maxFavoriteCount) {
        startFavoriteLoading();
        favoriteStoryIds.add(storyDocs[index].id);
        notifyListeners();
        final List<dynamic> storiesDynamic = storyDocs[index]['stories'];
        final List<Map<String, dynamic>> stories =
            storiesDynamic.cast<Map<String, dynamic>>();
        debugPrint('favoriteStoryIds: $favoriteStoryIds');
        final String storyId = storyDocs[index].id;
        final favoriteStoriesRef = userDocToFavoriteStoriesRef(
            userDoc: mainModel.currentUserDoc, storyId: storyId);
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
        await favoriteStoriesRef.set(story.toJson());
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(mainModel.currentUser!.uid);
        await userRef.update({'favoriteMyStoryCount': favoriteStoryIds.length});
        mainModel.firestoreUser.favoriteMyStoryCount + 1;
      } else {
        voids.showFluttertoast(msg: 'おきにいりは5つまでだよ!');
        return;
      }
    } catch (e) {
      voids.showFluttertoast(msg: 'エラーが発生しました。');
      debugPrint('Error: $e');
    }
    endFavoriteLoading();
  }

  Future<void> unlike(
      {required BuildContext context,
      required StoryModel storyModel,
      required MainModel mainModel,
      required int index}) async {
    // Check if the story is already in the favorites list
    final String storyId = storyDocs[index].id;
    if (favoriteStoryIds.contains(storyId)) {
      startFavoriteLoading();
      // Remove from local favorites list
      favoriteStoryIds.remove(storyId);
      notifyListeners();

      // Remove the story from the user's favorite stories in Firestore
      final favoriteStoriesRef = userDocToFavoriteStoriesRef(
          userDoc: mainModel.currentUserDoc, storyId: storyId);
      await favoriteStoriesRef.delete();
      // Update the favorite count in the user's document
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(mainModel.currentUser!.uid);
      await userRef.update({'favoriteMyStoryCount': favoriteStoryIds.length});
      mainModel.firestoreUser.favoriteMyStoryCount - 1;
    } else {
      voids.showFluttertoast(msg: 'このストーリーはお気に入りに追加されていません。');
    }
    endFavoriteLoading();
  }

  void backToContext(BuildContext context) {
    Navigator.pop(context);
  }
}
