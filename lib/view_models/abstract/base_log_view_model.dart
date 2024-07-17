import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/ui_helper.dart';

abstract class BaseLogViewModel extends ChangeNotifier {
  final FirestoreRepository firestoreRepository;

  BaseLogViewModel(this.firestoreRepository) {
    init();
  }

  List<DocumentSnapshot<Map<String, dynamic>>> storyDocs = [];
  final RefreshController refreshController = RefreshController();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void init() {
    onReload();
  }

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void endLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addStoryDoc(MapQuery query) async {
    final result = await firestoreRepository.getDocs(query);
    result.when(success: (qDocs) {
      for (final doc in qDocs) {
        storyDocs.add(doc);
      }
    }, failure: (_) async {
      await UIHelper.showFlutterToast('取得できませんでした。');
    });
  }

  Future<void> onRefresh();
  Future<void> onReload();
  Future<void> onLoading();

  void addStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    int insertIndex = storyDocs.indexWhere(
        (doc) => doc['createdAt'].compareTo(storyDoc['createdAt']) < 0);
    if (insertIndex == -1) {
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

  Future<void> getMyStories({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  });
}
