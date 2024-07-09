//dart
import 'dart:convert';

//flutter
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:go_router/go_router.dart';
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
import 'package:apapane/model_riverpod_old/story_model.dart';
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
  String _summaryMainSettings = '';
  String _exampleText = "";
  String get exampleText => _exampleText.trim().replaceAll("。", "").length > 9
      ? _exampleText.trim().replaceAll("。", "").substring(0, 9)
      : _exampleText.trim().replaceAll("。", "");
  String _lastQuestion = "";

  void init(BuildContext context) async {
    _messages = [];
    isShowCreate = false;
    isCommentLoading = true;
    chatCount = 4;
    isListening = false;
    _exampleText = "";
    _lastQuestion = "";
    _summaryMainSettings = '';
    isExampleLoading = false;
    isValidCreate = false;
    textController.clear();
    textController.text = "";
    notifyListeners();
    context.push('/chat');
    _replyMessage(context);
    await Future.delayed(const Duration(milliseconds: 500));
    // ignore: use_build_context_synchronously
    _replyMessage(context);
  }

  void cancel(BuildContext context) {
    isShowCreate = false;
    if (_messages.isNotEmpty && _messages.last is types.TextMessage) {
      _replyMessage(context,
          lastText: (_messages.last as types.TextMessage).text);
    }
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _addMessage(BuildContext context, types.Message message) {
    _messages.insert(0, message);
    _checkMessagesLength(context);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500));
  }

  void _checkMessagesLength(BuildContext context) {
    int userMessageCount =
        _messages.where((message) => message.author.id == _user.id).length;
    if (userMessageCount > 0 && userMessageCount % chatCount == 0) {
      FocusScope.of(context).unfocus();
      isShowCreate = true;
      chatCount += 4;
    } else {
      isShowCreate = false;
    }
  }

  void exampleAndVoiceSendPressed(String text,
      {bool isVoice = false, required BuildContext context}) {
    if (isExampleLoading || isCommentLoading) return;
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );
    _addMessage(context, textMessage);
    if (isVoice) {
      FocusScope.of(context).unfocus();
      isListening = false;
      speechToText.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
      textController.clear();
      textController.text = "";
      notifyListeners();
    }

    if (!isShowCreate) {
      _replyMessage(context, lastText: text);
    }
    _startExampleLoading();
  }

  void handleSendPressed(BuildContext context, types.PartialText message) {
    if (isExampleLoading || isCommentLoading) return;
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    _addMessage(context, textMessage);

    if (!isShowCreate) {
      _replyMessage(context, lastText: message.text);
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

    int retries = 0;
    const int maxRetries = 3;
    while (retries < maxRetries) {
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
      } else if (response.statusCode == 529) {
        // Handle overload error with retry
        retries++;
        await Future.delayed(Duration(seconds: 2 * retries));
        debugPrint('Retrying due to overloaded error. Retry count: $retries');
      } else {
        const String responseData = "error";
        debugPrint(
            'Error response: ${response.statusCode}, ${response.body} in _claude');
        return responseData;
      }
    }
    return "error";
  }

  Future<void> _example(String text) async {
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
    const systemPrompt =
        "Please reply in Japanese and return a solid one-word response to a question.";
    final String response =
        await _claude(text + prompt, systemPrompt, "ANTHROPIC_API_KEY_SHOTA");
    // text + prompt, "Please reply in Japanese.", "ANTHROPIC_API_KEY");
    // final String response = "example";
    _exampleText = response;
    notifyListeners();
  }

  void _replyMessage(BuildContext context, {String lastText = ""}) async {
    _startCommentLoading();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final id = const Uuid().v4();
    String reply = "";
    if (_messages.length < 8) {
      reply = await _replyTemplate(_messages.length);
      final replyMessage = types.TextMessage(
        author: _apapane,
        createdAt: createdAt,
        id: id,
        text: reply,
      );
      _lastQuestion = reply;
      _addMessage(context, replyMessage);
    } else {
      if (isShowCreate) return;
      String summarySettings = _summaryMainSettingsInitSettings();
      final chatLogs = _messageListToString();
      if (_messages.length == 9) {
        final newChatLogs =
            '$summarySettings And last Q&A Q:$_lastQuestion A:$lastText';
        reply = await _talk(newChatLogs);
      } else {
        debugPrint('chatLogs: $chatLogs');
        debugPrint('summarySettings: $summarySettings');
        final chatLogsPlusSummary =
            '$chatLogs And $summarySettings And last Q&A Q:$_lastQuestion  $lastText';
        reply = await _talk(chatLogsPlusSummary);
      }

      final replyMessage = types.TextMessage(
        author: _apapane,
        createdAt: createdAt,
        id: id,
        text: reply,
      );
      _lastQuestion = reply;
      // ignore: use_build_context_synchronously
      _addMessage(context, replyMessage);
    }
    if (isListening) stopListening();
    _endCommentLoading();
    if (_messages.length == 1) return;
    _startExampleLoading();
    await _example(reply);
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
        return "その子はおともだち？敵？それとも他の何か？";
      default:
        await Future.delayed(const Duration(milliseconds: 600));
        return "そうしましょう！";
    }
  }

  String _summaryMainSettingsInitSettings() {
    if (_messages.length > 9) return _summaryMainSettings;
    if (_messages.length > 2) {
      _summaryMainSettings +=
          'Main character of this story: ${(_messages[_messages.length - 3] as types.TextMessage).text}\n';
    }
    if (_messages.length > 4) {
      _summaryMainSettings +=
          'Location of this story: ${(_messages[_messages.length - 5] as types.TextMessage).text}\n';
    }
    if (_messages.length > 6) {
      _summaryMainSettings +=
          'Other characters of this story: ${(_messages[_messages.length - 7] as types.TextMessage).text}\n';
    }
    if (_messages.length > 8) {
      _summaryMainSettings +=
          'The Other characters is: ${(_messages[_messages.length - 9] as types.TextMessage).text} in this story. \n';
    }
    return _summaryMainSettings;
  }

  Future<String> _summaryStoryAllSettings(String chatLogs) async {
    final String prompt = '''
      <chatLogs>
      $chatLogs
      </chatLogs>

      <storyMainSettings>
      $_summaryMainSettings
      </storyMainSettings>

      <instruction>
      The answer text after the question was answered by the child.
      Summarize the content of the child's worldview answer in light of the question.
      Summarize the development of the story in detail.
      Never delete the content of the child's setting.
      Here is an example. Output the following as a sample
      Summarize the contents of [[chatLogs]] in a synopsis style, strictly adhering to and taking into account the content of [[storyMainSettings]].
      </instruction>
      <example>
      The main character is: Takashi
      Location: Mountain
      Other characters: Bear
      Other settings: Takashi is so brave boy. He is going to the mountain to find a treasure. He met a bear in the mountain. The bear is a kind bear. Takashi and the bear are going to find the treasure together.
      </example>
''';
    const String systemPrompt =
        'Carefully and rigorously set up <storyMainSettings> and <chatLogs> stories and put them together in every detail';
    final String response =
        await _claude(prompt, systemPrompt, "ANTHROPIC_API_KEY_SHOTA");
    return response;
  }

  Future<String> _talk(String summary) async {
    final String prompt = '''
      <chatLogs>
      $summary
      </chatLogs>
      <instruction>
      You are a friendly interviewer who asks children about the stories they imagine.
      Speak in a friendly, frank tone, without using honorifics.
      Do not repeat questions already asked in the [[chatLogs]].
      Answer in easy-to-understand Japanese, using no more than 30 characters per sentence.
      The ratio of kanji to hiragana should be about 1:4.
      Avoid difficult-to-read kanji characters.
      Follow these instructions to react to the user's last statement in the [[chatLogs]] and ask another question regarding the story setting.
      Focus on questions that help the child unpack their thoughts step by step, and avoid repeating questions already asked.
      </instruction>
    ''';
    const String systemPrompt = '''
    <instruction>
      Please look at the conversation history so far in [[chatLogs]] and output only the Assistant's next reply. 
      Assistant should output a reaction to Human's last statement in [[chatLogs]] and another additional question regarding the setting of the story. 
      [[NOTE: The main character, the stage, and one of the characters have already been heard. ]]]
      so please start with other questions.
      [[Be sure to limit the number of questions to one question!]] [[What is your personality? , What is its color? , What is the shape? etc.]]
      And consider fully the latest kid's answers on [[chatLogs]]
      Rough without honorifics!
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

  Future<Map<String, dynamic>> _stableDiffusion(
      String prompt, String negativePrompt,
      {int seed = 0}) async {
    const String url =
        "https://api.stability.ai/v1/generation/stable-diffusion-v1-6/text-to-image";
    final String apiKey = dotenv.get("STABLE_DIFFUSION_API_KEY");
    try {
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
        debugPrint(
            'Error response: ${response.statusCode}, ${response.body} in _stablediffusion');
        return {};
      }
    } catch (e) {
      debugPrint('Error in stableDiffusion: $e');
      return {};
    }
  }

  //_makeStory
  Future<List<Map<String, dynamic>>> _makeStory(
      {required String chatLogs}) async {
    debugPrint('summary: $_summaryMainSettings');
    final String prompt = '''
    <chatLogs>
    $chatLogs
    </chatLogs>

    <storyMainSettings>
    $_summaryMainSettings
    </storyMainSettings>

    Create a narrative based on the [[chatLogs]].Make it fun and exciting for kids!

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
    *Write an exciting title that fits the story.
    *Write very concrete stories, not abstract. Come up with a clear and detailed setting for all characters and explain it in writing.
    *Create your story in strict adherence to [[storyMainSettings]] and [[chatLogs]]. Incorrect setting of the story will result in the death of innocent people.
    </instruction>

    <OutputExample>
    {
      "title": "ここにtitleが入る",
      "introduction": "ここにIntroductionの章が入る",
      "development": "ここにDevelopmentの章が入る",
      "turn": "ここにTurnの章が入る",
      "conclusion": "ここにConclusionの章が入る"
    }
    </OutputExample>

    Output a story in easy Japanese that can be understood by middle school students
    The ratio of kanji to hiragana should be about 1:4. Avoid difficult-to-read kanji characters.
    The story consists of four paragraphs.
    Use JSON format with the keys "title", "introduction", "development", "turn", and "conclusion".
    Output only JSON.
    Please refer to [[OutputExample]] for the output format.

    Write a story with interesting twists and turns as described in the [[storyline]].
    Follow the [[instruction]] to create a story.
    {{Output only JSON.}}
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
    *Write an exciting title that fits the story.
    *Write very concrete stories, not abstract. Come up with a clear and detailed setting for all characters and explain it in writing.
    *Create your story in strict adherence to [[storyMainSettings]] and [[chatLogs]]. Incorrect setting of the story will result in the death of innocent people.
    </instruction>

    <OutputExample>
    {
      "title": "ここにtitleが入る",
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
    {{Output only JSON.}}
    ''';
    debugPrint('Starting _makeStory with chatLogs: $chatLogs');

    var retries = 0;
    const int maxRetries = 3;
    Map<String, dynamic> storyText = {};
    int seconds = 2;

    while (retries < maxRetries) {
      try {
        final data = await _claude(prompt, systemPrompt, "ANTHROPIC_API_KEY");
        storyText = jsonDecode(data);
        break;
      } on FormatException catch (e) {
        debugPrint(
            'Invalid JSON response in storyText, retrying... (${e.message}) And retrying count: $retries');
      } catch (e) {
        debugPrint('Error occurred in _makeStory: $e');
      }

      retries++;
      await Future.delayed(Duration(seconds: seconds)); // 2秒待機してリトライ
      seconds += 4;
    }

    if (retries >= maxRetries) {
      throw Exception('Maximum retries exceeded');
    }

    debugPrint('story: $storyText');
    final String imagePrompt = '''
    <story>
    $storyText
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
      "title": [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
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

    {{Output only JSON.}}

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
      "title": [
        {
          'prompt: 'text',
          'nagetive_prompt': 'text',
        }
      ], }
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

   {{Output only JSON.}}
    ''';
    retries = 0;
    Map<String, dynamic> storyImagesPrompt = {};

    while (retries < maxRetries) {
      try {
        final data =
            await _claude(imagePrompt, imageSystemPrompt, "ANTHROPIC_API_KEY");
        storyImagesPrompt = jsonDecode(data);
        break;
      } on FormatException catch (e) {
        debugPrint(
            'Invalid JSON response in storyImagesPrompt, retrying... (${e.message}) And retrying count: $retries');
      } catch (e) {
        debugPrint('Error occurred in _makeStory: $e');
      }

      retries++;
      await Future.delayed(const Duration(seconds: 2)); // 2秒待機してリトライ
    }

    if (retries >= maxRetries) {
      throw Exception('Maximum retries exceeded');
    }

    debugPrint('storyImagesPrompt: $storyImagesPrompt');
    Map<String, Pair<String, String>> elements = {};

    storyImagesPrompt.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            List<String> keys = item.keys.toList();
            if (keys.length >= 2) {
              elements[key] = Pair(keys[0], keys[1]);
            } else {
              debugPrint('Error: Not enough keys in map for key: $key');
            }
          } else {
            debugPrint('Error: Value is not a Map for key: $key');
          }
        }
      } else {
        debugPrint('Error: Value is not a List for key: $key');
      }
    });

    final List<Map<String, dynamic>> outputStory = [];

    if (storyImagesPrompt.isEmpty) {
      throw Exception('No story images found');
    }

    final firstKey = storyImagesPrompt.keys.first;
    final firstElement = storyImagesPrompt[firstKey];

    if (firstElement == null || firstElement.isEmpty) {
      throw Exception('First element is null or empty');
    }

    final String firstPositivePrompt = elements[firstKey]?.first ?? "prompt";
    final String firstNegativePrompt =
        elements[firstKey]?.second ?? "negative_prompt";

    if (firstElement is List && firstElement[0] is Map<String, dynamic>) {
      final firstElementMap = firstElement[0] as Map<String, dynamic>;
      if (firstElementMap.containsKey(firstPositivePrompt) &&
          firstElementMap.containsKey(firstNegativePrompt)) {
        final Map<String, dynamic> firstImageOutput = await _stableDiffusion(
            firstElementMap[firstPositivePrompt],
            firstElementMap[firstNegativePrompt]);
        final int seed = firstImageOutput["seed"];
        debugPrint('seed: $seed');
        outputStory.add({
          "story": storyText[firstKey],
          "image": firstImageOutput["base64"],
        });
      } else {
        debugPrint(
            'Key not found: $firstPositivePrompt or $firstNegativePrompt for key: $firstKey');
      }
    } else {
      debugPrint(
          'Error: firstElement[0] is not a Map or is empty for key: $firstKey');
    }

    storyImagesPrompt.remove(firstKey);

    final futures = storyImagesPrompt.entries.map((entry) async {
      final key = entry.key;
      final element = entry.value;

      if (element == null || element.isEmpty || element[0] is! Map) {
        debugPrint(
            'Error: Expected a non-empty list with a Map as first element for key $key');
        return null;
      }

      final String positivePrompt = elements[key]?.first ?? "prompt";
      final String negativePrompt = elements[key]?.second ?? "negative_prompt";
      final elementMap = element[0] as Map<String, dynamic>;

      debugPrint('Available keys: ${elementMap.keys}');
      debugPrint('Element data: $elementMap');

      if (elementMap.containsKey(positivePrompt) &&
          elementMap.containsKey(negativePrompt)) {
        final Map<String, dynamic> imageOutput = await _stableDiffusion(
            elementMap[positivePrompt], elementMap[negativePrompt]);
        return {
          "story": storyText[key],
          "image": imageOutput["base64"],
        };
      } else {
        debugPrint('Key not found in element for key: $key');
        return null;
      }
    }).toList();

    final results = await Future.wait(futures);
    outputStory.addAll(results
        .where((element) => element != null)
        .cast<Map<String, dynamic>>());

    debugPrint('outputStory: $outputStory');
    return outputStory;
  }

  void createButtonPressed(
      {required BuildContext context, required StoryModel storyModel}) async {
    int countIsMeMessages =
        _messages.where((message) => message.author.id == _user.id).length;
    if (countIsMeMessages > 2) {
      _startLoading(); // isLoading を true に設定
      String chatLogs = _messageListToString();
      storyModel.updateChatLogs(chatLogs: chatLogs);

      try {
        List<Map<String, dynamic>> newStoryMaps =
            await _makeStory(chatLogs: chatLogs);
        for (var story in newStoryMaps) {
          debugPrint('newStoryMaps: $story');
        }

        if (newStoryMaps.isNotEmpty && newStoryMaps[0]['story'] != null) {
          storyModel.getTitleTextAndImage(
              title: newStoryMaps[0]['story'], image: newStoryMaps[0]['image']);
          storyModel.updateStoryMaps(newStoryMaps: newStoryMaps);
          storyModel.toStoryPageType = ToStoryPageType.newStory;

          if (context.mounted) {
            // コンテキストが有効かどうかを確認
            routes.toStoryScreenReplacement(context: context, isNew: true);
            debugPrint('Navigating to StoryScreen');
          } else {
            debugPrint('not mounted!');
          }
        } else {
          debugPrint('No stories or images returned');
          await voids.showFluttertoast(msg: "物語を取得できませんでした。");
        }
      } catch (e) {
        debugPrint('Error fetching story: $e');
        if (context.mounted) {
          await voids.showFluttertoast(msg: "エラーが発生しました。後ほど再試行してください。");
          debugPrint('Error encountered, navigating back');
          Navigator.pop(context);
        }
      } finally {
        if (context.mounted) {
          debugPrint('Ending loading');
          _endLoading(); // isLoading を false に設定
          _messages.clear();
          notifyListeners();
        } else {
          debugPrint('Context is not mounted during finally');
        }
      }
    } else {
      debugPrint('Not enough messages to proceed');
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

  String _messageListToString() {
    messageListString = "";
    messageListString +=
        'Conversation History. Please refer to the absolute child\'s view of the world.\n';

    for (var message in _messages) {
      if (message.author.id == _user.id) {
        messageListString +=
            "Child who want to create a story:${(message as types.TextMessage).text}\n";
      } else {
        messageListString += "AI:${(message as types.TextMessage).text}\n";
      }
    }

    return messageListString;
  }

  void toMicUi({required BuildContext context}) {
    context.push('/mic');
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }
}
