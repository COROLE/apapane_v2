//flutter
import 'dart:convert';

import 'package:apapane/constants/others.dart';
import 'package:apapane/constants/voids.dart';
import 'package:apapane/domain/chatLog/chatLog.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
//packages
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
//domain
import 'package:apapane/domain/firestore_user/firestore_user.dart';
//constants
import 'package:apapane/constants/strings.dart';
import 'package:apapane/constants/enums.dart';
//models
import 'package:apapane/model/main_model.dart';
//domain
import 'package:apapane/domain/story/story.dart';

final storyProvider = ChangeNotifierProvider((ref) => StoryModel());

class StoryModel extends ChangeNotifier {
  // FlutterTtsのインスタンスを作成
  final FlutterTts tts = FlutterTts();
  ConfirmAction confirmAction = ConfirmAction.initialValue;
  ToStoryPageType toStoryPageType = ToStoryPageType.initialValue;
  String chatLogs = "";
  bool isVolume = false;
  bool isVoiceDownloading = false;
  final player = AudioPlayer();
  final Map<String, Uint8List> _imageCache = {};

  // ignore: non_constant_identifier_names

  List<Map<String, dynamic>> storyPages = [];

  //削除
  // Future<void> loadStoryMapsFromJson() async {
  //   final String jsonString = await rootBundle.loadString('assets/a.json');
  //   final List<dynamic> jsonList = jsonDecode(jsonString);
  //   storyPages = jsonList.map((e) => e as Map<String, dynamic>).toList();
  //   notifyListeners();
  // }

  String titleText = '';
  String titleImage = '';

  void playAudioFromUrl(String url) {
    player.play(UrlSource(url));
  }

  @override
  void dispose() {
    // ウィジェットが破棄されるときに呼び出される
    // tts.stop(); // ttsの音声を停止する
    player.stop(); // 音声の呼び上げを停止する
    super.dispose();
  }

  void startVoiceDownloading() {
    isVoiceDownloading = true;
    notifyListeners();
  }

  void endVoiceDownloading() {
    isVoiceDownloading = false;
    notifyListeners();
  }

  void getTitleTextAndImage({required String title, required String image}) {
    titleText = title;
    titleImage = image;
    notifyListeners();
  }

  void updateStoryMaps({required List<Map<String, dynamic>> newStoryMaps}) {
    storyPages = newStoryMaps;
    notifyListeners();
  }

  void updateChatLogs({required String chatLogs}) {
    chatLogs = chatLogs;
    notifyListeners();
  }

  Future<void> endButtonPressed(
      {required BuildContext context, required MainModel mainModel}) async {
    // tts.stop();
    player.stop();
    try {
      switch (confirmAction) {
        case ConfirmAction.save:
          String saveTitleImage = titleImage;
          String saveTitleText = titleText;
          List<Map<String, dynamic>> saveStoryPages = storyPages;
          String newChatLogs = chatLogs;

          final DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
              mainModel.currentUserDoc;
          final FirestoreUser firestoreUser = mainModel.firestoreUser;
          final String activeUid = currentUserDoc.id;
          final Timestamp now = Timestamp.now();
          final String id = returnUuidV4();
          final chatLogRef = userDocToChatLogIdRef(
            userDoc: currentUserDoc,
            id: id,
          );

          final ChatLog chatLog = ChatLog(
            chatLog: newChatLogs,
            chatLogId: id,
            createdAt: now,
            uid: activeUid,
            userName: firestoreUser.userName,
            updatedAt: now,
          );
          try {
            await chatLogRef.set(chatLog.toJson());
            debugPrint('chatLog: ${chatLog.toJson()}');
          } catch (e) {
            showFluttertoast(msg: 'バグってる');
          }

          //削除
          // await loadStoryMapsFromJson();
          // 画像をFirebase Storageに保存する
          List<Map<String, dynamic>> updatedStoryPages = [];
          try {
            // 画像がある場合のみ保存する
            if (saveTitleImage != '') {
              saveTitleImage = await saveImageFromBase64(
                activeUid: activeUid,
                storyId: id,
                base64Image: saveTitleImage,
              );
              // 新しいダウンロードURLで更新
              notifyListeners();
            }

            for (final storyPage in saveStoryPages) {
              if (storyPage['image'] != null) {
                String base64Image = storyPage['image'] as String;
                String downloadUrl = await saveImageFromBase64(
                  activeUid: activeUid,
                  storyId: id,
                  base64Image: base64Image,
                );
                updatedStoryPages.add({
                  ...storyPage,
                  'image': downloadUrl, // 新しいダウンロードURLで更新
                });
              } else {
                updatedStoryPages.add(storyPage);
              }
            }
          } catch (e) {
            debugPrint('Error in endButtonPressed: $e');
          }
          // Firestoreに保存するためにstoryPagesを更新
          List<Map<String, dynamic>> lastUpdatedStoryPages = updatedStoryPages;
          final Story story = Story(
              createdAt: now,
              chatLogRef: chatLogRef,
              isPublic: true,
              stories: lastUpdatedStoryPages,
              storyId: id,
              titleImage: saveTitleImage,
              titleText: saveTitleText,
              uid: activeUid,
              userImageURL: firestoreUser.userImageURL,
              userName: firestoreUser.userName,
              updatedAt: now);
          try {
            await chatLogRef.collection('stories').doc(id).set(story.toJson());
            debugPrint('stories: ${story.toJson()}');
          } catch (e) {
            showFluttertoast(msg: 'バグってる');
          }
          debugPrint('storyPages: $storyPages');
          saveTitleImage = '';
          saveTitleText = '';
          saveStoryPages = [];
          lastUpdatedStoryPages = [];
          storyPages = [];
          updatedStoryPages = [];
          break;
        case ConfirmAction.cancel:
          break;
        case ConfirmAction.initialValue:
          break;
      }
    } catch (e) {
      print('Error in endButtonPressed: $e');
    }
  }

  void onPageChanged() {
    // tts.stop();
    player.stop();
    isVolume = false;
    notifyListeners();
  }

  // onVolumePressed({required String sentence}) async {
  //   isVolume = !isVolume;
  //   if (!isVolume) {
  //     tts.stop(); // 音声の呼び上げを停止する
  //   } else {
  //     try {
  //       tts.setLanguage('ja-JP'); // 読み上げる言語を日本語に設定
  //       tts.setSpeechRate(0.5); // 読み上げる速度を設定
  //       tts.setPitch(1.1);
  //       tts.setVolume(1.0);
  //       tts.speak(sentence);
  //     } catch (e) {
  //       print("Error speaking: $e");
  //     }
  //   }
  //   notifyListeners();
  // }
  void onVolumePressed({required String sentence}) async {
    isVolume = !isVolume;
    if (!isVolume) {
      player.stop(); // 音声の呼び上げを停止する
    } else {
      try {
        startVoiceDownloading();
        final String? audioUrl = await fetchVoicevoxAudioUrl(sentence);
        if (audioUrl != null) {
          playAudioFromUrl(audioUrl);
        }
        endVoiceDownloading();
      } catch (e) {
        print("Error speaking: $e");
      }
    }
    notifyListeners();
  }

  Future<String> uploadImageToFirebase({
    required String activeUid,
    required String storyId,
    required Uint8List imageData,
    required String fileName,
  }) async {
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('users/$activeUid/$storyId/$fileName');
    UploadTask uploadTask = storageRef.putData(imageData);

    // アップロードが完了するのを待つ
    await uploadTask;

    // アップロードが成功したかどうかを確認
    if (uploadTask.snapshot.state == TaskState.success) {
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } else {
      // アップロードが失敗した場合の処理
      throw Exception('ファイルのアップロードに失敗しました');
    }
  }

  Future<Uint8List> downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('画像のダウンロードに失敗しました');
    }
  }

  Future<String> saveImageFromBase64({
    required String activeUid,
    required String storyId,
    required String base64Image,
  }) async {
    // Base64文字列から画像データをデコード
    Uint8List imageData = base64Decode(base64Image);
    String fileName = returnJpgFileName();

    // Firebaseにアップロード
    String downloadUrl = await uploadImageToFirebase(
        activeUid: activeUid,
        storyId: storyId,
        imageData: imageData,
        fileName: fileName);
    debugPrint('アップロードされた画像のURL: $downloadUrl');
    return downloadUrl;
  }

  Future<String?> fetchVoicevoxAudioUrl(String text) async {
    final queryParams = {
      'speaker': "3",
      'text': text,
      'key': dotenv.env['VOICEVOX_API_KEY'], // .envからAPIキーを読み込む
    };
    final uri =
        Uri.https('api.tts.quest', '/v3/voicevox/synthesis', queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['mp3StreamingUrl'];
    } else {
      // エラーハンドリング
      print('Failed to load voice');
      return null;
    }
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
