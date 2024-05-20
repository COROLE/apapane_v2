//flutter
import 'package:flutter/material.dart';
//packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
//constants
import 'package:apapane/constants/enums.dart';
import 'package:apapane/constants/routes.dart' as routes;
import 'package:apapane/constants/voids.dart' as voids;
//models
import 'package:apapane/model/story_model.dart';

final publicProvider = ChangeNotifierProvider((ref) => PublicModel());

class PublicModel extends ChangeNotifier {
  List<DocumentSnapshot<Map<String, dynamic>>> storyDocs = [];
  List<String> muteUids = [];
  final RefreshController refreshController = RefreshController();
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _storiesCache = {};

  Query<Map<String, dynamic>> returnQuery() {
    // FirebaseFirestore.instanceから直接.collectionGroup('stories')を使用します。
    return FirebaseFirestore.instance
        .collectionGroup('stories') // ここを修正しました
        .where('isPublic', isEqualTo: true) // isPublicフィールドでフィルタリング
        .orderBy('createdAt', descending: true);
  }

  PublicModel() {
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
    await voids.processNewDocs(
        muteUids: muteUids, docs: storyDocs, query: returnQuery());
    notifyListeners();
  }

  Future<void> onReload() async {
    startLoading();
    await voids.processBasicDocs(
        muteUids: muteUids, docs: storyDocs, query: returnQuery());
    endLoading();
  }

  Future<void> onLoading() async {
    refreshController.loadComplete();
    await voids.processOldDocs(
        muteUids: muteUids, docs: storyDocs, query: returnQuery());
    notifyListeners();
  }

  Future<void> getMyStories({
    required BuildContext context,
    required StoryModel storyModel,
    required DocumentSnapshot storyDoc,
  }) async {
    String storyId = storyDoc.id;
    if (_storiesCache.containsKey(storyId)) {
      // キャッシュからデータを取得し、リストに変換して渡す
      storyModel.updateStoryMaps(newStoryMaps: [_storiesCache[storyId]]);
    } else {
      // データベースからデータを取得
      DocumentSnapshot snapshot =
          await _firestore.collection('stories').doc(storyId).get();
      if (snapshot.exists) {
        Map<String, dynamic> storyData =
            snapshot.data() as Map<String, dynamic>;
        _storiesCache[storyId] = storyData; // キャッシュにデータを保存
        // データをリストに変換して渡す
        storyModel.updateStoryMaps(newStoryMaps: [storyData]);
      }
    }
  }

  void backToContext(BuildContext context) {
    Navigator.pop(context);
  }
}
