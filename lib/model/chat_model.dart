//dart
import 'dart:convert';

//flutter
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
//packages
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
//constants
import 'package:apapane/constants/voids.dart' as voids;
import 'package:apapane/constants/enums.dart';
import 'package:apapane/constants/routes.dart' as routes;
//models
import 'package:apapane/model/story_model.dart';
import 'package:uuid/uuid.dart';

final chatProvider = ChangeNotifierProvider((ref) => ChatModel());

class Pair<T, U> {
  final T first;
  final U second;
  const Pair(this.first, this.second);
}

class ChatModel extends ChangeNotifier {
  bool isLoading = false;
  SpeechToText speechToText = SpeechToText();
  ScrollController scrollController = ScrollController();
  bool isListening = false;
  bool available = false;
  String userInput = "";
  String voiceText = "";

  String messageListString = "";

  final TextEditingController textController = TextEditingController();

//chatuiを使用

  List<types.Message> _messages = [];
  List<types.Message> get messages => _messages;
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );
  final _apapane = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d65kai',
    firstName: 'アパパネくん',
  );
  types.User get user => _user;
  bool isShowCreate = false;
  bool isCommentLoading = false;
  bool isExampleLoading = false;
  bool isValidCreate = false;
  int chatCount = 4;
  String _exampleText = "";
  String get exampleText => _exampleText.trim().length > 6
      ? _exampleText.trim().substring(0, 6)
      : _exampleText.trim();

  void init(BuildContext context) async {
    _messages = [];
    isShowCreate = false;
    isCommentLoading = true;
    chatCount = 4;
    isListening = false;
    _exampleText = "";
    isExampleLoading = false;
    isValidCreate = false;
    textController.clear();
    textController.text = "";
    notifyListeners();
    routes.toChatScreen(context: context);
    _replyMessage();
    await Future.delayed(const Duration(milliseconds: 500));
    _replyMessage();
  }

  void cancel() {
    isShowCreate = false;
    if (_messages.isNotEmpty && _messages.last is types.TextMessage) {
      _replyMessage(text: (_messages.last as types.TextMessage).text);
    }
    notifyListeners();
  }

  void _addMessage(types.Message message) {
    _messages.insert(0, message);
    _checkMessagesLength();
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500));
  }

  void _checkMessagesLength() {
    int userMessageCount =
        _messages.where((message) => message.author.id == _user.id).length;
    if (userMessageCount > 0 && userMessageCount % chatCount == 0) {
      isShowCreate = true;
      chatCount += 4;
    } else {
      isShowCreate = false;
    }
  }

  void exampleAndVoiceSendPressed(String text,
      {bool isVoice = false, required BuildContext context}) {
    if (isExampleLoading) return;
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );
    _addMessage(textMessage);
    if (isVoice) {
      isListening = false;
      speechToText.stop();
      Navigator.pop(context);
      textController.clear();
      textController.text = "";
      notifyListeners();
    }
    FocusScope.of(context).unfocus();
    if (!isShowCreate) {
      _replyMessage(text: text);
    }
    _startExampleLoading();
  }

  void handleSendPressed(BuildContext context, types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    _addMessage(textMessage);
    FocusScope.of(context).unfocus();
    if (!isShowCreate) {
      _replyMessage(text: message.text);
    }
  }

  Future<String> _claude(
      String prompt, String systemPrompt, String apiKeyName) async {
    const String model = "claude-3-haiku-20240307";
    final String apiKey = dotenv.get(apiKeyName);
    final url = Uri.https('api.anthropic.com', '/v1/messages');

    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'Anthropic-Version': '2023-06-01',
    };

    final body = jsonEncode({
      'model': model,
      'max_tokens': 1024,
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': prompt},
      ]
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData =
            jsonDecode(utf8.decode(response.bodyBytes));
        return responseData['content'][0]['text'];
      } catch (e) {
        debugPrint('Error decoding response: $e');
        return "";
      }
    } else {
      const String responseData = "error";
      debugPrint('Error response: ${response.statusCode}, ${response.body}');
      return responseData;
    }
  }

  Future<String> _example(String text) async {
    const String prompt = '''
   <prompt>
    <role>Assistant to boost children's imagination</role>
    <skill>Stimulate children's creativity with single-word responses in the style of a shonen manga</skill>
    <instructions>
        <item>Responses must be a single word only.</item>
    </instructions>
    <example>
        <question>What kind of place is it?</question>
        <answer>Forest</answer>
        <question>Who should be the protagonist of the story?</question>
        <answer>Takashi</answer>
    </example>
    <input_prompt>Provide a single-word response in hiragana to stimulate a child's imagination, appropriate to the context. Context:</input_prompt>
</prompt>
    ''';
    
    final String response = await _claude(
        text + prompt, "Please reply in Japanese.", "ANTHROPIC_API_KEY_SHOTA");
        // text + prompt, "Please reply in Japanese.", "ANTHROPIC_API_KEY");
    // final String response = "example";
    _exampleText = response;
    notifyListeners();
    return response;
  }

  void _replyMessage({String text = ""}) async {
    _startCommentLoading();
    if (_messages.length < 8) {
      text = await _replyTemplate(_messages.length);
      final replyMessage = types.TextMessage(
        author: _apapane,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: text,
      );

      _addMessage(replyMessage);
    } else {
      if (isShowCreate) return;
      text = await _talk(text);
      final replyMessage = types.TextMessage(
        author: _apapane,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: text,
      );
      _addMessage(replyMessage);
    }
    if (isListening) stopListening();
    _endCommentLoading();
    if (_messages.length == 1) return;
    _startExampleLoading();
    Future.delayed(const Duration(milliseconds: 500));
    debugPrint("text: $text");
    await _example(text);
    _endExampleLoading();
  }

  Future<String> _replyTemplate(int countMessages) async {
    switch (countMessages) {
      case 0:
        return "こんにちは！いっしょにものがたりをつくりましょう！";
      case 1:
        return "このおはなしの主人公はだれ？";
      case 3:
        await Future.delayed(const Duration(milliseconds: 600));
        return "このおはなしの場所はどこ？";
      case 5:
        await Future.delayed(const Duration(milliseconds: 600));
        return "他にだれが出てくる？";
      case 7:
        await Future.delayed(const Duration(milliseconds: 600));
        isValidCreate = true;
        notifyListeners();
        return "その子はおともだち？それとも敵？";
      default:
        await Future.delayed(const Duration(milliseconds: 600));
        return "そうしましょう！";
    }
  }

  Future<String> _talk(String text) async {
    final String prompt = '''
      <chatlog>
      $text
      </chatlog>

      <instruction>
        Please look at the conversation history so far in [[chatlog]] and output only the Assistant's next reply. 
        Assistant should output a reaction to Human's last statement in [[chatlog]] and another additional question regarding the setting of the story. 
        We have already asked about the name of the main character and location, so please start with other questions.
      </instruction>

      You are a friendly interviewer who asks children about the stories they imagine.
      Speak in a friendly, frank tone, without using honorifics.
      Do not repeat questions already asked in the conversation history.
      Answer in easy-to-understand Japanese, using no more than 30 characters per sentence.
      The ratio of kanji to hiragana should be about 1:4.
      Avoid difficult-to-read kanji characters.
      Omit preambles and output only agreement (e.g., "I see, so the main character is ~!", "Nice!") and a question.
      Follow these instructions to react to the user's last statement in the chatlog and ask another question regarding the story setting.
      Focus on questions that help the child unpack their thoughts step by step, and avoid repeating questions already asked.

    ''';
    final String systemPrompt = '''
    <instruction>
      Please look at the conversation history so far in [[chatlog]] and output only the Assistant's next reply. 
      Assistant should output a reaction to Human's last statement in [[chatlog]] and another additional question regarding the setting of the story. 
      We have already asked about the name of the main character and location, so please start with other questions.
    </instruction>
    ''';
    final String response =
        await _claude(prompt, systemPrompt, "ANTHROPIC_API_KEY");
    return response;
  }

  void _startCommentLoading() {
    isCommentLoading = true;
    notifyListeners();
  }

  void _endCommentLoading() {
    isCommentLoading = false;
    notifyListeners();
  }

  void _startExampleLoading() {
    isExampleLoading = true;
    notifyListeners();
  }

  void _endExampleLoading() {
    isExampleLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> stableDiffusion(
      String prompt, String negativePrompt,
      {int seed = 0}) async {
    const String url =
        "https://api.stability.ai/v1/generation/stable-diffusion-v1-6/text-to-image";
    final String apiKey = dotenv.get("STABLE_DIFFUSION_API_KEY");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'text_prompts': [
          {
            'text': prompt,
            'weight': 1.0,
          },
          {
            'text': negativePrompt,
            'weight': -1.0,
          }
        ],
        'cfg_scale': 7,
        'height': 1344,
        'width': 768,
        'samples': 1,
        'steps': 30,
        'seed': seed,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData["artifacts"][0];
      } catch (e) {
        debugPrint('Error decoding image: $e');
        return {};
      }
    } else {
      return {};
    }
  }

  //_makeStory
  Future<List<Map<String, dynamic>>> _makeStory({required String text}) async {
    final String prompt = '''
    <chatlog>
    $text
    </chatlog>

    Create a narrative based on the [[chatlog]].Make it fun and exciting for kids!

    <storyline>
    *Stories that delve deeply into the inner life, emotions, surprising secrets, and backgrounds of the main character and other characters
    *Stories with unexpected events and foreshadowing
    *A story in which the protagonist faces unexpected difficulties or obstacles and manages to overcome them with innovative solutions
    *A story in which the protagonists realize their inner power and demonstrate it to create an unexpected turn of events
    *A story in which unexpected events occur as the protagonist confronts and overcomes his or her own weaknesses and shortcomings
    *A touching story in which unexpected encounters and events occur as the protagonist strives to achieve his or her dreams and goals
    *A story in which unexpected relationships between characters are revealed
    </storyline>

    <instruction>
    *Describe in detail the names of the characters, what kind of creatures they are, their appearance, personalities, etc., using your imagination.
    *Describe in detail the location of the story, the scenery, the surroundings, etc., using your imagination.
    *Avoid mediocre storylines.
    *As far as possible, describe the characters in detail and clearly in words.For example, instead of abstract and vague descriptions such as 'a large monster with magical powers', use clear and detailed descriptions such as 'a 10m long dragon that breathes fire'.
    *Include lots of specific lines and words spoken by the characters.
    *Write very concrete stories, not abstract. Come up with a clear and detailed setting for all characters and explain it in writing.
    </instruction>

    <OutputExample>
    {
      "introduction": "ここにIntroductionの章が入る",
      "development": "ここにDevelopmentの章が入る",
      "turn": "ここにTurnの章が入る",
      "conclusion": "ここにConclusionの章が入る"
    }
    </OutputExample>

    Output a story in easy Japanese that can be understood by middle school students
    The ratio of kanji to hiragana should be about 1:4. Avoid difficult-to-read kanji characters.
    The story consists of four paragraphs.
    Use JSON format with the keys "introduction", "development", "turn", and "conclusion".
    Output only JSON.
    Please refer to [[OutputExample]] for the output format.

    Write a story with interesting twists and turns as described in the [[storyline]].
    Follow the [[instruction]] to create a story.

    Output:
    ''';
    const String systemPrompt = '''
    <storyline>
    *Stories that delve deeply into the inner life, emotions, surprising secrets, and backgrounds of the main character and other characters
    *Stories with unexpected events and foreshadowing
    *A story in which the protagonist faces unexpected difficulties or obstacles and manages to overcome them with innovative solutions
    *A story in which the protagonists realize their inner power and demonstrate it to create an unexpected turn of events
    *A story in which unexpected events occur as the protagonist confronts and overcomes his or her own weaknesses and shortcomings
    *A touching story in which unexpected encounters and events occur as the protagonist strives to achieve his or her dreams and goals
    *A story in which unexpected relationships between characters are revealed
    </storyline>

    <instruction>
    *Describe in detail the names of the characters, what kind of creatures they are, their appearance, personalities, etc., using your imagination.
    *Describe in detail the location of the story, the scenery, the surroundings, etc., using your imagination.
    *Avoid mediocre storylines.
    *As far as possible, describe the characters in detail and clearly in words.For example, instead of abstract and vague descriptions such as 'a large monster with magical powers', use clear and detailed descriptions such as 'a 10m long dragon that breathes fire'.
    *Include lots of specific lines and words spoken by the characters.
    *Write very concrete stories, not abstract. Come up with a clear and detailed setting for all characters and explain it in writing.
    </instruction>

    <OutputExample>
    {
      "introduction": "ここにIntroductionの章が入る",
      "development": "ここにDevelopmentの章が入る",
      "turn": "ここにTurnの章が入る",
      "conclusion": "ここにConclusionの章が入る"
    }
    </OutputExample>

    Output a story in easy Japanese that can be understood by middle school students
    The ratio of kanji to hiragana should be about 1:4. Avoid difficult-to-read kanji characters.
    The story consists of four paragraphs.
    Use JSON format with the keys "introduction", "development", "turn", and "conclusion".
    Output only JSON.
    Please refer to [[OutputExample]] for the output format.

    Write a story with interesting twists and turns as described in the [[storyline]].
    Follow the [[instruction]] to create a story.
    ''';

    var retries = 0;
    const int maxRetries = 3;
    Map<String, dynamic> story = {};
    int seconds = 2;
    while (retries < maxRetries) {
      try {
        // APIリクエストを行う
        final data = await _claude(prompt, systemPrompt, "ANTHROPIC_API_KEY");

        // レスポンスをJSONとしてデコードする
        story = jsonDecode(data);
        break;
      } on FormatException catch (e) {
        // JSONデコードに失敗した場合はリトライする
        debugPrint('Invalid JSON response, retrying... (${e.message})');
      } catch (e) {
        // その他の例外をキャッチし、適切に処理する
        debugPrint('Error occurred: $e');
      }

      retries++;
      await Future.delayed(Duration(seconds: seconds)); // 2秒待機してリトライ
      seconds += 4;
    }

    if (retries >= maxRetries) {
      // 最大リトライ回数を超えた場合はエラー
      throw Exception('Maximum retries exceeded');
    }

    debugPrint('story: $story');
    final String imagePrompt = '''
    <story>
    $story
    </story>

    <positive>
    detailed anime-style illustration, 3d, digital painting, vibrant colors, highly detailed, digital art, clearly
    </positive>

    <negative>
    low quality, cartoon-like, 2d, text, logo, watermark, vague, blurred
    </negative>

    First, figure out who and what each of the main character and other characters in the [[story]] look like.
    Generate positive_prompt_characters and negative_prompt_characters to have stablediffusion generate images of what the main character and the other characters look like.
    Include positive_prompt_characters in the "prompt" of all four paragraphs and negative_prompt_characters in the "negative_prompt" of all four paragraphs.
    In other words, the images are generated so that the protagonist consistently has the same look, the same mood, the same clothes and the same face in all paragraphs. 
    For each of the other characters, the images are generated so that they consistently have the same look, the same mood, the same clothes and the same face in all paragraphs. 
    The same characters should appear consistently across all four paragraphs.

    Please output positive and negative prompts in English for StableDiffusion to generate an image of the scene depicted in [[paragraph]], down to the actions and characters.
    The [[story]] is divided into 4 paragraphs in json format and I would like you to output positive and negative prompts in English for each of them. In other words, I would like you to output 8 prompts in total.
    Positive prompts should include the words in [[positive]] and negative prompts should include the words in [[negative]]. Other words can of course be included as well.
    Please faithfully reproduce the characterization, atmosphere and worldview of the main character. Please include detailed instructions from the name of the main character to describe in detail what you specifically imagine it to look like.
    I want StableDiffusion to generate an image that shows at a glance even the actions of what the main character is doing.

    Please output in JSON format as in the following [[OutputExample]].
    <OutputExample>
    {
      “introduction”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “development”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “turn”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “conclusion”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ]
    }
    </OutputExample>

    Output only JSON.

    Output:
    ''';

    const String imageSystemPrompt = '''
    Please output positive and negative prompts in English for StableDiffusion to generate an image of the scene depicted in [[paragraph]], down to the actions and characters.
    The [[story]] is divided into 4 paragraphs in json format and I would like you to output positive and negative prompts in English for each of them. In other words, I would like you to output 8 prompts in total.
    Positive prompts should include the words in [[positive]] and negative prompts should include the words in [[negative]]. Other words can of course be included as well.
    Please faithfully reproduce the characterization, atmosphere and worldview of the main character. Please include detailed instructions from the name of the main character to describe in detail what you specifically imagine it to look like.
    I want StableDiffusion to generate an image that shows at a glance even the actions of what the main character is doing.
    
    First, figure out who and what each of the main character and other characters in the [[story]] look like.
    Generate positive_prompt_characters and negative_prompt_characters to have stablediffusion generate images of what the main character and the other characters look like.
    Include positive_prompt_characters in the "prompt" of all four paragraphs and negative_prompt_characters in the "negative_prompt" of all four paragraphs.
    In other words, the images are generated so that the protagonist consistently has the same look, the same mood, the same clothes and the same face in all paragraphs. 
    For each of the other characters, the images are generated so that they consistently have the same look, the same mood, the same clothes and the same face in all paragraphs. 
    The same characters should appear consistently across all four paragraphs.

    Please output in JSON format as in the following [[OutputExample]].
    <OutputExample>
    {
      “introduction”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “development”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “turn”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
      “conclusion”: [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ]
    }
    </OutputExample>

    Output only JSON.
    ''';

    retries = 0;
    Map<String, dynamic> imageStory = {};

    while (retries < maxRetries) {
      try {
        // APIリクエストを行う

        final data =
            await _claude(imagePrompt, imageSystemPrompt, "ANTHROPIC_API_KEY");

        // レスポンスをJSONとしてデコードする
        imageStory = jsonDecode(data);
        break;
      } on FormatException catch (e) {
        // JSONデコードに失敗した場合はリトライする
        debugPrint('Invalid JSON response, retrying... (${e.message})');
      } catch (e) {
        // その他の例外をキャッチし、適切に処理する
        debugPrint('Error occurred: $e');
      }

      retries++;
      await Future.delayed(const Duration(seconds: 2)); // 2秒待機してリトライ
    }

    if (retries >= maxRetries) {
      // 最大リトライ回数を超えた場合はエラー
      throw Exception('Maximum retries exceeded');
    }

    Map<String, Pair<String, String>> elements = {};

    imageStory.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            List<String> keys = item.keys.toList();
            elements[key] = Pair(keys[0], keys[1]);
          }
        }
      }
    });

    final List<Map<String, dynamic>> outputStory = [];

    final firstKey = imageStory.keys.first;
    final firstElement = imageStory[firstKey];
    final String firstPositivePrompt =
        elements[firstKey]?.first ?? "positive_prompt";
    final String firstNegativePrompt =
        elements[firstKey]?.second ?? "negative_prompt";

    if (firstElement is List &&
        firstElement.isNotEmpty &&
        firstElement[0] is Map<String, dynamic>) {
      if (firstElement[0].containsKey(firstPositivePrompt) &&
          firstElement[0].containsKey(firstNegativePrompt)) {
        final Map<String, dynamic> firstImageOutput = await stableDiffusion(
            firstElement[0][firstPositivePrompt],
            firstElement[0][firstNegativePrompt]);
        final int seed = firstImageOutput["seed"];
        debugPrint('seed: $seed');
        outputStory.add({
          "story": story[firstKey],
          "image": firstImageOutput["base64"],
        });
      } else {
        debugPrint(
            'Key not found: $firstPositivePrompt or $firstNegativePrompt');
      }
    } else {
      debugPrint('Error: firstElement[0] is not a Map or is empty');
    }
    imageStory.remove(firstKey);

    // 並列処理するFutureのリストを作成
    // 並列処理するFutureのリストを作成
    final futures = imageStory.entries.map((entry) async {
      final key = entry.key;
      final element = entry.value;

      // Check if element[0] is a Map
      if (element[0] is! Map) {
        debugPrint('Error: Expected a Map but found ${element[0].runtimeType}');
        return null;
      }

      final String positivePrompt = elements[key]?.first ?? "positive_prompt";
      final String negativePrompt = elements[key]?.second ?? "negative_prompt";

      debugPrint('Available keys: ${element[0].keys}');
      debugPrint('Element data: ${element[0]}');

      if (element[0].containsKey(positivePrompt) &&
          element[0].containsKey(negativePrompt)) {
        final Map<String, dynamic> imageOutput = await stableDiffusion(
            element[0][positivePrompt], element[0][negativePrompt]);
        return {
          "story": story[key],
          "image": imageOutput["base64"],
        };
      } else {
        debugPrint('Key not found in element');
        return null;
      }
    }).toList();

    // 並列処理の結果を待ち、順番を維持したままoutputStoryに追加
    final results = await Future.wait(futures);
    outputStory.addAll(results
        .where((element) => element != null)
        .cast<Map<String, dynamic>>());

    debugPrint('outputStory: $outputStory');
    return outputStory;
  }

  Future<void> createButtonPressed(
      {required BuildContext context, required StoryModel storyModel}) async {
    int countIsMeMessages =
        _messages.where((message) => message.author.id == _user.id).length;
    if (countIsMeMessages > 2) {
      _startLoading();
      String message = messageListToString();
      storyModel.updateMessages(message: message);
      final test = await _makeStory(text: message);
      debugPrint('test: $test');
      try {
        List<Map<String, dynamic>> newStoryMaps =
            await _makeStory(text: message);
        debugPrint('newStoryMaps: $newStoryMaps');
        if (newStoryMaps.isNotEmpty && newStoryMaps[0]['story'] != null) {
          storyModel.getTitleTextAndImage(
              title: newStoryMaps[0]['story'], image: newStoryMaps[0]['image']);
          storyModel.updateStoryMaps(newStoryMaps: newStoryMaps);
          storyModel.toStoryPageType = ToStoryPageType.newStory;
          // ignore: use_build_context_synchronously
          routes.toStoryScreenReplacement(context: context, isNew: true);
        } else {
          debugPrint('No stories or images returned');
          voids.showFluttertoast(msg: "物語を取得できませんでした。");
        }
      } catch (e) {
        debugPrint('Error fetching story: $e');
        voids.showFluttertoast(msg: "エラーが発生しました。後ほど再試行してください。");
        routes.toHomeScreen(context: context);
      } finally {
        _endLoading();
        _messages.clear();
        notifyListeners();
      }
    }
  }

  void _startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void _endLoading() {
    isLoading = false;
    notifyListeners();
  }

  String messageListToString() {
    messageListString = "";
    messageListString += '#会話履歴です。絶対子供の世界観を参考にしてください。\n';

    for (var message in _messages) {
      if (message.author.id == _user.id) {
        messageListString +=
            "物語を作成したい子供:${(message as types.TextMessage).text}\n";
      } else {
        messageListString += "AI:${(message as types.TextMessage).text}\n";
      }
    }

    return messageListString;
  }

  void toMicUi({required BuildContext context}) {
    routes.toMicUi(context: context);
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
    messageListString = "";
    _messages.clear();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
    notifyListeners();
  }
}
