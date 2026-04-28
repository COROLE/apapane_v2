import 'dart:convert';

import 'package:apapane/config/app_env.dart';
import 'package:apapane/constants/prompt_constant.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/models/auth/local_session_user.dart';
import 'package:apapane/models/purchase/purchase_entitlements.dart';
import 'package:apapane/models/story/story_generation_config.dart';
import 'package:apapane/models/story/story_generation_draft.dart';
import 'package:apapane/repositories/api_repository.dart';
import 'package:apapane/repositories/purchase_repository.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/ui_core/dialog_core.dart';
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

class _GeneratedStoryPackage {
  const _GeneratedStoryPackage({
    required this.title,
    required this.titleImage,
    required this.storyPages,
    required this.draft,
    required this.storySeed,
    required this.mode,
    required this.storyOptions,
    required this.preview,
    required this.generationRequestId,
  });

  final String title;
  final String titleImage;
  final List<SDMap> storyPages;
  final StoryGenerationDraft draft;
  final int storySeed;
  final StoryMode mode;
  final StoryOptions storyOptions;
  final StoryPreview? preview;
  final String generationRequestId;
}

enum StoryCreationAccessState {
  allowed,
  loginRequired,
  purchaseRequired,
}

class ChatViewModel extends ChangeNotifier {
  static const String _incompleteImageGenerationMessage =
      '\u753b\u50cf\u3092\u5168\u90e8\u4f5c\u308c\u307e\u305b\u3093\u3067\u3057\u305f\u3002'
      '\u5c11\u3057\u5f85\u3063\u3066\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002';
  static const String _directImageNegativePrompt =
      'blurry, low quality, distorted face, extra limbs, cropped, text, letters, readable words, subtitles, captions, speech bubbles, signage, logo, watermark, book page with readable writing, frame, photorealistic, 3d render, anime screencap, comic style, sketch, rough lineart, inconsistent art style, inconsistent character design, different outfit, different species';
  static const String _directImageStylePrompt =
      'Family picture-book illustration, hand-painted gouache watercolor texture, soft pastel colors, rounded shapes, clean outlines, friendly expressions, gentle lighting, portrait orientation, vertical composition for a phone screen, no readable text, no watermark, same illustration genre across every page of the same story.';

  final ApiRepository _apiRepository;
  final PurchaseRepository _purchaseRepository;
  final LocalSessionUser? Function() _currentUserReader;

  ChatViewModel(
    this._apiRepository,
    this._purchaseRepository, {
    LocalSessionUser? Function()? currentUserReader,
  }) : _currentUserReader = currentUserReader ?? IDCore.authUser;

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
  StoryMode _selectedMode = StoryMode.standard;
  StoryOptions _storyOptions = const StoryOptions();
  StoryPreview? _storyPreview;
  StoryCreationStatus? _storyCreationStatus;
  int _previewGenerationCount = 0;
  static const int _maxPreviewGenerationCount = 3;
  final Map<int, int> _exampleCursorByStage = {};
  int _exampleSeed = DateTime.now().millisecondsSinceEpoch;
  late int _seed;
  bool _isSeedInitialized = false;
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  final _apapane = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d65kai',
    firstName: 'アパパネ',
  );
  final TextEditingController _textController = TextEditingController();
  String _lastQuestion = "";

  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  bool get isCommentLoading => _isCommentLoading;
  bool get isExampleLoading => _isExampleLoading;
  bool get isValidCreate => _isValidCreate;
  bool get isShowCreate => _isShowCreate;
  bool get hasExample => _exampleText.trim().isNotEmpty;
  TextEditingController get textController => _textController;
  List<types.Message> get messages => _messages;
  types.User get user => _user;
  String get exampleText => _exampleText.trim();
  StoryMode get selectedMode => _selectedMode;
  StoryOptions get storyOptions => _storyOptions;
  StoryPreview? get storyPreview => _storyPreview;
  StoryCreationStatus? get storyCreationStatus => _storyCreationStatus;
  int get previewGenerationCount => _previewGenerationCount;
  bool get canRegeneratePreview =>
      _previewGenerationCount < _maxPreviewGenerationCount;
  String get exampleButtonLabel {
    final text = exampleText;
    if (text.isEmpty) {
      return 'れいをつくる';
    }
    return text.length > 10 ? '${text.substring(0, 10)}…' : text;
  }

  void init(BuildContext context) async {
    _resetState();
    context.push('/chat');
    _replyMessage(context);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!context.mounted) {
      return;
    }
    _replyMessage(context);
  }

  void cancel(BuildContext context) {
    _isShowCreate = false;
    if (_messages.isNotEmpty && _messages.last is types.TextMessage) {
      _replyMessage(
        context,
        lastText: (_messages.last as types.TextMessage).text,
      );
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
    final userMessageCount =
        _messages.where((message) => message.author.id == _user.id).length;
    if (userMessageCount > 0 && userMessageCount % _chatCount == 0) {
      FocusScope.of(context).unfocus();
      _isShowCreate = true;
      _chatCount += 4;
    } else {
      _isShowCreate = false;
    }
  }

  Future<void> exampleAndVoiceSendPressed(
    String text, {
    bool isVoice = false,
    required BuildContext context,
  }) async {
    if (_isExampleLoading || _isCommentLoading) return;
    if (text.trim().isEmpty) {
      await UIHelper.showFlutterToast('れいを準備中です。');
      return;
    }
    _sendMessage(context, text);
    if (isVoice) {
      _handleVoiceSend(context);
    }
  }

  void handleSendPressed(BuildContext context, types.PartialText message) {
    if (_isExampleLoading || _isCommentLoading) return;
    _sendMessage(context, message.text);
  }

  Future<void> _example() async {
    final fallback = _buildRotatingExample();
    final questionText = _latestAssistantQuestion();

    if (!_hasClaudeAccess() || questionText.isEmpty) {
      _exampleText = fallback;
      notifyListeners();
      return;
    }

    _exampleText = await _generateAdaptiveExample(
      questionText: questionText,
      fallback: fallback,
    );
    notifyListeners();
  }

  void _replyMessage(BuildContext context, {String lastText = ""}) async {
    _startCommentLoading();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final id = IDCore.uuidV4();
    String reply = "";

    if (_messages.length < 8) {
      reply = await _replyTemplate(_messages.length);
      if (!context.mounted) {
        _endCommentLoading();
        return;
      }
      _addMessage(context, _createTextMessage(_apapane, createdAt, id, reply));
    } else {
      if (_isShowCreate) return;
      final summarySettings = _summaryMainInitSettings();
      debugPrint('summaryInitSettings: $summarySettings');
      final chatLogs = _messageListToString();
      if (_messages.length == 9) {
        final newChatLogs =
            '$summarySettings さいごのまとめ質問: $_lastQuestion こたえ: $lastText';
        reply = await _talk(newChatLogs);
      } else {
        final chatLogsPlusSummary =
            '$chatLogs $summarySettings さいごのまとめ質問: $_lastQuestion こたえ: $lastText';
        reply = await _talk(chatLogsPlusSummary);
      }
      if (!context.mounted) {
        _endCommentLoading();
        return;
      }
      _addMessage(context, _createTextMessage(_apapane, createdAt, id, reply));
    }

    _lastQuestion = reply;
    _endCommentLoading();
    if (_messages.length > 1) {
      _startExampleLoading();
      await _example();
      _endExampleLoading();
    }
  }

  Future<String> _replyTemplate(int countMessages) async {
    switch (countMessages) {
      case 0:
        return 'こんにちは。どんなおはなしを つくりたい？';
      case 1:
        return 'だれが しゅじんこうだと たのしい？';
      case 3:
        await Future.delayed(const Duration(milliseconds: 1000));
        return 'その おはなしの ばしょは どこがいい？';
      case 5:
        await Future.delayed(const Duration(milliseconds: 1000));
        return 'いっしょに でてくる なかまは だれ？';
      case 7:
        _isValidCreate = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1000));
        return 'そのこは どんな せいかく？ きまったら「つくる」を押してね。';
      default:
        return 'そうなんだ。';
    }
  }

  String _summaryMainInitSettings() {
    if (_messages.length > 9) return _summaryMainSettings;
    if (_messages.length > 2) {
      _summaryMainSettings +=
          'このおはなしの主人公: ${(_messages[_messages.length - 3] as types.TextMessage).text}\n';
    }
    if (_messages.length > 4) {
      _summaryMainSettings +=
          'このおはなしの場所: ${(_messages[_messages.length - 5] as types.TextMessage).text}\n';
    }
    if (_messages.length > 6) {
      _summaryMainSettings +=
          'このおはなしの仲間: ${(_messages[_messages.length - 7] as types.TextMessage).text}\n';
    }
    if (_messages.length > 8) {
      _summaryMainSettings +=
          '仲間のせつめい: ${(_messages[_messages.length - 9] as types.TextMessage).text}\n';
    }
    return _summaryMainSettings;
  }

  Future<String> _talk(String summary) async {
    if (!_hasClaudeAccess()) {
      return 'いいね。もうひとつ教えて。できたら「つくる」を押してね。';
    }

    String response = '';
    final prompt = PromptConstant.generateClaudePromptForTalk(summary);
    const systemPrompt = PromptConstant.claudeTalkSystemPrompt;
    final result = await _apiRepository.getClaudeResponse(
      prompt,
      systemPrompt,
      'conversation',
    );
    result.when(
      success: (res) {
        response = res;
      },
      failure: (error) {
        debugPrint('Error in _talk: $error');
        response = _fallbackTalk();
      },
    );
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

  Future<_GeneratedStoryPackage> _makeStory({
    required String chatLogs,
    required StoryMode mode,
    required StoryOptions storyOptions,
    required StoryPreview? preview,
    required String generationRequestId,
  }) async {
    debugPrint('summary: $_summaryMainSettings');
    final prompt = PromptConstant.generateClaudePromptForStory(
      chatLogs,
      _summaryMainSettings,
    );
    const systemPrompt = PromptConstant.claudeStorySystemPrompt;
    debugPrint('Starting _makeStory with chatLogs: $chatLogs');
    var retries = 0;
    const maxRetries = 3;
    SDMap storyText = {};
    const seconds = 2;

    try {
      storyText = await _fetchDataWithRetry(
        retries: retries,
        maxRetries: maxRetries,
        seconds: seconds,
        fetchFunction: () async {
          final result = await _apiRepository.getClaudeResponse(
            prompt,
            systemPrompt,
            'story',
            jsonOutput: true,
            responseJsonSchema: _storyJsonSchemaForMode(mode),
            storyMode: mode.key,
            storyOptions: storyOptions.toJson(),
            preview: preview == null
                ? null
                : {
                    'title': preview.title,
                    'summary': preview.summary,
                    'pagePlan': preview.pagePlan,
                  },
          );
          return result.when(
            success: (res) => jsonDecode(res),
            failure: (_) => null,
          );
        },
        errorMessage: 'Error in _makeStory storyText',
      );
    } catch (error) {
      debugPrint('Falling back to local story text: $error');
      return _buildLocalStoryPackage(
        chatLogs: chatLogs,
        mode: mode,
        storyOptions: storyOptions,
        preview: preview,
        generationRequestId: generationRequestId,
      );
    }

    debugPrint('story: $storyText');
    final draft = _draftFromStoryResponse(
      storyText,
      mode: mode,
      pageCount: mode.pageCount,
    );
    final fallbackStory = StoryGenerationComposer.storyPagesFromDraft(draft);
    return _buildStoryWithDirectImages(
      draft: draft,
      fallbackStory: fallbackStory,
      mode: mode,
      storyOptions: storyOptions,
      preview: preview,
      generationRequestId: generationRequestId,
    );
  }

  void createButtonPressed({
    required BuildContext context,
  }) async {
    await generateStoryPreviewButtonPressed(
      context: context,
      mode: _selectedMode,
      storyOptions: _storyOptions,
    );
  }

  Future<void> generateStoryPreviewButtonPressed({
    required BuildContext context,
    required StoryMode mode,
    required StoryOptions storyOptions,
    bool navigate = true,
  }) async {
    final countIsMeMessages =
        _messages.where((message) => message.author.id == _user.id).length;
    if (countIsMeMessages <= 2) {
      debugPrint('Not enough messages to proceed');
      return;
    }
    if (!canRegeneratePreview) {
      await UIHelper.showFlutterToast('あらすじの作り直しは3回までです。');
      return;
    }

    _selectedMode = mode;
    _storyOptions = storyOptions;
    _startLoading();
    try {
      final chatLogs = _messageListToString();
      final result = await _apiRepository.generateStoryPreview(
        chatLogs: chatLogs,
        summaryMainSettings: _summaryMainSettings,
        mode: mode.key,
        storyOptions: storyOptions.toJson(),
      );
      _storyPreview = await result.when(
        success: (json) async => StoryPreview.fromJson(
          json,
          fallbackMode: mode,
          fallbackOptions: storyOptions,
        ),
        failure: (_) async => _buildLocalStoryPreview(
          mode: mode,
          storyOptions: storyOptions,
        ),
      );
      _previewGenerationCount += 1;
      _storyCreationStatus = await _loadStoryCreationStatus();
      notifyListeners();
      if (context.mounted && navigate) {
        context.push('/story/preview');
      }
    } finally {
      if (context.mounted) {
        _endLoading();
      }
    }
  }

  Future<void> regenerateStoryPreview({
    required BuildContext context,
  }) async {
    await generateStoryPreviewButtonPressed(
      context: context,
      mode: _selectedMode,
      storyOptions: _storyOptions,
      navigate: false,
    );
  }

  Future<void> confirmPreviewAndCreate({
    required BuildContext context,
    required StoryViewModel storyViewModel,
  }) async {
    final preview = _storyPreview;
    if (preview == null) {
      await UIHelper.showFlutterToast('あらすじを先に作ってください。');
      return;
    }

    final currentUser = _currentUserReader();
    final entitlements = currentUser == null || currentUser.isGuest
        ? PurchaseEntitlements.initial()
        : await _loadStoryCreationEntitlements(currentUser.uid);
    if (!context.mounted) {
      return;
    }
    final accessState = storyCreationAccessForTesting(
      currentUser: currentUser,
      entitlements: entitlements ?? PurchaseEntitlements.initial(),
      coinCost: preview.coinCost,
    );
    if (accessState == StoryCreationAccessState.loginRequired) {
      _showLoginRequiredDialog(context);
      return;
    }
    if (accessState == StoryCreationAccessState.purchaseRequired) {
      _showStoreRequiredDialog(context);
      return;
    }

    StoryGenerationReservation? reservation;
    final generationRequestId = IDCore.uuidV4();
    _startLoading();
    final chatLogs = _messageListToString();
    storyViewModel.updateChatLogs(chatLogs: chatLogs);
    try {
      final reserveResult = await _apiRepository.reserveStoryGeneration(
        mode: preview.mode.key,
        requestId: generationRequestId,
      );
      reservation = await reserveResult.when(
        success: (json) async => StoryGenerationReservation.fromJson(json),
        failure: (error) async =>
            throw error ?? const StoryCreationAccessDenied(),
      );

      final storyPackage = _hasStoryGenerationAccess()
          ? await _makeStory(
              chatLogs: chatLogs,
              mode: preview.mode,
              storyOptions: _storyOptions,
              preview: preview,
              generationRequestId: generationRequestId,
            )
          : _buildLocalStoryPackage(
              chatLogs: chatLogs,
              mode: preview.mode,
              storyOptions: _storyOptions,
              preview: preview,
              generationRequestId: generationRequestId,
            );
      final newStoryMaps = storyPackage.storyPages;
      if (newStoryMaps.isNotEmpty && newStoryMaps[0]['story'] != null) {
        storyViewModel.getTitleTextAndImage(
          title: storyPackage.title,
          image: storyPackage.titleImage,
        );
        storyViewModel.setTransientNewStorySession(
          draft: storyPackage.draft,
          storySeed: storyPackage.storySeed,
        );
        storyViewModel.setTransientStoryMetadata(
          mode: storyPackage.mode,
          storyOptions: storyPackage.storyOptions,
          preview: storyPackage.preview,
          generationRequestId: storyPackage.generationRequestId,
        );
        storyViewModel.updateStoryMaps(newStoryMaps: newStoryMaps);
        storyViewModel.toStoryPageType = ToStoryPageType.newStory;
        final failedImagePageIndexes = await storyViewModel.prewarmStoryImages(
          isNew: true,
          requireGeneratedImages: true,
        );
        if (failedImagePageIndexes.isNotEmpty) {
          debugPrint(
            'Generated story image verification failed for pages: '
            '$failedImagePageIndexes',
          );
          throw StateError(_incompleteImageGenerationMessage);
        }

        await _apiRepository.completeStoryGeneration(
          requestId: generationRequestId,
        );

        if (context.mounted) {
          context.pushReplacement('/story?isNew=true');
          _messages.clear();
          debugPrint('Navigating to StoryScreen');
        } else {
          debugPrint('not mounted!');
        }
      } else {
        debugPrint('No stories or images returned');
        await UIHelper.showFlutterToast('おはなしを取得できませんでした。');
      }
    } catch (e) {
      debugPrint('Error fetching story: $e');
      if (reservation != null) {
        await _apiRepository.cancelStoryGeneration(
          requestId: generationRequestId,
          reason: e.toString(),
        );
      }
      if (context.mounted) {
        await UIHelper.showFlutterToast(_errorMessage(e));
      }
    } finally {
      if (context.mounted) {
        _endLoading();
        notifyListeners();
      }
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
    _messageListString = "会話の記録です。子どもの想像を大切にして読んでください。\n";
    for (final message in _messages) {
      if (message.author.id == _user.id) {
        _messageListString +=
            "子どものこたえ: ${(message as types.TextMessage).text}\n";
      } else {
        _messageListString += "アパパネ: ${(message as types.TextMessage).text}\n";
      }
    }
    return _messageListString;
  }

  void toMicUi({required BuildContext context}) {
    context.push('/mic');
  }

  Future<void> startListening({required String localeId}) async {
    try {
      final available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (_) async {
          _isListening = false;
          notifyListeners();
          await UIHelper.showFlutterToast('音声認識に失敗しました。マイク権限を確認してください。');
        },
      );

      if (!available) {
        _isListening = false;
        notifyListeners();
        await UIHelper.showFlutterToast(
          'マイクが使えません。端末の権限設定を確認してください。',
        );
        return;
      }

      _isListening = true;
      notifyListeners();
      await _speechToText.listen(
        onResult: (result) {
          _voiceText = result.recognizedWords;
          _textController.text = _voiceText;
          notifyListeners();
        },
        localeId: localeId,
      );
    } catch (error) {
      _isListening = false;
      notifyListeners();
      debugPrint('Failed to start speech recognition: $error');
      await UIHelper.showFlutterToast('音声認識を開始できませんでした。');
    }
  }

  Future<void> stopListening() async {
    _voiceText = "";
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
    }
    notifyListeners();
  }

  void _resetState() {
    _messages = [];
    _isShowCreate = false;
    _isCommentLoading = true;
    _chatCount = 4;
    _isListening = false;
    _exampleText = "";
    _exampleCursorByStage.clear();
    _exampleSeed = DateTime.now().millisecondsSinceEpoch;
    _lastQuestion = "";
    _summaryMainSettings = '';
    _isExampleLoading = false;
    _isValidCreate = false;
    _selectedMode = StoryMode.standard;
    _storyOptions = const StoryOptions();
    _storyPreview = null;
    _storyCreationStatus = null;
    _previewGenerationCount = 0;
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
    types.User author,
    int createdAt,
    String id,
    String text,
  ) {
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
        debugPrint('$errorMessage, retrying... (${e.message}) count: $retries');
      } catch (e) {
        debugPrint('$errorMessage: $e');
      }
      retries++;
      if (retries < maxRetries) {
        await Future.delayed(Duration(seconds: seconds * retries));
      }
    }
    if (retries >= maxRetries) {
      throw Exception('読み込み回数の上限をこえました。');
    }
    return data!;
  }

  // ignore: unused_element
  Future<void> _fetchInitialImage({
    required String firstKey,
    required Pair<String, String> firstElement,
    required Map<String, Pair<String, String>> elements,
    required SDMap storyText,
    required List<SDMap> outputStory,
  }) async {
    try {
      final firstPositivePrompt = firstElement.first;
      final firstNegativePrompt = firstElement.second;

      if (firstPositivePrompt.isEmpty || firstNegativePrompt.isEmpty) {
        throw Exception('最初の画像の設定が正しくありません。');
      }

      final result = await _apiRepository.getStableDiffusionImageWithRetry(
        firstPositivePrompt,
        firstNegativePrompt,
        isValid: (res) =>
            res.containsKey("seed") && _extractImageSource(res) != null,
        invalidResultError: (res) => StateError(
          'Image generation response was missing seed or image data: $res',
        ),
      );

      result.when(
        success: (res) {
          final firstImageOutput = res;
          if (firstImageOutput.containsKey("seed")) {
            _seed = firstImageOutput["seed"];
            _isSeedInitialized = true;
            final imageSource = _extractImageSource(firstImageOutput);
            outputStory.add({
              "story": storyText[firstKey],
              "image": imageSource,
            });
            debugPrint('seed: $_seed');
          } else {
            debugPrint('API response: $firstImageOutput');
            throw Exception(
              '画像のseedが見つかりませんでした。response: $firstImageOutput',
            );
          }
        },
        failure: (error) {
          debugPrint('API error: $error');
          throw Exception('最初の画像を取得できませんでした。エラー: $error');
        },
      );
    } catch (e) {
      debugPrint('Error in _fetchInitialImage: $e');
      await UIHelper.showFlutterToast('タイトル画像の取得に失敗しました。エラー: $e');
      rethrow;
    }
  }

  // ignore: unused_element
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

      final positivePrompt = element.first;
      final negativePrompt = element.second;

      final result = await _apiRepository.getStableDiffusionImageWithRetry(
        positivePrompt,
        negativePrompt,
        seed: _seed,
        isValid: (res) => _extractImageSource(res) != null,
        invalidResultError: (res) => StateError(
            'Image generation response was missing image data: $res'),
      );

      return result.when(
        success: (res) {
          final imageOutput = res;
          final imageSource = _extractImageSource(imageOutput);
          return {
            "story": storyText[key],
            "image": imageSource,
          };
        },
        failure: (_) async {
          await UIHelper.showFlutterToast('画像の取得に失敗しました。');
          return null;
        },
      );
    }).toList();

    final results = await Future.wait(futures);
    outputStory.addAll(results.whereType<SDMap>());
  }

  // ignore: unused_element
  bool _usesDirectImageGeneration() {
    return AppEnv.hasFirebaseConfiguration();
  }

  Future<_GeneratedStoryPackage> _buildStoryWithDirectImages({
    required StoryGenerationDraft draft,
    required List<SDMap> fallbackStory,
    required StoryMode mode,
    required StoryOptions storyOptions,
    required StoryPreview? preview,
    required String generationRequestId,
  }) async {
    final storySeed = _buildStructuredStorySeed(draft);
    if (fallbackStory.isEmpty) {
      return _GeneratedStoryPackage(
        title: draft.title,
        titleImage: '',
        storyPages: fallbackStory,
        draft: draft,
        storySeed: storySeed,
        mode: mode,
        storyOptions: storyOptions,
        preview: preview,
        generationRequestId: generationRequestId,
      );
    }

    var titleImage = '';
    final prefetchedStory = List<SDMap>.generate(
      fallbackStory.length,
      (index) => Map<String, dynamic>.from(fallbackStory[index]),
    );

    try {
      titleImage = await _generateImageSource(
        primaryPrompt: StoryGenerationComposer.buildCoverImagePrompt(
          draft: draft,
        ),
        secondaryPrompt: StoryGenerationComposer.buildCoverImagePrompt(
          draft: draft,
        ),
        seed: _buildStructuredPageSeed(storySeed, -1),
        debugKey: 'cover',
      );
    } catch (error) {
      debugPrint('Direct cover image generation failed: $error');
    }

    for (var pageIndex = 0; pageIndex < draft.pages.length; pageIndex += 1) {
      final story = draft.pages[pageIndex].story.trim();
      if (story.isEmpty) {
        continue;
      }

      try {
        final imageSource = await _generateImageSource(
          primaryPrompt: _buildStructuredStoryImagePrompt(
            draft: draft,
            pageIndex: pageIndex,
          ),
          secondaryPrompt: _buildStructuredRetryImagePrompt(
            draft: draft,
            pageIndex: pageIndex,
          ),
          seed: _buildStructuredPageSeed(storySeed, pageIndex),
          debugKey: 'page_$pageIndex',
        );
        prefetchedStory[pageIndex] = {
          'story': story,
          'image': imageSource,
        };
      } catch (error) {
        debugPrint(
            'Direct image generation failed for page $pageIndex: $error');
        throw StateError(_incompleteImageGenerationMessage);
      }
    }

    final missingImagePageIndexes =
        _missingStoryImagePageIndexes(prefetchedStory);
    if (missingImagePageIndexes.isNotEmpty) {
      debugPrint(
        'Story image generation completed with missing images: '
        '$missingImagePageIndexes',
      );
      throw StateError(_incompleteImageGenerationMessage);
    }

    if (titleImage.isEmpty && prefetchedStory.isNotEmpty) {
      final firstImage = prefetchedStory.first['image'];
      if (firstImage is String && firstImage.trim().isNotEmpty) {
        titleImage = firstImage.trim();
      }
    }

    return _GeneratedStoryPackage(
      title: draft.title,
      titleImage: titleImage,
      storyPages: prefetchedStory,
      draft: draft,
      storySeed: storySeed,
      mode: mode,
      storyOptions: storyOptions,
      preview: preview,
      generationRequestId: generationRequestId,
    );
  }

  // ignore: unused_element
  Map<String, Pair<String, String>> _buildStableDirectImagePrompts(
      StoryGenerationDraft draft) {
    return const <String, Pair<String, String>>{};
/*

    final mainCharacter = _answerAt(0, fallback: 'やさしい しゅじんこう');
    final place = _answerAt(1, fallback: 'ふしぎな森');
    final partner = _answerAt(2, fallback: 'たのしい友だち');
    final trait = _answerAt(3, fallback: 'あたたかい気持ち');
    final styleGuide = _buildStoryStyleGuide(
      storyText,
      mainCharacter: mainCharacter,
      place: place,
      partner: partner,
      trait: trait,
    );

    final prompts = <String, Pair<String, String>>{};
    for (final key in orderedKeys) {
      final value = storyText[key];
      if (value is! String || value.trim().isEmpty) {
        continue;
      }

      final positivePrompt = _buildStoryImagePrompt(
        scene: value,
        styleGuide: styleGuide,
      );
      prompts[key] = Pair(positivePrompt, _directImageNegativePrompt);
    }

    return prompts;
*/
  }

  // ignore: unused_element
  Map<String, Pair<String, String>> _buildDirectImagePrompts(SDMap storyText) {
    const orderedKeys = [
      'title',
      'introduction',
      'development',
      'turn',
      'conclusion',
    ];
    const negativePrompt =
        'blurry, low quality, distorted face, extra limbs, cropped, text, watermark, logo';

    final mainCharacter = _answerAt(0, fallback: 'げんきな こどもの しゅじんこう');
    final place = _answerAt(1, fallback: 'ふしぎな そらの にわ');
    final partner = _answerAt(2, fallback: 'ちいさな とりの なかま');
    final trait = _answerAt(3, fallback: 'やさしく げんきで ぼうけんずき');

    final prompts = <String, Pair<String, String>>{};
    for (final key in orderedKeys) {
      final value = storyText[key];
      if (value is! String || value.trim().isEmpty) {
        continue;
      }

      final positivePrompt = [
        '子ども向け絵本のような、あたたかく繊細なイラスト。',
        'たて長構図、明るい色、やさしい光。',
        'すべての場面で同じキャラクターデザインを保つ。',
        '主人公: $mainCharacter。',
        '場所: $place。',
        '仲間: $partner。',
        '雰囲気と性格: $trait。',
        '描く場面: ${value.trim()}',
      ].join(' ');

      prompts[key] = Pair(positivePrompt, negativePrompt);
    }

    return prompts;
  }

  // ignore: unused_element
  Future<SDMap> _generateImageForStoryPage({
    required String story,
    required int pageIndex,
    required int storySeed,
    required String primaryPrompt,
    required String secondaryPrompt,
    required String debugKey,
  }) async {
    final prompts = [
      primaryPrompt,
      secondaryPrompt,
    ];

    for (var attempt = 0; attempt < prompts.length; attempt++) {
      final result = await _apiRepository.getStableDiffusionImageWithRetry(
        prompts[attempt],
        _directImageNegativePrompt,
        seed: storySeed,
        isValid: (res) => _extractImageSource(res) != null,
        invalidResultError: (res) => StateError(
            'Image generation response was missing image data: $res'),
      );

      final page = await result.when(
        success: (res) async {
          final imageSource = _extractImageSource(res);
          if (imageSource != null) {
            return {
              'story': story,
              'image': imageSource,
            };
          }
          return null;
        },
        failure: (error) async {
          debugPrint(
            'Direct image generation failed for $debugKey on attempt ${attempt + 1}: $error',
          );
          return null;
        },
      );

      if (page != null) {
        return page;
      }
    }

    return {
      'story': story,
      'image': null,
    };
  }

  Future<String> _generateImageSource({
    required String primaryPrompt,
    required String secondaryPrompt,
    required int seed,
    required String debugKey,
  }) async {
    final prompts = [
      primaryPrompt,
      secondaryPrompt,
    ];

    for (var attempt = 0; attempt < prompts.length; attempt += 1) {
      final result = await _apiRepository.getStableDiffusionImageWithRetry(
        prompts[attempt],
        _directImageNegativePrompt,
        seed: seed,
        isValid: (res) => _extractImageSource(res) != null,
        invalidResultError: (res) => StateError(
          'Image generation response was missing image data: $res',
        ),
      );

      final imageSource = await result.when(
        success: (res) async => _extractImageSource(res),
        failure: (error) async {
          debugPrint(
            'Direct image generation failed for $debugKey on attempt ${attempt + 1}: $error',
          );
          return null;
        },
      );

      if (imageSource != null) {
        return imageSource;
      }
    }

    throw StateError('Image generation failed for $debugKey.');
  }

  String? _extractImageSource(SDMap response) {
    final imageUrl = response['imageUrl'];
    if (imageUrl is String && imageUrl.trim().isNotEmpty) {
      return imageUrl.trim();
    }

    final base64 = response['base64'];
    if (base64 is String && base64.trim().isNotEmpty) {
      return base64.trim();
    }

    return null;
  }

  static List<int> _missingStoryImagePageIndexes(List<SDMap> storyPages) {
    final missing = <int>[];
    for (var index = 0; index < storyPages.length; index += 1) {
      final image = storyPages[index]['image'];
      if (image is! String || image.trim().isEmpty) {
        missing.add(index);
      }
    }
    return missing;
  }

  // ignore: unused_element
  String _buildRetryImagePrompt({
    required String story,
    required String styleGuide,
  }) {
    return [
      _directImageStylePrompt,
      styleGuide,
      'Scene from a Japanese children\'s story: ${_trimPromptText(story)}.',
      'Keep exactly the same illustration genre, brush texture, palette, face design, costume details, and proportions as the other pages in this story.',
      'One clear subject, simple background, soft pastel palette.',
    ].join(' ');
  }

  // ignore: unused_element
  String _buildStoryImagePrompt({
    required String scene,
    required String styleGuide,
  }) {
    final parts = <String>[
      _directImageStylePrompt,
      styleGuide,
      'Scene: ${_trimPromptText(scene)}.',
      'Keep the same characters, costume details, face shape, palette, and picture-book genre as the other pages in this story.',
      'Warm Japanese picture-book composition, centered subject, clear silhouette.',
    ];
    return parts.join(' ');
  }

  // ignore: unused_element
  String _buildStoryStyleGuide(
    SDMap storyText, {
    String? mainCharacter,
    String? place,
    String? partner,
    String? trait,
  }) {
    final normalizedTitle = _trimPromptText(
      storyText['title']?.toString() ?? '',
      maxLength: 120,
    );
    final normalizedMainCharacter =
        _trimPromptText(mainCharacter ?? _answerAt(0, fallback: 'やさしい しゅじんこう'));
    final normalizedPlace =
        _trimPromptText(place ?? _answerAt(1, fallback: 'ふしぎな森'));
    final normalizedPartner =
        _trimPromptText(partner ?? _answerAt(2, fallback: 'たのしい友だち'));
    final normalizedTrait =
        _trimPromptText(trait ?? _answerAt(3, fallback: 'あたたかい気持ち'));

    return [
      'Series art bible: hand-painted Japanese children picture book, gouache watercolor texture, pastel palette, rounded anatomy, gentle linework, cozy lighting, vertical portrait layout.',
      'Keep the same art genre, brush texture, line weight, color palette, facial design, eye shape, body proportions, and costume details on every page.',
      'Main character design: $normalizedMainCharacter.',
      'World setting: $normalizedPlace.',
      if (normalizedPartner.isNotEmpty)
        'Supporting character design: $normalizedPartner.',
      if (normalizedTrait.isNotEmpty)
        'Overall mood and personality: $normalizedTrait.',
      if (normalizedTitle.isNotEmpty) 'Story title motif: $normalizedTitle.',
    ].join(' ');
  }

  // ignore: unused_element
  int _buildStorySeed(SDMap storyText) {
    final seedSource = [
      storyText['title']?.toString() ?? '',
      storyText['introduction']?.toString() ?? '',
      storyText['development']?.toString() ?? '',
      _answerAt(0, fallback: ''),
      _answerAt(1, fallback: ''),
      _answerAt(2, fallback: ''),
      _answerAt(3, fallback: ''),
    ].join('|');

    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }

    final normalized = hash & 0x7fffffff;
    return normalized == 0 ? 1 : normalized;
  }

  String _buildStructuredRetryImagePrompt({
    required StoryGenerationDraft draft,
    required int pageIndex,
  }) {
    return StoryGenerationComposer.buildRetryImagePrompt(
      draft: draft,
      pageIndex: pageIndex,
    );
  }

  String _buildStructuredStoryImagePrompt({
    required StoryGenerationDraft draft,
    required int pageIndex,
  }) {
    return StoryGenerationComposer.buildPageImagePrompt(
      draft: draft,
      pageIndex: pageIndex,
    );
  }

  int _buildStructuredStorySeed(StoryGenerationDraft draft) {
    return StoryGenerationComposer.buildStorySeed(
      draft: draft,
      fallbackAnswers: _userAnswers(),
    );
  }

  int _buildStructuredPageSeed(int storySeed, int pageIndex) {
    return StoryGenerationComposer.buildPageSeed(
      storySeed: storySeed,
      pageIndex: pageIndex,
    );
  }

  String _trimPromptText(String value, {int maxLength = 180}) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }

  List<String> _userAnswers() {
    return _messages.reversed
        .whereType<types.TextMessage>()
        .where((message) => message.author.id == _user.id)
        .map((message) => message.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
  }

  StoryGenerationDraft _draftFromStoryResponse(
    SDMap storyText, {
    StoryMode mode = StoryMode.mini,
    int? pageCount,
  }) {
    return StoryGenerationDraft.fromResponse(
      storyText,
      fallbackAnswers: _userAnswers(),
      mode: mode,
      pageCount: pageCount,
    );
  }

  _GeneratedStoryPackage _buildLocalStoryPackage({
    required String chatLogs,
    required StoryMode mode,
    required StoryOptions storyOptions,
    required StoryPreview? preview,
    required String generationRequestId,
  }) {
    final draft = StoryGenerationComposer.fallbackDraft(
      answers: _userAnswers(),
      mode: mode,
    );
    final storySeed = StoryGenerationComposer.buildStorySeed(
      draft: draft,
      fallbackAnswers: _userAnswers(),
    );
    return _GeneratedStoryPackage(
      title: draft.title,
      titleImage: '',
      storyPages: StoryGenerationComposer.storyPagesFromDraft(draft),
      draft: draft,
      storySeed: storySeed,
      mode: mode,
      storyOptions: storyOptions,
      preview: preview,
      generationRequestId: generationRequestId,
    );
  }

  String _answerAt(int index, {required String fallback}) {
    final answers = _userAnswers();
    if (index >= 0 && index < answers.length) {
      return answers[index];
    }
    return fallback;
  }

  bool _hasClaudeAccess() {
    return AppEnv.hasFirebaseConfiguration();
  }

  bool _hasStoryGenerationAccess() {
    return AppEnv.hasFirebaseConfiguration();
  }

  Future<PurchaseEntitlements?> _loadStoryCreationEntitlements(
      String uid) async {
    try {
      return await _purchaseRepository.loadEntitlements(uid);
    } catch (error) {
      debugPrint('Failed to load story creation entitlements: $error');
      return null;
    }
  }

  Future<StoryCreationStatus?> _loadStoryCreationStatus() async {
    final currentUser = _currentUserReader();
    if (currentUser == null || currentUser.isGuest) {
      return null;
    }
    final result = await _apiRepository.getStoryCreationStatus();
    return result.when(
      success: (json) => StoryCreationStatus.fromJson(json),
      failure: (_) => null,
    );
  }

  StoryPreview _buildLocalStoryPreview({
    required StoryMode mode,
    required StoryOptions storyOptions,
  }) {
    return localStoryPreviewForTesting(
      answers: _userAnswers(),
      mode: mode,
      storyOptions: storyOptions,
    );
  }

  @visibleForTesting
  static StoryPreview localStoryPreviewForTesting({
    required List<String> answers,
    required StoryMode mode,
    required StoryOptions storyOptions,
  }) {
    final protagonist = answers.isNotEmpty ? answers[0] : 'やさしい ぼうけんか';
    final place = answers.length > 1 ? answers[1] : 'ひみつの もり';
    final companion = answers.length > 2 ? answers[2] : 'たよりに なる なかま';
    final strength = answers.length > 3 ? answers[3] : 'あきらめない気持ち';
    final pagePlan = _localPreviewPagePlan(
      mode: mode,
      protagonist: protagonist,
      place: place,
      companion: companion,
      strength: strength,
      storyOptions: storyOptions,
    );
    return StoryPreview(
      title: '$protagonistの ぼうけん',
      summary: '$protagonist が $place で $companion と出会い、'
          'ふしぎな困りごとを解決するおはなしです。',
      pagePlan: pagePlan,
      mode: mode,
      pageCount: mode.pageCount,
      coinCost: mode.coinCost,
      storyOptions: storyOptions,
    );
  }

  static List<String> _localPreviewPagePlan({
    required StoryMode mode,
    required String protagonist,
    required String place,
    required String companion,
    required String strength,
    required StoryOptions storyOptions,
  }) {
    final ending = switch (storyOptions.endingStyle) {
      StoryEndingStyle.happy => 'みんなでよろこび、明るいごほうびを受け取る。',
      StoryEndingStyle.gentle => '安心した気持ちで帰り、静かな余韻を味わう。',
      StoryEndingStyle.funnyTwist => '思わず笑ってしまう小さなオチを見つける。',
    };
    final plans = switch (mode) {
      StoryMode.mini => [
          '$protagonist が $place で 小さな願いを見つける。',
          '$companion が現れ、ふたりで最初の手がかりを試す。',
          '$strength を活かして困りごとの原因に気づく。',
          '$companion と力を合わせて解決し、$ending',
        ],
      StoryMode.standard => [
          '$protagonist が $place で 小さな願いを見つける。',
          '$companion が助けを求め、ふしぎな道がひらく。',
          'ふたりは光る目印を追って、知らない場所へ進む。',
          '$protagonist が急ぎすぎて、たいせつな手がかりを見失う。',
          '$strength を思い出し、別のやり方で手がかりを探す。',
          '大きな障害が道をふさぎ、進むか戻るかを選ぶ。',
          '$protagonist と $companion が力を合わせ、問題の中心を解く。',
          '$place に静けさが戻り、$ending',
        ],
      StoryMode.premium => [
          '$protagonist が $place でいつもの時間を過ごしている。',
          '小さな願いがかなわず、少しだけ困った気持ちになる。',
          '足もとにふしぎな印が現れ、遠くから小さな音が聞こえる。',
          '$protagonist は音を追って、知らない道へ一歩ふみ出す。',
          '$companion が現れ、道具や合図の使い方を教える。',
          '最初の門で失敗し、ふたりは別の入り口を探す。',
          '$strength が役に立ち、小さな通り道を見つける。',
          '奥でさらに大きな問題が起き、$place 全体がざわつく。',
          '$protagonist は自分だけ進むか、$companion を待つかを選ぶ。',
          '選んだ行動が道を変え、いちばん大きなピンチに向き合う。',
          'ふたりの工夫で問題がほどけ、なくしたものが戻ってくる。',
          '$protagonist は安心して帰り、眠る前に今日の冒険を思い出す。',
        ],
    };
    return List<String>.unmodifiable(plans.take(mode.pageCount));
  }

  void _showLoginRequiredDialog(BuildContext context) {
    DialogCore.cupertinoAlertDialog(
      context,
      'おはなしをつくるには、保護者がログインしてください。',
      'ログインが必要です',
      () {
        context.pop();
        context.push('/login');
      },
    );
  }

  void _showStoreRequiredDialog(BuildContext context) {
    DialogCore.cupertinoAlertDialog(
      context,
      'おはなしをつくるには、選んだ長さに応じたコインまたはSilverの月間枠が必要です。Silverは毎月6コイン分まで使えます。',
      'コインが必要です',
      () {
        context.pop();
        context.push('/parent/store');
      },
    );
  }

  @visibleForTesting
  static StoryCreationAccessState storyCreationAccessForTesting({
    required LocalSessionUser? currentUser,
    required PurchaseEntitlements entitlements,
    int coinCost = 1,
  }) {
    if (currentUser == null || currentUser.isGuest) {
      return StoryCreationAccessState.loginRequired;
    }
    if (entitlements.isSubscriptionActive || entitlements.coins >= coinCost) {
      return StoryCreationAccessState.allowed;
    }
    return StoryCreationAccessState.purchaseRequired;
  }

  String _buildRotatingExample() {
    final userAnswerCount = _messages
        .whereType<types.TextMessage>()
        .where((message) => message.author.id == _user.id)
        .length;

    switch (userAnswerCount) {
      case 0:
        return _nextExampleForStage(0, const [
          'うさぎ',
          'くま',
          'こねこ',
          'きつね',
          'ペンギン',
        ]);
      case 1:
        return _nextExampleForStage(1, const [
          'にじのもり',
          'おほしさまのうみ',
          'ふわふわぐものくに',
          'ひかるきのこのもり',
          'おかしのおしろ',
        ]);
      case 2:
        return _nextExampleForStage(2, const [
          'やさしいこぐま',
          'げんきなことり',
          'ちいさなドラゴン',
          'おしゃべりなどんぐり',
          'ふしぎなロボット',
        ]);
      case 3:
        return _nextExampleForStage(3, const [
          'やさしくて ちょっと こわがり',
          'げんきいっぱいで ゆうきがある',
          'のんびりしていて ものしり',
          'いたずらずきだけど やさしい',
          'しずかだけど がんばりや',
        ]);
      default:
        return _nextExampleForStage(4, const [
          'ひみつのたからをさがしたい',
          'まいごのほしをおうちにかえしたい',
          'おともだちとなかなおりしたい',
          'こわいよるをのりこえたい',
          'ふしぎなドアのむこうをみにいきたい',
        ]);
    }
  }

  String _nextExampleForStage(int stage, List<String> options) {
    final current = _exampleCursorByStage[stage];
    final startOffset = (_exampleSeed + stage) % options.length;
    final nextIndex = current ?? startOffset;
    _exampleCursorByStage[stage] = nextIndex + 1;
    return options[nextIndex % options.length];
  }

  String _latestAssistantQuestion() {
    final cached = _lastQuestion.trim();
    if (cached.isNotEmpty) {
      return cached;
    }

    for (final message in _messages) {
      if (message is types.TextMessage && message.author.id == _apapane.id) {
        final text = message.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }

  Future<String> _generateAdaptiveExample({
    required String questionText,
    required String fallback,
  }) async {
    final userAnswers = _messages.reversed
        .whereType<types.TextMessage>()
        .where((message) => message.author.id == _user.id)
        .map((message) => message.text.trim())
        .where((text) => text.isNotEmpty)
        .take(4)
        .toList()
        .reversed
        .toList();

    final prompt = [
      'Create one short example reply in Japanese for a child using a story app.',
      'Latest assistant question:',
      questionText,
      if (userAnswers.isNotEmpty) 'Previous child answers:',
      if (userAnswers.isNotEmpty) ...userAnswers.map((answer) => '- $answer'),
      'Requirements:',
      '- Output exactly one example reply only.',
      '- Keep it playful, specific, and easy for a child to tap.',
      '- Use simple Japanese.',
      '- Avoid repeating this fallback example word-for-word: $fallback',
      '- Vary the wording and details naturally.',
      '- No quotes, no bullets, no explanations.',
    ].join('\n');

    const systemPrompt =
        'You write one short child-safe Japanese example answer for a storytelling app. Output only the example text.';

    final result = await _apiRepository.getClaudeResponse(
      prompt,
      systemPrompt,
      'conversation',
    );

    return result.when(
      success: (res) => _sanitizeExampleResponse(res, fallback),
      failure: (_) => fallback,
    );
  }

  String _sanitizeExampleResponse(String raw, String fallback) {
    final firstLine = raw
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');

    if (firstLine.isEmpty) {
      return fallback;
    }

    final cleaned = firstLine
        .replaceAll(RegExp(r'^[\s"\.\-\d\)\(]+'), '')
        .replaceAll(RegExp(r'[\s"]+$'), '')
        .trim();

    if (cleaned.isEmpty) {
      return fallback;
    }

    return cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
  }

  // ignore: unused_element
  String _buildLocalExample(String questionText) {
    final normalized = questionText
        .replaceAll('。', '')
        .replaceAll('?', '')
        .replaceAll('？', '')
        .trim();

    if (normalized.contains('しゅじんこう')) {
      return 'うさぎ';
    }
    if (normalized.contains('ばしょ') || normalized.contains('どこ')) {
      return 'にじのもり';
    }
    if (normalized.contains('なかま') || normalized.contains('だれ')) {
      return 'こぐま';
    }
    if (normalized.contains('せいかく')) {
      return 'やさしい';
    }
    if (normalized.contains('どんなこと') || normalized.contains('なに')) {
      return 'ひみつのたからさがし';
    }
    return 'もり';
  }

  static SDMap _storyJsonSchemaForMode(StoryMode mode) => {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'coverScene': {'type': 'string'},
          'characterSheet': {
            'type': 'object',
            'properties': {
              'protagonist': {'type': 'string'},
              'companion': {'type': 'string'},
              'worldDetails': {'type': 'string'},
              'artDirection': {'type': 'string'},
            },
            'required': [
              'protagonist',
              'companion',
              'worldDetails',
              'artDirection',
            ],
          },
          'pages': {
            'type': 'array',
            'minItems': mode.pageCount,
            'maxItems': mode.pageCount,
            'items': {
              'type': 'object',
              'properties': {
                'story': {'type': 'string'},
                'visualFocus': {'type': 'string'},
                'mood': {'type': 'string'},
                'dialogue': {'type': 'string'},
                'visibleCast': {
                  'type': 'array',
                  'minItems': 1,
                  'maxItems': 2,
                  'items': {
                    'type': 'string',
                    'enum': ['protagonist', 'companion'],
                  },
                },
              },
              'required': [
                'story',
                'visualFocus',
                'mood',
                'dialogue',
                'visibleCast',
              ],
            },
          },
        },
        'required': [
          'title',
          'coverScene',
          'characterSheet',
          'pages',
        ],
      };

  @visibleForTesting
  static StoryGenerationDraft storyDraftForTesting(
    SDMap storyText, {
    List<String> fallbackAnswers = const [],
  }) {
    return StoryGenerationDraft.fromResponse(
      storyText,
      fallbackAnswers: fallbackAnswers,
    );
  }

  @visibleForTesting
  static List<SDMap> storyPagesForTesting(
    SDMap storyText, {
    List<String> fallbackAnswers = const [],
  }) {
    final draft = StoryGenerationDraft.fromResponse(
      storyText,
      fallbackAnswers: fallbackAnswers,
    );
    return StoryGenerationComposer.storyPagesFromDraft(draft);
  }

  @visibleForTesting
  static String storyImagePromptForTesting(
    SDMap storyText, {
    required int pageIndex,
    List<String> fallbackAnswers = const [],
  }) {
    final draft = StoryGenerationDraft.fromResponse(
      storyText,
      fallbackAnswers: fallbackAnswers,
    );
    return StoryGenerationComposer.buildPageImagePrompt(
      draft: draft,
      pageIndex: pageIndex,
    );
  }

  @visibleForTesting
  static int storySeedForTesting(
    SDMap storyText, {
    List<String> fallbackAnswers = const [],
  }) {
    final draft = StoryGenerationDraft.fromResponse(
      storyText,
      fallbackAnswers: fallbackAnswers,
    );
    return StoryGenerationComposer.buildStorySeed(
      draft: draft,
      fallbackAnswers: fallbackAnswers,
    );
  }

  @visibleForTesting
  static int pageSeedForTesting(int storySeed, int pageIndex) {
    return StoryGenerationComposer.buildPageSeed(
      storySeed: storySeed,
      pageIndex: pageIndex,
    );
  }

  @visibleForTesting
  static List<int> missingStoryImagePageIndexesForTesting(
    List<SDMap> storyPages,
  ) {
    return _missingStoryImagePageIndexes(storyPages);
  }

  String _fallbackTalk() {
    return 'いいね。つぎは どんなことが 起こるかな？';
  }

  // ignore: unused_element
  List<SDMap> _storyTextToPages(SDMap storyText) {
    final draft = _draftFromStoryResponse(storyText);
    return StoryGenerationComposer.storyPagesFromDraft(draft);
  }

  // ignore: unused_element
  List<SDMap> _makeLocalStory({required String chatLogs}) {
    final draft = StoryGenerationComposer.fallbackDraft(
      answers: _userAnswers(),
    );
    return StoryGenerationComposer.storyPagesFromDraft(draft);
/*
    final answers = _messages.reversed
        .whereType<types.TextMessage>()
        .where((message) => message.author.id == _user.id)
        .map((message) => message.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final mainCharacter = answers.isNotEmpty ? answers[0] : 'そら';
    final place = answers.length > 1 ? answers[1] : 'そらの にわ';
    final partner = answers.length > 2 ? answers[2] : 'ちいさな とりの アパパネ';
    final goal = answers.length > 3 ? answers[3] : 'ひかる おほしさまを さがすこと';

    return [
      {
        'story': '$mainCharacter と $place の ひみつ',
        'image': null,
      },
      {
        'story': '$mainCharacter は $place に やってきて、$goal を めざすことに しました。',
        'image': null,
      },
      {
        'story':
            'その みちの とちゅうで $mainCharacter は $partner に 出会い、いっしょに がんばることに しました。',
        'image': null,
      },
      {
        'story': 'とつぜん むずかしい できごとが 起こりましたが、ふたりは ゆうきと やさしさで のりこえました。',
        'image': null,
      },
      {
        'story':
            'さいごに $mainCharacter は、いちばん たいせつな たからものは みんなと いっしょに すごした じかんだと 気づきました。',
        'image': null,
      },
    ];
*/
  }

  String _errorMessage(Object? error) {
    final message = error?.toString().trim() ?? '';
    if (message.isEmpty) {
      return 'おはなし作りに失敗しました。設定を確認して、もう一度お試しください。';
    }
    return message.replaceFirst('Bad state: ', '');
  }
}
