//flutter
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
  List<String> muteUids = [];
  final RefreshController refreshController = RefreshController();
  bool isLoading = false;

  Query<Map<String, dynamic>> returnQuery() {
    final User? currentUser = returnAuthUser();
    // ユーザーのchatLogs内の全てのstoriesを取得するために、
    // FirebaseFirestore.instanceから直接.collectionGroup('stories')を使用します。
    return FirebaseFirestore.instance
        .collectionGroup('stories') // ここを修正しました
        .where('uid', isEqualTo: currentUser!.uid) // userIdフィールドでフィルタリング
        .orderBy('createdAt', descending: true);
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
