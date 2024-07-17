import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/repositories/api_repository.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:apapane/models/chat_log/chat_log.dart';
import 'package:apapane/enums/confirm_action.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:flutter/material.dart';
//packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
//domain
import 'package:apapane/models/firestore_user/firestore_user.dart';
//models
//domain
import 'package:apapane/models/story/story.dart';

class StoryViewModel extends ChangeNotifier {
  final ApiRepository _apiRepository;
  final FirestoreRepository _firestoreRepository;

  StoryViewModel(this._apiRepository, this._firestoreRepository);

  // FlutterTtsのインスタンスを作成
  ConfirmAction confirmAction = ConfirmAction.initialValue;
  ToStoryPageType toStoryPageType = ToStoryPageType.initialValue;
  String _chatLogs = "";
  bool _isVolume = false;
  bool _isVoiceDownloading = false;
  final _player = AudioPlayer();
  final Map<String, Uint8List> _imageCache = {};
  List<Map<String, dynamic>> _storyPages = [];
  String _titleText = '';
  String _titleImage = '';

  List<Map<String, dynamic>> get storyPages => _storyPages;
  String get titleText => _titleText;
  bool get isVolume => _isVolume;
  bool get isVoiceDownloading => _isVoiceDownloading;

  void _playAudioFromUrl(String url) {
    _player.play(UrlSource(url));
  }

  @override
  void dispose() {
    // ウィジェットが破棄されるときに呼び出される
    super.dispose();
    _player.stop(); // 音声の呼び上げを停止する
  }

  void _startVoiceDownloading() {
    _isVoiceDownloading = true;
    notifyListeners();
  }

  void _endVoiceDownloading() {
    _isVoiceDownloading = false;
    notifyListeners();
  }

  void getTitleTextAndImage({required String title, required String image}) {
    _titleText = title;
    _titleImage = image;
    notifyListeners();
  }

  void updateStoryMaps({required List<Map<String, dynamic>> newStoryMaps}) {
    _storyPages = newStoryMaps;
    notifyListeners();
  }

  void updateChatLogs({required String chatLogs}) {
    _chatLogs = chatLogs;
    notifyListeners();
  }

  Future<void> endButtonPressed(
      {required BuildContext context,
      required MainViewModel mainViewModel}) async {
    _player.stop();
    try {
      switch (confirmAction) {
        case ConfirmAction.save:
          String saveTitleImage = _titleImage;
          String saveTitleText = _titleText;
          List<Map<String, dynamic>> saveStoryPages = _storyPages;
          String newChatLogs = _chatLogs;

          final DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
              mainViewModel.currentUserDoc;
          final FirestoreUser firestoreUser = mainViewModel.firestoreUser;
          final String activeUid = currentUserDoc.id;
          final Timestamp now = Timestamp.now();
          final String id = IDCore.uuidV4();

          final ChatLog chatLog = ChatLog(
            chatLog: newChatLogs,
            chatLogId: id,
            createdAt: now,
            uid: activeUid,
            userName: firestoreUser.userName,
            updatedAt: now,
          );

          final chatLogRef = ColRefCore.chatLogsColRef(activeUid).doc(id);
          final result = await _firestoreRepository.createDoc(
              chatLogRef, chatLog.toJson());

          result.when(
              success: (_) {},
              failure: (_) async {
                await UIHelper.showFlutterToast('チャット情報の保存に失敗しました。');
              });
          debugPrint('chatLog: ${chatLog.toJson()}');

          // 画像をFirebase Storageに保存する
          List<Map<String, dynamic>> updatedStoryPages = [];
          try {
            // 画像がある場合のみ保存する
            if (saveTitleImage != '') {
              for (int i = 0; i < saveStoryPages.length; i++) {
                final storyPage = saveStoryPages[i];
                if (storyPage['image'] != null) {
                  String base64Image = storyPage['image'] as String;
                  String downloadUrl = await _saveImageFromBase64(
                    activeUid: activeUid,
                    storyId: id,
                    base64Image: base64Image,
                  );

                  updatedStoryPages.add({
                    ...storyPage,
                    'image': downloadUrl, // 新しいダウンロードURLで更新
                  });

                  if (i == 0) {
                    saveTitleImage = downloadUrl; // 最初の要素の画像をsaveTitleImageに代入
                  }
                } else {
                  await UIHelper.showFlutterToast('UI画像がありません。');
                }
              }
            } else {
              await UIHelper.showFlutterToast('タイトル画像がありません。');
            }
          } catch (e) {
            debugPrint('Error in endButtonPressed: $e');
          }
          // Firestoreに保存するためにstoryPagesを更新
          List<Map<String, dynamic>> lastUpdatedStoryPages = updatedStoryPages;
          final Story story = Story(
              createdAt: now,
              chatLogRef: chatLogRef,
              stories: lastUpdatedStoryPages,
              storyId: id,
              titleImage: saveTitleImage,
              titleText: saveTitleText,
              uid: activeUid,
              userImageURL: firestoreUser.userImageURL,
              userName: firestoreUser.userName,
              updatedAt: now);

          final saveStoryResult = await _firestoreRepository.createDoc(
              ColRefCore.storiesColRef(activeUid, id).doc(id), story.toJson());
          saveStoryResult.when(
              success: (_) {},
              failure: (_) async {
                await UIHelper.showFlutterToast('Catch: ストーリーの保存に失敗しました。');
              });
          debugPrint('stories: ${story.toJson()}');

          debugPrint('_storyPages: $_storyPages');
          saveTitleImage = '';
          saveTitleText = '';
          saveStoryPages = [];
          lastUpdatedStoryPages = [];
          _storyPages = [];
          updatedStoryPages = [];
          break;
        case ConfirmAction.cancel:
          break;
        case ConfirmAction.initialValue:
          break;
      }
    } catch (e) {
      debugPrint('Error in endButtonPressed: $e');
    }
  }

  void onPageChanged() {
    _player.stop();
    _isVolume = false;
    notifyListeners();
  }

  void onVolumePressed({required String sentence}) async {
    _isVolume = !_isVolume;
    if (!_isVolume) {
      _player.stop(); // 音声の呼び上げを停止する
    } else {
      try {
        _startVoiceDownloading();

        final result = await _apiRepository.getVoicevoxAudioUrl(sentence);
        result.when(success: (audioUrl) {
          if (audioUrl != null) {
            _playAudioFromUrl(audioUrl);
          }
        }, failure: (_) async {
          await UIHelper.showFlutterToast('音声のダウンロードに失敗しました。');
        });
        _endVoiceDownloading();
      } catch (e) {
        debugPrint("Error speaking: $e");
      }
    }
    notifyListeners();
  }

  Future<String> _uploadImageToFirebase({
    required String activeUid,
    required String storyId,
    required Uint8List imageData,
    required String fileName,
  }) async {
    String downloadUrl = '';
    final path = 'users/$activeUid/$storyId/$fileName';
    final result = await _firestoreRepository.uploadImage(path, imageData);
    result.when(success: (res) {
      downloadUrl = res;
    }, failure: (_) async {
      await UIHelper.showFlutterToast('画像のアップロードに失敗しました。');
    });
    return downloadUrl;
  }

  Future<String> _saveImageFromBase64({
    required String activeUid,
    required String storyId,
    required String base64Image,
  }) async {
    // Base64文字列から画像データをデコード
    Uint8List imageData = base64Decode(base64Image);
    String fileName = IDCore.jpgFileName();

    // Firebaseにアップロード
    String downloadUrl = await _uploadImageToFirebase(
        activeUid: activeUid,
        storyId: storyId,
        imageData: imageData,
        fileName: fileName);
    debugPrint('アップロードされた画像のURL: $downloadUrl');
    return downloadUrl;
  }

  Future<Uint8List?> fetchImageData(String? imageUrl) async {
    if (_imageCache.containsKey(imageUrl)) {
      return _imageCache[imageUrl]!;
    } else {
      if (imageUrl == null) return null;
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        Uint8List imageData = response.bodyBytes;
        _imageCache[imageUrl] = imageData; // キャッシュに画像データを保存
        return imageData;
      } else {
        throw Exception('Failed to load image');
      }
    }
  }
}
