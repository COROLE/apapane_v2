import 'package:apapane/local/local_firestore.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

abstract class BaseLogViewModel extends ChangeNotifier {
  BaseLogViewModel(this.firestoreRepository) {
    init();
  }

  final FirestoreRepository firestoreRepository;

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
    result.when(
      success: (qDocs) {
        for (final doc in qDocs) {
          storyDocs.removeWhere((existing) => existing.id == doc.id);
          storyDocs.add(doc);
        }
        storyDocs.sort(
          (left, right) => (right['createdAt'] as Timestamp)
              .compareTo(left['createdAt'] as Timestamp),
        );
      },
      failure: (error) async {
        final rawMessage = error?.toString() ?? '';
        if (rawMessage.contains('index') ||
            rawMessage.contains('failed-precondition')) {
          await UIHelper.showFlutterToast(
            'ストーリー一覧の準備中です。少し待ってからもう一度開いてください。',
          );
          return;
        }
        await UIHelper.showFlutterToast('ストーリーの読み込みに失敗しました');
      },
    );
  }

  Future<void> onRefresh();
  Future<void> onReload();
  Future<void> onLoading();

  void addStoryDocs({
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) {
    storyDocs.removeWhere((doc) => doc.id == storyDoc.id);
    final insertIndex = storyDocs.indexWhere(
      (doc) =>
          (doc['createdAt'] as Timestamp).compareTo(
            storyDoc['createdAt'] as Timestamp,
          ) <
          0,
    );
    if (insertIndex == -1) {
      storyDocs.add(storyDoc);
    } else {
      storyDocs.insert(insertIndex, storyDoc);
    }
    notifyListeners();
  }

  void removeStoryDocs({
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) {
    storyDocs.removeWhere((doc) => doc.id == storyDoc.id);
    notifyListeners();
  }

  Future<void> getMyStories({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  });
}
