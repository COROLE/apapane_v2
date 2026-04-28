import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/firestore/query_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/local/local_firestore.dart';
import 'package:apapane/models/story/story.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/abstract/base_log_view_model.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';

class ArchiveViewModel extends BaseLogViewModel {
  ArchiveViewModel(this._firestoreRepository) : super(_firestoreRepository);

  final FirestoreRepository _firestoreRepository;
  List<DocumentSnapshot<Map<String, dynamic>>> _chatLogDocs = [];

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
    if (currentUser == null || _chatLogDocs.isEmpty) {
      return;
    }
    await _loadStoriesFromChatLogs(
      QueryCore.newArchiveChatLogsQuery(currentUser, _chatLogDocs),
      currentUser.uid,
    );
    updatePublicStoryIds();
    notifyListeners();
  }

  @override
  Future<void> onReload() async {
    startLoading();
    final currentUser = IDCore.authUser();
    if (currentUser == null) {
      _chatLogDocs = [];
      storyDocs = [];
      favoriteStoryIds = [];
      publicStoryIds = [];
      endLoading();
      return;
    }

    _chatLogDocs = [];
    storyDocs = [];
    await _loadStoriesFromChatLogs(
      QueryCore.archiveChatLogsQuery(currentUser),
      currentUser.uid,
    );
    updatePublicStoryIds();
    await updateFavoriteStoryIds(currentUser.uid);
    notifyListeners();
    endLoading();
  }

  @override
  Future<void> onLoading() async {
    refreshController.loadComplete();
    final currentUser = IDCore.authUser();
    if (currentUser == null || _chatLogDocs.isEmpty) {
      return;
    }
    await _loadStoriesFromChatLogs(
      QueryCore.oldArchiveChatLogsQuery(currentUser, _chatLogDocs),
      currentUser.uid,
    );
    updatePublicStoryIds();
    notifyListeners();
  }

  Future<void> _loadStoriesFromChatLogs(MapQuery query, String uid) async {
    final result = await _firestoreRepository.getDocs(query);
    await result.when(
      success: (chatLogs) async {
        for (final chatLogDoc in chatLogs) {
          _chatLogDocs.removeWhere((existing) => existing.id == chatLogDoc.id);
          _chatLogDocs.add(chatLogDoc);

          final storyResult = await _firestoreRepository
              .getDoc(DocRefCore.storyDocRef(uid, chatLogDoc.id));
          storyResult.when(
            success: (storyDoc) {
              if (!storyDoc.exists || storyDoc.data() == null) {
                return;
              }
              storyDocs.removeWhere((existing) => existing.id == storyDoc.id);
              storyDocs.add(storyDoc);
            },
            failure: (error) async {
              debugPrint(
                  'Failed to load story document ${chatLogDoc.id}: $error');
            },
          );
        }

        _chatLogDocs.sort(
          (left, right) => (right['createdAt'] as Timestamp)
              .compareTo(left['createdAt'] as Timestamp),
        );
        storyDocs.sort(
          (left, right) => (right['createdAt'] as Timestamp)
              .compareTo(left['createdAt'] as Timestamp),
        );
      },
      failure: (error) async {
        debugPrint('Failed to load chat log list: $error');
        await UIHelper.showFlutterToast('ストーリーの読み込みに失敗しました');
      },
    );
  }

  void updatePublicStoryIds() {
    publicStoryIds = storyDocs
        .where((element) => element['isPublic'] == true)
        .map((e) => e.id)
        .toList();
  }

  Future<void> updateFavoriteStoryIds(String uid) async {
    final result = await _firestoreRepository.getDocs(
      ColRefCore.favoriteStoriesColRef(uid).limit(maxFavoriteCount),
    );
    result.when(
      success: (qShot) {
        favoriteStoryIds = qShot.map((e) => e.id).toList();
      },
      failure: (_) async {
        await UIHelper.showFlutterToast('お気に入りの読込に失敗しました');
      },
    );
  }

  @override
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

  Future<void> _updateLikeFunction(
    MainViewModel mainViewModel,
    bool isLike,
  ) async {
    final currentUser = mainViewModel.currentUser;
    if (currentUser == null) {
      return;
    }

    final result = await _firestoreRepository.updateDoc(
      DocRefCore.publicUserDocRef(currentUser.uid),
      {'favoriteMyStoryCount': favoriteStoryIds.length},
    );

    result.when(
      success: (_) => mainViewModel.updateFavoriteCount(isLike),
      failure: (_) async {
        await UIHelper.showFlutterToast(
          isLike ? 'お気に入り更新に失敗しました' : 'お気に入り解除に失敗しました',
        );
      },
    );
  }

  Future<void> updateFavorite({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required MainViewModel mainViewModel,
    required int index,
    required bool isLike,
  }) async {
    final currentUser = mainViewModel.currentUser;
    if (currentUser == null) {
      return;
    }

    final storyDoc = storyDocs[index];
    final storyId = storyDoc.id;

    if (isLike) {
      if (favoriteStoryIds.length >= maxFavoriteCount) {
        await UIHelper.showFlutterToast('お気に入りは5件までです');
        return;
      }
      _startFavoriteLoading();
      favoriteStoryIds.add(storyId);
      notifyListeners();

      final storiesDynamic = storyDoc['stories'] as List<dynamic>;
      final story = Story(
        createdAt: storyDoc['createdAt'],
        chatLogRef: storyDoc['chatLogRef'],
        isPublic: storyDoc['isPublic'] == true,
        stories: storiesDynamic.cast<Map<String, dynamic>>(),
        storyId: storyId,
        titleImage: storyDoc['titleImage'].toString(),
        titleText: storyDoc['titleText'].toString(),
        uid: storyDoc['uid'].toString(),
        userImageURL: storyDoc['userImageURL']?.toString() ?? '',
        userName: storyDoc['userName']?.toString() ?? '',
        updatedAt: Timestamp.now(),
      );

      final favoriteStoryJson = story.toJson();
      final rawStoryData = storyDoc.data();
      if (rawStoryData != null) {
        for (final key in [
          'schemaVersion',
          'mode',
          'pageCount',
          'coinCost',
          'storyOptions',
          'previewSummary',
          'pagePlan',
          'generationRequestId',
        ]) {
          if (rawStoryData.containsKey(key)) {
            favoriteStoryJson[key] = rawStoryData[key];
          }
        }
      }

      final result = await _firestoreRepository.createDoc(
        ColRefCore.favoriteStoriesColRef(currentUser.uid).doc(storyId),
        favoriteStoryJson,
      );
      result.when(
        success: (_) => _updateLikeFunction(mainViewModel, true),
        failure: (_) async {
          await UIHelper.showFlutterToast('お気に入り保存に失敗しました');
        },
      );
    } else {
      if (!favoriteStoryIds.contains(storyId)) {
        await UIHelper.showFlutterToast('このストーリーはお気に入りに入っていません');
        return;
      }
      _startFavoriteLoading();
      favoriteStoryIds.remove(storyId);
      notifyListeners();

      final result = await _firestoreRepository.deleteDoc(
        ColRefCore.favoriteStoriesColRef(currentUser.uid).doc(storyId),
      );
      result.when(
        success: (_) => _updateLikeFunction(mainViewModel, false),
        failure: (_) async {
          await UIHelper.showFlutterToast('お気に入り解除に失敗しました');
        },
      );
    }

    _endFavoriteLoading();
  }

  Future<void> updatePublicMode({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required int index,
    required bool isOn,
  }) async {
    final currentUser = IDCore.authUser();
    if (currentUser == null) {
      return;
    }

    final storyId = storyDocs[index].id;
    if (isOn) {
      publicStoryIds.add(storyId);
    } else {
      publicStoryIds.remove(storyId);
    }
    notifyListeners();

    final result = await _firestoreRepository.updateDoc(
      DocRefCore.storyDocRef(currentUser.uid, storyId),
      {'isPublic': isOn, 'updatedAt': Timestamp.now()},
    );

    result.when(
      success: (_) async {
        await UIHelper.showFlutterToast(
          isOn ? '公開ストーリーに追加しました' : '公開ストーリーから外しました',
        );
      },
      failure: (_) async {
        await UIHelper.showFlutterToast('公開設定の更新に失敗しました');
      },
    );
  }
}
