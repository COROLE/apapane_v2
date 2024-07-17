import 'dart:convert';

import 'package:apapane/constants/prompt_constant.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/enums/env_key.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/repositories/api_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Pair<T, U> {
  final T first;
  final U second;
  const Pair(this.first, this.second);
}

class ChatViewModel extends ChangeNotifier {
  final ApiRepository _apiRepository;

  ChatViewModel(this._apiRepository);
  List<types.Message> _messages = [];
  final SpeechToText _speechToText = SpeechToText();
  bool _isLoading = false;
  bool _isListening = false;
  String _voiceText = "";
  bool _isShowCreate = false;
  bool _isCommentLoading = false;
  bool _isExampleLoading = false;
  bool _isValidCreate = false;
  int _chatCount = 4;
  String _messageListString = "";
  String _summaryMainSettings = '';
  String _exampleText = "";
  late int _seed;
  bool _isSeedInitialized = false;
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  final _apapane = const types.User(
      id: '82091008-a484-4a89-ae75-a22bf8d65kai', firstName: 'アパパネくん');
  final TextEditingController _textController = TextEditingController();
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  bool get isCommentLoading => _isCommentLoading;
  bool get isExampleLoading => _isExampleLoading;
  bool get isValidCreate => _isValidCreate;
  bool get isShowCreate => _isShowCreate;
  TextEditingController get textController => _textController;
  List<types.Message> get messages => _messages;
  types.User get user => _user;

  String get exampleText => _exampleText.trim().replaceAll("。", "").length > 9
      ? _exampleText.trim().replaceAll("。", "").substring(0, 9)
      : _exampleText.trim().replaceAll("。", "");
  String _lastQuestion = "";

  void init(BuildContext context) async {
    _resetState();
    context.push('/chat');
    _replyMessage(context);
    await Future.delayed(const Duration(milliseconds: 200));

    // ignore: use_build_context_synchronously
    _replyMessage(context);
  }

  void cancel(BuildContext context) {
    _isShowCreate = false;
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
    if (userMessageCount > 0 && userMessageCount % _chatCount == 0) {
      FocusScope.of(context).unfocus();
      _isShowCreate = true;
      _chatCount += 4;
    } else {
      _isShowCreate = false;
    }
  }

  void exampleAndVoiceSendPressed(String text,
      {bool isVoice = false, required BuildContext context}) {
    if (_isExampleLoading || _isCommentLoading) return;
    _sendMessage(context, text);
    if (isVoice) {
      _handleVoiceSend(context);
    }
  }

  void handleSendPressed(BuildContext context, types.PartialText message) {
    if (_isExampleLoading || _isCommentLoading) return;
    _sendMessage(context, message.text);
  }

  Future<void> _example(String text) async {
    final prompt = PromptConstant.generateClaudePromptForExample(text);
    const systemPrompt = PromptConstant.claudeExampleSystemPrompt;
    final result = await _apiRepository.getClaudeResponse(
        prompt, systemPrompt, EnvKey.ANTHROPIC_API_KEY_SHOTA.name);
    result.when(success: (res) {
      _exampleText = res;
      notifyListeners();
    }, failure: (_) async {
      await UIHelper.showFlutterToast('例の取得にエラーが発生しました。');
    });
  }

  void _replyMessage(BuildContext context, {String lastText = ""}) async {
    _startCommentLoading();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final id = IDCore.uuidV4();
    String reply = "";
    if (_messages.length < 8) {
      reply = await _replyTemplate(_messages.length);
      // ignore: use_build_context_synchronously
      _addMessage(context, _createTextMessage(_apapane, createdAt, id, reply));
    } else {
      if (_isShowCreate) return;
      String summarySettings = _summaryMainInitSettings();
      debugPrint('summaryInitSettings: $summarySettings');
      final chatLogs = _messageListToString();
      if (_messages.length == 9) {
        final newChatLogs =
            '$summarySettings And last Q&A Q:$_lastQuestion A:$lastText';
        reply = await _talk(newChatLogs);
      } else {
        final chatLogsPlusSummary =
            '$chatLogs And $summarySettings And last Q&A Q:$_lastQuestion  $lastText';
        reply = await _talk(chatLogsPlusSummary);
      }
      _addMessage(context, _createTextMessage(_apapane, createdAt, id, reply));
    }
    _lastQuestion = reply;
    _endCommentLoading();
    if (_messages.length > 1) {
      _startExampleLoading();
      await _example(reply);
      _endExampleLoading();
    }
  }

  Future<String> _replyTemplate(int countMessages) async {
    switch (countMessages) {
      case 0:
        return "こんにちは！いっしょにものがたりをつくりましょう！";
      case 1:
        return "このおはなしの主人公はだれ？";
      case 3:
        await Future.delayed(const Duration(milliseconds: 1000));

        return "このおはなしの場所はどこ？";
      case 5:
        await Future.delayed(const Duration(milliseconds: 1000));

        return "他にだれが出てくる？";
      case 7:
        _isValidCreate = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1000));

        return "その子はおともだち？敵？それとも他の何か？";
      default:
        return "そうしょ！";
    }
  }

  String _summaryMainInitSettings() {
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
          'Other character of this story: ${(_messages[_messages.length - 7] as types.TextMessage).text}\n';
    }
    if (_messages.length > 8) {
      _summaryMainSettings +=
          'The Other character is: ${(_messages[_messages.length - 9] as types.TextMessage).text} in this story. \n';
    }
    return _summaryMainSettings;
  }

  Future<String> _summaryStoryAllSettings(String chatLogs) async {
    String response = '';
    final String prompt = PromptConstant.generateClaudePromptForSummary(
        chatLogs, _summaryMainSettings);
    final String systemPrompt =
        PromptConstant.generateClaudeSystemPromptForSummary(
            chatLogs, _summaryMainSettings);
    final result = await _apiRepository.getClaudeResponse(
        prompt, systemPrompt, EnvKey.ANTHROPIC_API_KEY_SHOTA.name);
    result.when(success: (res) {
      response = res;
    }, failure: (_) {
      debugPrint('Error in _summaryStoryAllSettings');
    });
    return response;
  }

  Future<String> _talk(String summary) async {
    String response = '';
    final String prompt = PromptConstant.generateClaudePromptForTalk(summary);
    const String systemPrompt = PromptConstant.claudeTalkSystemPrompt;
    final result = await _apiRepository.getClaudeResponse(
        prompt, systemPrompt, EnvKey.ANTHROPIC_API_KEY.name);
    result.when(success: (res) {
      response = res;
    }, failure: (_) {
      debugPrint('Error in _talk');
    });
    return response;
  }

  void _startCommentLoading() {
    _isCommentLoading = true;
    notifyListeners();
  }

  void _endCommentLoading() {
    _isCommentLoading = false;
    notifyListeners();
  }

  void _startExampleLoading() {
    _isExampleLoading = true;
    notifyListeners();
  }

  void _endExampleLoading() {
    _isExampleLoading = false;
    notifyListeners();
  }

  Future<List<SDMap>> _makeStory({required String chatLogs}) async {
    debugPrint('summary: $_summaryMainSettings');
    final String prompt = PromptConstant.generateClaudePromptForStory(
        chatLogs, _summaryMainSettings);
    const String systemPrompt = PromptConstant.claudeStorySystemPrompt;
    debugPrint('Starting _makeStory with chatLogs: $chatLogs');
    var retries = 0;
    const int maxRetries = 3;
    SDMap storyText = {};
    const int seconds = 2;

    storyText = await _fetchDataWithRetry(
      retries: retries,
      maxRetries: maxRetries,
      seconds: seconds,
      fetchFunction: () async {
        final result = await _apiRepository.getClaudeResponse(
            prompt, systemPrompt, EnvKey.ANTHROPIC_API_KEY.name);
        return result.when(
            success: (res) => jsonDecode(res), failure: (_) => null);
      },
      errorMessage: 'Error in _makeStory storyText',
    );

    debugPrint('story: $storyText');
    final String imagePrompt =
        PromptConstant.generateClaudePromptForImage(storyText);
    const String imageSystemPrompt = PromptConstant.claudeImageSystemPrompt;
    retries = 0;
    SDMap storyImagesPrompt = {};

    storyImagesPrompt = await _fetchDataWithRetry(
      retries: retries,
      maxRetries: maxRetries,
      seconds: seconds,
      fetchFunction: () async {
        final result = await _apiRepository.getClaudeResponse(
            imagePrompt, imageSystemPrompt, EnvKey.ANTHROPIC_API_KEY.name);
        return result.when(
            success: (res) => jsonDecode(res), failure: (_) => null);
      },
      errorMessage: 'Error in _makeStory storyImagesPrompt',
    );

    debugPrint(
        'storyImagesPrompt structure: ${json.encode(storyImagesPrompt)}');

    Map<String, Pair<String, String>> elements = {};

    storyImagesPrompt.forEach((key, value) {
      if (value is List && value.isNotEmpty && value[0] is SDMap) {
        final promptMap = value[0] as SDMap;
        if (promptMap.containsKey('prompt') &&
            promptMap.containsKey('negative_prompt')) {
          elements[key] =
              Pair(promptMap['prompt'], promptMap['negative_prompt']);
        } else {
          debugPrint(
              'Error: prompt or negative_prompt not found for key: $key');
        }
      } else {
        debugPrint('Error: Unexpected structure for key: $key');
      }
    });

    final List<SDMap> outputStory = [];

    if (elements.isEmpty) {
      throw Exception('No valid story images found');
    }

    final firstKey = elements.keys.first;
    final firstElement = elements[firstKey];

    if (firstElement == null) {
      throw Exception('First element is null');
    }

    await _fetchInitialImage(
      firstKey: firstKey,
      firstElement: firstElement,
      elements: elements,
      storyText: storyText,
      outputStory: outputStory,
    );

    elements.remove(firstKey);

    await _fetchRemainingImages(
      storyImagesPrompt: elements,
      storyText: storyText,
      outputStory: outputStory,
    );

    debugPrint('outputStory: $outputStory');
    return outputStory;
  }

  void createButtonPressed(
      {required BuildContext context,
      required StoryViewModel storyViewModel}) async {
    int countIsMeMessages =
        _messages.where((message) => message.author.id == _user.id).length;
    if (countIsMeMessages > 2) {
      _startLoading();
      String chatLogs = _messageListToString();
      storyViewModel.updateChatLogs(chatLogs: chatLogs);
      try {
        List<SDMap> newStoryMaps = await _makeStory(chatLogs: chatLogs);
        if (newStoryMaps.isNotEmpty && newStoryMaps[0]['story'] != null) {
          storyViewModel.getTitleTextAndImage(
              title: newStoryMaps[0]['story'], image: newStoryMaps[0]['image']);
          storyViewModel.updateStoryMaps(newStoryMaps: newStoryMaps);
          storyViewModel.toStoryPageType = ToStoryPageType.newStory;

          if (context.mounted) {
            context.pushReplacement('/story?isNew=true');
            debugPrint('Navigating to StoryScreen');
          } else {
            debugPrint('not mounted!');
          }
        } else {
          debugPrint('No stories or images returned');
          await UIHelper.showFlutterToast('物語を取得できませんでした。');
        }
      } catch (e) {
        debugPrint('Error fetching story: $e');
        if (context.mounted) {
          context.pop();
          await UIHelper.showFlutterToast('エラーが発生しました。後ほど再試行してください。');
        }
      } finally {
        if (context.mounted) {
          _endLoading();
          _messages.clear();
          notifyListeners();
        }
      }
    } else {
      debugPrint('Not enough messages to proceed');
    }
  }

  void _startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void _endLoading() {
    _isLoading = false;
    notifyListeners();
  }

  String _messageListToString() {
    _messageListString =
        "Conversation History. Please refer to the absolute child's view of the world.\n";
    for (var message in _messages) {
      if (message.author.id == _user.id) {
        _messageListString +=
            "Child who want to create a story: ${(message as types.TextMessage).text}\n";
      } else {
        _messageListString += "AI: ${(message as types.TextMessage).text}\n";
      }
    }
    return _messageListString;
  }

  void toMicUi({required BuildContext context}) {
    context.push('/mic');
  }

  void startListening({required String localeId}) async {
    final available = await _speechToText.initialize();
    notifyListeners();
    if (available) {
      _isListening = true;
      _speechToText.listen(
        onResult: (result) {
          _voiceText = result.recognizedWords;
          _textController.text = _voiceText;
          notifyListeners();
        },
        localeId: localeId,
      );
    } else {
      _isListening = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _voiceText = "";
    if (_isListening) {
      _isListening = false;
      _speechToText.stop();
    }
    notifyListeners();
  }

// Private helper methods

  void _resetState() {
    _messages = [];
    _isShowCreate = false;
    _isCommentLoading = true;
    _chatCount = 4;
    _isListening = false;
    _exampleText = "";
    _lastQuestion = "";
    _summaryMainSettings = '';
    _isExampleLoading = false;
    _isValidCreate = false;
    _textController.clear();
    notifyListeners();
  }

  void _sendMessage(BuildContext context, String text) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: IDCore.uuidV4(),
      text: text,
    );
    _addMessage(context, textMessage);
    if (!_isShowCreate) {
      _replyMessage(context, lastText: text);
    }
    _startExampleLoading();
  }

  void _handleVoiceSend(BuildContext context) {
    FocusScope.of(context).unfocus();
    _isListening = false;
    _speechToText.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.pop();
      }
    });
    _textController.clear();
    notifyListeners();
  }

  types.TextMessage _createTextMessage(
      types.User author, int createdAt, String id, String text) {
    return types.TextMessage(
      author: author,
      createdAt: createdAt,
      id: id,
      text: text,
    );
  }

  Future<SDMap> _fetchDataWithRetry({
    required int retries,
    required int maxRetries,
    required int seconds,
    required Future<SDMap?> Function() fetchFunction,
    required String errorMessage,
  }) async {
    SDMap? data;
    while (retries < maxRetries) {
      try {
        data = await fetchFunction();
        if (data != null) break;
      } on FormatException catch (e) {
        debugPrint(
            '$errorMessage, retrying… (${e.message}) And retrying count: $retries');
      } catch (e) {
        debugPrint('$errorMessage: $e');
      }
      retries++;
      if (retries < maxRetries) {
        await Future.delayed(Duration(seconds: seconds * retries));
      }
    }
    if (retries >= maxRetries) {
      throw Exception('Maximum retries exceeded');
    }
    return data!;
  }

  Future<void> _fetchInitialImage({
    required String firstKey,
    required Pair<String, String> firstElement,
    required Map<String, Pair<String, String>> elements,
    required SDMap storyText,
    required List<SDMap> outputStory,
  }) async {
    try {
      final String firstPositivePrompt = firstElement.first;
      final String firstNegativePrompt = firstElement.second;

      if (firstPositivePrompt.isEmpty || firstNegativePrompt.isEmpty) {
        throw Exception('Invalid prompts for first image');
      }

      final result = await _apiRepository.getStableDiffusionImage(
        firstPositivePrompt,
        firstNegativePrompt,
      );

      result.when(
        success: (res) {
          final SDMap firstImageOutput = res;
          if (firstImageOutput.containsKey("seed")) {
            _seed = firstImageOutput["seed"];
            _isSeedInitialized = true;
            outputStory.add({
              "story": storyText[firstKey],
              "image": firstImageOutput["base64"],
            });
            debugPrint('seed: $_seed');
          } else {
            throw Exception('Seed not found in the response');
          }
        },
        failure: (_) {
          throw Exception('Failed to fetch initial image');
        },
      );
    } catch (e) {
      debugPrint('Error in _fetchInitialImage: $e');
      await UIHelper.showFlutterToast('タイトル画像の取得に失敗しました。');
      rethrow;
    }
  }

  Future<void> _fetchRemainingImages({
    required Map<String, Pair<String, String>> storyImagesPrompt,
    required SDMap storyText,
    required List<SDMap> outputStory,
  }) async {
    if (!_isSeedInitialized) {
      throw Exception('_seed is not initialized');
    }

    final futures = storyImagesPrompt.entries.map((entry) async {
      final key = entry.key;
      final element = entry.value;

      final String positivePrompt = element.first;
      final String negativePrompt = element.second;

      final result = await _apiRepository.getStableDiffusionImage(
        positivePrompt,
        negativePrompt,
        seed: _seed,
      );

      return result.when(success: (res) {
        final SDMap imageOutput = res;

        return {
          "story": storyText[key],
          "image": imageOutput["base64"],
        };
      }, failure: (_) async {
        await UIHelper.showFlutterToast('画像の取���に失敗しました。');
        return null;
      });
    }).toList();

    final results = await Future.wait(futures);
    outputStory.addAll(results.cast<SDMap>());
  }
}
