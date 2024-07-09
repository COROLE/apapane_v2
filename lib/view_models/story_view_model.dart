// import 'dart:convert';
// import 'package:apapane/constants/others.dart';
// import 'package:apapane/model_riverpod_old/main_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:apapane/constants/voids.dart';
// import 'package:apapane/constants/enums.dart';
// import 'package:apapane/constants/routes.dart' as routes;
// import 'package:apapane/domain/chatLog/chatLog.dart';
// import 'package:apapane/domain/firestore_user/firestore_user.dart';
// import 'package:apapane/domain/story/story.dart';
// import 'package:apapane/models/result/result.dart';
// import 'package:apapane/repositories/firestore_repository.dart';
// import 'package:apapane/core/id_core/id_core.dart';

// final storyProvider = ChangeNotifierProvider((ref) => StoryViewModel(ref.read));

// class StoryViewModel extends ChangeNotifier {
//   final Reader _read;
//   final FlutterTts tts = FlutterTts();
//   ConfirmAction confirmAction = ConfirmAction.initialValue;
//   ToStoryPageType toStoryPageType = ToStoryPageType.initialValue;
//   String chatLogs = "";
//   bool isVolume = false;
//   bool isVoiceDownloading = false;
//   final player = AudioPlayer();
//   final Map<String, Uint8List> _imageCache = {};
//   List<Map<String, dynamic>> storyPages = [];
//   String titleText = '';
//   String titleImage = '';

//   StoryViewModel(this._read);

//   void playAudioFromUrl(String url) {
//     player.play(UrlSource(url));
//   }

//   @override
//   void dispose() {
//     player.stop();
//     super.dispose();
//   }

//   void startVoiceDownloading() {
//     isVoiceDownloading = true;
//     notifyListeners();
//   }

//   void endVoiceDownloading() {
//     isVoiceDownloading = false;
//     notifyListeners();
//   }

//   void getTitleTextAndImage({required String title, required String image}) {
//     titleText = title;
//     titleImage = image;
//     notifyListeners();
//   }

//   void updateStoryMaps({required List<Map<String, dynamic>> newStoryMaps}) {
//     storyPages = newStoryMaps;
//     notifyListeners();
//   }

//   void updateChatLogs({required String chatLogs}) {
//     this.chatLogs = chatLogs;
//     notifyListeners();
//   }

//   Future<void> endButtonPressed({required BuildContext context, required MainModel mainModel}) async {
//     player.stop();
//     try {
//       switch (confirmAction) {
//         case ConfirmAction.save:
//           String saveTitleImage = titleImage;
//           String saveTitleText = titleText;
//           List<Map<String, dynamic>> saveStoryPages = storyPages;
//           String newChatLogs = chatLogs;

//           final DocumentSnapshot<Map<String, dynamic>> currentUserDoc = mainModel.currentUserDoc;
//           final FirestoreUser firestoreUser = mainModel.firestoreUser;
//           final String activeUid = currentUserDoc.id;
//           final Timestamp now = Timestamp.now();
//           final String id = IDCore.uuidV4();
//           final chatLogRef = userDocToChatLogIdRef(userDoc: currentUserDoc, id: id);

//           final ChatLog chatLog = ChatLog(
//             chatLog: newChatLogs,
//             chatLogId: id,
//             createdAt: now,
//             uid: activeUid,
//             userName: firestoreUser.userName,
//             updatedAt: now,
//           );
//           try {
//             await chatLogRef.set(chatLog.toJson());
//           } catch (e) {
//             showFluttertoast(msg: 'バグってる');
//           }

//           List<Map<String, dynamic>> updatedStoryPages = [];
//           try {
//             if (saveTitleImage != '') {
//               saveTitleImage = await saveImageFromBase64(
//                 activeUid: activeUid,
//                 storyId: id,
//                 base64Image: saveTitleImage,
//               );
//               notifyListeners();
//             }

//             for (final storyPage in saveStoryPages) {
//               if (storyPage['image'] != null) {
//                 String base64Image = storyPage['image'] as String;
//                 String downloadUrl = await saveImageFromBase64(
//                   activeUid: activeUid,
//                   storyId: id,
//                   base64Image: base64Image,
//                 );
//                 updatedStoryPages.add({
//                   ...storyPage,
//                   'image': downloadUrl,
//                 });
//               } else {
//                 updatedStoryPages.add(storyPage);
//               }
//             }
//           } catch (e) {
//             debugPrint('Error in endButtonPressed: $e');
//           }
//           List<Map<String, dynamic>> lastUpdatedStoryPages = updatedStoryPages;
//           final Story story = Story(
//               createdAt: now,
//               chatLogRef: chatLogRef,
//               isPublic: true,
//               stories: lastUpdatedStoryPages,
//               storyId: id,
//               titleImage: saveTitleImage,
//               titleText: saveTitleText,
//               uid: activeUid,
//               userImageURL: firestoreUser.userImageURL,
//               userName: firestoreUser.userName,
//               updatedAt: now);
//           try {
//             await chatLogRef.collection('stories').doc(id).set(story.toJson());
//           } catch (e) {
//             showFluttertoast(msg: 'バグってる');
//           }
//           saveTitleImage = '';
//           saveTitleText = '';
//           saveStoryPages = [];
//           lastUpdatedStoryPages = [];
//           storyPages = [];
//           updatedStoryPages = [];
//           break;
//         case ConfirmAction.cancel:
//           break;
//         case ConfirmAction.initialValue:
//           break;
//       }
//     } catch (e) {
//       print('Error in endButtonPressed: $e');
//     }
//   }

//   void onPageChanged() {
//     player.stop();
//     isVolume = false;
//     notifyListeners();
//   }

//   void onVolumePressed({required String sentence}) async {
//     isVolume = !isVolume;
//     if (!isVolume) {
//       player.stop();
//     } else {
//       try {
//         startVoiceDownloading();
//         final String? audioUrl = await fetchVoicevoxAudioUrl(sentence);
//         if (audioUrl != null) {
//           playAudioFromUrl(audioUrl);
//         }
//         endVoiceDownloading();
//       } catch (e) {
//         print("Error speaking: $e");
//       }
//     }
//     notifyListeners();
//   }

//   Future<String> uploadImageToFirebase({
//     required String activeUid,
//     required String storyId,
//     required Uint8List imageData,
//     required String fileName,
//   }) async {
//     Reference storageRef = FirebaseStorage.instance.ref().child('users/$activeUid/$storyId/$fileName');
//     UploadTask uploadTask = storageRef.putData(imageData);

//     await uploadTask;

//     if (uploadTask.snapshot.state == TaskState.success) {
//       String downloadUrl = await storageRef.getDownloadURL();
//       return downloadUrl;
//     } else {
//       throw Exception('ファイルのアップロードに失敗しました');
//     }
//   }

//   Future<Uint8List> downloadImage(String imageUrl) async {
//     final response = await http.get(Uri.parse(imageUrl));
//     if (response.statusCode == 200) {
//       return response.bodyBytes;
//     } else {
//       throw Exception('画像のダウンロードに失敗しました');
//     }
//   }

//   Future<String> saveImageFromBase64({
//     required String activeUid,
//     required String storyId,
//     required String base64Image,
//   }) async {
//     Uint8List imageData = base64Decode(base64Image);
//     String fileName = IDCore.uuidV4();

//     String downloadUrl = await uploadImageToFirebase(
//         activeUid: activeUid,
//         storyId: storyId,
//         imageData: imageData,
//         fileName: fileName);
//     return downloadUrl;
//   }

//   Future<String?> fetchVoicevoxAudioUrl(String text) async {
//     final queryParams = {
//       'speaker': "3",
//       'text': text,
//       'key': dotenv.env['VOICEVOX_API_KEY'],
//     };
//     final uri = Uri.https('api.tts.quest', '/v3/voicevox/synthesis', queryParams);

//     final response = await http.get(uri);
//     if (response.statusCode == 200) {
//       final jsonResponse = jsonDecode(response.body);
//       return jsonResponse['mp3StreamingUrl'];
//     } else {
//       print('Failed to load voice');
//       return null;
//     }
//   }

//   Future<Uint8List?> fetchImageData(String? imageUrl) async {
//     if (_imageCache.containsKey(imageUrl)) {
//       return _imageCache[imageUrl]!;
//     } else {
//       if (imageUrl == null) return null;
//       final response = await http.get(Uri.parse(imageUrl));
//       if (response.statusCode == 200) {
//         Uint8List imageData = response.bodyBytes;
//         _imageCache[imageUrl] = imageData;
//         return imageData;
//       } else {
//         throw Exception('Failed to load image');
//       }
//     }
//   }
// }