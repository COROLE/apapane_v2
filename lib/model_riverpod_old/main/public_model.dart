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
import 'package:apapane/model_riverpod_old/story_model.dart';

final publicProvider = ChangeNotifierProvider((ref) => PublicModel());

class PublicModel extends ChangeNotifier {
  List<DocumentSnapshot<Map<String, dynamic>>> storyDocs = [];
  List<String> muteUids = [];
  final RefreshController refreshController = RefreshController();
  bool isLoading = false;

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

  void addStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    int insertIndex = storyDocs.indexWhere(
        (doc) => doc['createdAt'].compareTo(storyDoc['createdAt']) < 0);
    if (insertIndex == -1) {
      // If no such element is found, append at the end of the list
      storyDocs.add(storyDoc);
    } else {
      storyDocs.insert(insertIndex, storyDoc);
    }
    notifyListeners();
  }

  void removeStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    storyDocs.removeWhere((doc) => doc['titleText'] == storyDoc['titleText']);
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

  void backToContext(BuildContext context) {
    Navigator.pop(context);
  }
}
