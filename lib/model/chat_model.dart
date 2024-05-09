//dart
import 'dart:convert';

//flutter
import 'package:apapane/constants/voids.dart' as voids;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
//packages
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:anthropic_dart/anthropic_dart.dart' as Anthropic;
//constants
import 'package:apapane/constants/enums.dart';
import 'package:apapane/constants/routes.dart' as routes;
//models
import 'package:apapane/model/model_class/message_class.dart';
import 'package:apapane/model/story_model.dart';

final chatProvider = ChangeNotifierProvider((ref) => ChatModel());

class ChatModel extends ChangeNotifier {
  final Map<String, dynamic> responseData = {};

  SpeechToText speechToText = SpeechToText();
  ScrollController scrollController = ScrollController();
  bool isLoading = false;
  bool isListening = false;
  bool isCommentLoading = false;
  bool isExampleLoading = false;
  bool available = false;
  int chatCount = 4;
  String userInput = "";
  String voiceText = "";
  String message = "";
  String exampleText = "";
  String exampleText2 = "";
  String messageListString = "";
  List<Message> messagesList = [];
  bool isComplete = false;
  final TextEditingController textController = TextEditingController();

  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void endLoading() {
    isLoading = false;
    notifyListeners();
  }

  void startCommentLoading() {
    isCommentLoading = true;
    notifyListeners();
  }

  void endCommentLoading() {
    isCommentLoading = false;
    notifyListeners();
  }

  void startExampleLoading() {
    isExampleLoading = true;
    notifyListeners();
  }

  void endExampleLoading() {
    isExampleLoading = false;
    notifyListeners();
  }

  // chatScreenに遷移したら最初のプロンプトを投げるようにする
  void chatInit({required BuildContext context, required String apapaneTitle}) {
    messagesList.clear();
    message = "";
    voiceText = "";
    messageListString = "";
    exampleText = "";
    exampleText2 = "";
    textController.clear();
    isComplete = false;
    chatCount = 4;
    routes.toChatScreen(context: context, apapaneTitle: apapaneTitle);
    messagesList.add(Message(
      message: "こんにちは！いっしょにものがたりをつくりましょう！",
      isMe: true,
      sendTime: DateTime.now(),
    ));

    sendFirstPrompt("h:おはなしをつくりたいです！", true);
    notifyListeners();
  }

  void sendFirstPrompt(String text, bool isMe) async {
    String reply = await replyTemplate(1);
    message += reply;
    Message replyMessage = Message(
      message: reply,
      isMe: false,
      sendTime: DateTime.now(),
    );

    messagesList.add(replyMessage);
    startExampleLoading();
    // exampleText = await example(reply);
    // exampleText2 = await example(reply);
    // exampleText = "mamama";
    // exampleText2 = "mamama";

    endExampleLoading();
    notifyListeners();
  }

  Future<void> sendMessageFromButton({required BuildContext context}) async {
    startCommentLoading();
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 200));
    String userInput = textController.text;
    textController.clear();
    await sendMessage(userInput, true);
    endCommentLoading();

    // ignore: use_build_context_synchronously
  }

  Future<void> sendMessage(String text, bool isMe) async {
    if (text.trim().isEmpty) {
      // テキストが空白の場合、何も送信しない
      return;
    } else {
      message += '$text\n';
      Message newMessage = Message(
        message: text,
        isMe: true,
        sendTime: DateTime.now(),
      );
      messagesList.add(newMessage);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await newMessageScroll();
      });
      notifyListeners();
      int countIsMeMessages =
          messagesList.where((message) => message.isMe).length;
      if (countIsMeMessages % chatCount == 0 && countIsMeMessages != 0) {
        toggleIsComplete();
        chatCount += 4;
        notifyListeners();
      }
      if (!isComplete) {
        await talkAndExample();
      }
    }

    scrollController = ScrollController();
  }

//echoMessageのエンドポイントを使って、会話をする
  // Future<String> talk(String text) async {
  //   final url = Uri.https("asia-northeast1-apapane-3cca0.cloudfunctions.net",
  //       "/echoMessage", {"aiInput": "", "message": text});
  //   final response = await http.get(
  //     url,
  //     headers: <String, String>{
  //       "Content-Type":
  //           "application/json; charset=UTF-8", // Correct token is set here
  //     },
  //   );

  //   try {
  //     if (response.statusCode == 200) {
  //       debugPrint('Text uploaded successfully');
  //       return response.body;
  //     } else {
  //       debugPrint(
  //           'Text upload failed with status code ${response.statusCode}');
  //       return "error";
  //     }
  //   } catch (e) {
  //     debugPrint('Error uploading text: $e');
  //     return "error";
  //   }
  // }

//replyのエンドポイントを使って、会話をする
  Future<String> talk(String text) async {
    final String prompt = '''
    <chatlog>
    $text
    </chatlog>

    <instruction>
    Speak in a friendly, frank tone, without using honorifics.
    Do not ask the same question more than once.
    Do not repeat a question that you have previously heard in the conversation history.
    Please answer in easy-to-understand japanese, using no more than 30 characters.
    The ratio of kanji to hiragana should be about 1:4.
    Avoid difficult-to-read kanji characters.
    </instruction>

    You are a friendly interviewer who asks the children what they imagine the story to be about.
    You are very curious about what story the children are imagining, so you ask, "What other characters are there?", "What happens afterwards?", "What happens after that?", and so on.
    Ask for more information about the protagonist and the characters.
    Ask only one element at a time about the setting of a story.
    Omit the preamble and output only the agreement(e.g., "I see, so the main character is ~!", "nice!" etc.) and a question.
    Please look at the conversation history so far in [chatlog] and output only the Assistant's next reply.
    Assistant should output a reaction to Human's last statement in [chatlog] and another additional question regarding the setting of the story.
    We have already asked about the name of main character and location, so please start with the other questions.
    Follow the instructions under [instruction] for output.
    ''';
    const String model = "claude-3-haiku-20240307";
    final service = Anthropic.AnthropicService(dotenv.get("ANTHROPIC_API_KEY"),
        model: model);
    var request = Anthropic.Request();
    request.model = model;
    request.maxTokens = 1024;
    request.messages = [
      Anthropic.Message(
        role: "user",
        content: prompt,
      )
    ];
    var response = await service.sendRequest(request: request);

    // レスポンスボディをそのまま出力
    // debugPrint('Response body: ${response.toJson()["content"][0]["text"]}');

    return response.toJson()["content"][0]["text"];
  }

// Response body: {id: msg_01RYfE4NMXifqPDnKdDfPfHd, type: message, role: assistant, model: claude-3-haiku-20240307, content: [{type: text, text: このお話の主人公はアキラで、舞台は月です。
// アキラは月で起きている出来事の主人公となっています。月という特殊な場所が物語の舞台となっているようですね。}], stop_reason: end_turn, stop_sequence: null, usage: {input_tokens: 38, output_tokens: 66}}

//echoMessageのエンドポイントを使って、exampleをする
  // Future<String> example(String text) async {
  //   final url = Uri.https("asia-northeast1-apapane-3cca0.cloudfunctions.net",
  //       "/echoMessage", {"aiInput": text, "message": ""});
  //   final response = await http.get(
  //     url,
  //     headers: <String, String>{
  //       "Content-Type":
  //           "application/json; charset=UTF-8", // Correct token is set here
  //     },
  //   );
  //   debugPrint('example response: ${response.body}');

  //   try {
  //     if (response.statusCode == 200) {
  //       debugPrint('Text uploaded successfully');
  //       return response.body;
  //     } else {
  //       debugPrint(
  //           'Text upload failed with status code ${response.statusCode}');
  //       return "error";
  //     }
  //   } catch (e) {
  //     debugPrint('Error uploading text: $e');
  //     return "error";
  //   }
  // }

//exampleのエンドポイントを使って、exampleをする
  Future<String> example(String text) async {
    final url = Uri.https(
        "asia-northeast1-apapane-3cca0.cloudfunctions.net", "/example");
    final response = await http.post(
      url,
      headers: <String, String>{
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode({"req": text}),
    );

    try {
      if (response.statusCode == 200) {
        debugPrint('Example text uploaded successfully');
        return response.body;
      } else {
        debugPrint(
            'Text upload failed with status code ${response.statusCode}');
        return "error";
      }
    } catch (e) {
      debugPrint('Error uploading text: $e');
      return "error";
    }
  }

  Future<void> newMessageScroll() async {
    if (scrollController.hasClients) {
      await scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    notifyListeners();
  }

  Future<void> onTapScrollFunction(BuildContext context, double plus) async {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // 現在のスクロール位置
    final currentPosition = scrollController.position.pixels;
    // ターゲットとなるスクロール位置（現在の位置 + キーボードの高さ + さらに少し余裕を持たせる）
    final targetPosition =
        currentPosition + keyboardHeight + plus; // 20は余裕を持たせるための値

    // スクロール位置をアニメーションで移動
    await scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void onTapScroll(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    int countIsMeMessages =
        messagesList.where((message) => !message.isMe).length;
    if (scrollController.hasClients) {
      switch (countIsMeMessages) {
        case 1:
          onTapScrollFunction(context, screenHeight * 0.18);
        case 2:
          onTapScrollFunction(context, screenHeight * 0.35);
          break;
        default:
          onTapScrollFunction(context, screenHeight * 0.43);
          break;
      }
    }
    notifyListeners();
  }

  Future<void> replyMessageScroll() async {
    if (scrollController.hasClients) {
      await scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }

    notifyListeners();
  }

//makeStoryを使用
  // Future<List<Map<String, dynamic>>> makeStory({
  //   required String text,
  // }) async {
  //   final url = Uri.https("asia-northeast1-apapane-3cca0.cloudfunctions.net",
  //       '/makeStory', {'message': text});
  //   String jsonBody = jsonEncode({"data": text});
  //   final response = await http.post(
  //     url,
  //     headers: <String, String>{
  //       "Content-Type": "application/json; charset=UTF-8",
  //     },
  //     body: jsonBody,
  //   );

  //   try {
  //     if (response.statusCode == 200) {
  //       debugPrint('Text uploaded successfully');
  //       // JSON データをデコードする
  //       final List<dynamic> responseData = jsonDecode(response.body);

  //       // responseDataをMapオブジェクトのリストに変換
  //       List<Map<String, dynamic>> storyMaps =
  //           responseData.cast<Map<String, dynamic>>();
  //       // StoryModelのStoryMapsを更新するのではなく、新しいStoryMapのリストを返す
  //       return storyMaps;
  //       // 必要に応じて他の処理を行う
  //     } else {
  //       debugPrint(
  //           'Text upload failed with status code ${response.statusCode}');
  //       return [];
  //     }
  //   } catch (e) {
  //     debugPrint('Error in makeImage: $e');
  //     return [];
  //   }
  // }

  //storymakerを使用
  Future<List<Map<String, dynamic>>> makeStory({
    required String text,
  }) async {
    final url = Uri.https(
        "asia-northeast1-apapane-3cca0.cloudfunctions.net", '/storymaker');
    String jsonBody = jsonEncode({"message": text}); // JSON キーを 'message' に修正
    final response = await http.post(
      url,
      headers: <String, String>{
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonBody,
    );

    try {
      if (response.statusCode == 200) {
        debugPrint('Text uploaded successfully');
        final List<dynamic> responseData = jsonDecode(response.body);
        if (responseData.isEmpty) {
          debugPrint('No stories returned');
          return [];
        }
        List<Map<String, dynamic>> storyMaps =
            responseData.cast<Map<String, dynamic>>();
        return storyMaps;
      } else {
        debugPrint(
            'Text upload failed with status code ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in makeImage: $e');
      return [];
    }
  }

  Future<void> createButtonPressed(
      {required BuildContext context, required StoryModel storyModel}) async {
    int countIsMeMessages =
        messagesList.where((message) => message.isMe).length;
    if (countIsMeMessages > 2) {
      startLoading();
      String message = messageListToString();
      storyModel.updateMessages(message: message);

      try {
        List<Map<String, dynamic>> newStoryMaps =
            await makeStory(text: message);
        if (newStoryMaps.isNotEmpty && newStoryMaps[0]['story'] != null) {
          storyModel.getTitleTextAndImage(
              title: newStoryMaps[0]['story'], image: newStoryMaps[0]['image']);
          storyModel.updateStoryMaps(newStoryMaps: newStoryMaps);
          storyModel.toStoryPageType = ToStoryPageType.newStory;
          routes.toStoryScreenReplacement(context: context);
        } else {
          debugPrint('No stories or images returned');
          voids.showFluttertoast(msg: "物語を取得できませんでした。");
        }
      } catch (e) {
        debugPrint('Error fetching story: $e');
        voids.showFluttertoast(msg: "エラーが発生しました。後ほど再試行してください。");
      } finally {
        endLoading();
        messagesList.clear();
        notifyListeners();
      }
    }
  }

  String messageListToString() {
    messageListString = "";
    messageListString += '#会話履歴です。絶対子供の世界観を参考にしてください。\n';
    for (Message message in messagesList) {
      if (message.isMe) {
        messageListString += ("物語を作成したい子供:${message.message}\n");
      } else {
        messageListString += ("AI:${message.message}\n");
      }
    }
    return messageListString;
  }

  void startListening({required String localeId}) async {
    final available = await speechToText.initialize();
    notifyListeners();
    if (available) {
      isListening = true;
      speechToText.listen(
        onResult: (result) {
          voiceText = result.recognizedWords;

          textController.text = voiceText;
          notifyListeners();
        },
        localeId: localeId,
      );
    } else {
      isListening = false;
      notifyListeners();
    }
  }

  void stopListening() {
    voiceText = "";
    if (isListening) {
      isListening = false;
      speechToText.stop();
      notifyListeners();
    }
    notifyListeners();
  }

  void backToHomeScreen({required BuildContext context}) {
    messagesList.clear();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // HTTPリクエストやタイマーをキャンセルする処理
    chatCount = 4;
    isComplete = false;
    textController.dispose();
    scrollController.dispose();
    messagesList.clear();
    messageListString = "";
    message = "";
    voiceText = "";
    super.dispose();
    notifyListeners();
  }

  void toggleIsComplete() {
    isComplete = !isComplete;
    notifyListeners();
  }

  Future<void> toggleIsCompleteAndTalk(BuildContext context) async {
    toggleIsComplete();
    await talkAndExample();
    onTapScroll(context);
  }

  Future<void> talkAndExample() async {
    int countIsMeMessages =
        messagesList.where((message) => message.isMe).length;

    if (countIsMeMessages > 2) {
      String reply = await talk(message); // 会話履歴を毎回送る

      message += reply;
      // message += reply;
      Message replyMessage = Message(
        message: reply,
        isMe: false,
        sendTime: DateTime.now(),
      );
      messagesList.add(replyMessage);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await replyMessageScroll();
      });
    } else {
      String reply = await replyTemplate(countIsMeMessages);
      message += reply;
      Message replyMessage = Message(
        message: reply,
        isMe: false,
        sendTime: DateTime.now(),
      );
      messagesList.add(replyMessage);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await replyMessageScroll();
      });
    }

    startExampleLoading();
    // exampleText = await example(reply);
    // exampleText2 = await example(reply);
    // exampleText = "mamama";
    // exampleText2 = "mamama";
    endExampleLoading();
  }

  Future<String> replyTemplate(int countIsMeMessages) async {
    switch (countIsMeMessages) {
      case 1:
        await Future.delayed(const Duration(milliseconds: 500));
        return "このおはなしの主人公はだれ？";
      case 2:
        await Future.delayed(const Duration(seconds: 1));

        return "このおはなしの場所はどこ？";
      default:
        await Future.delayed(const Duration(seconds: 1));

        return "そうしましょう！";
    }
  }
}
