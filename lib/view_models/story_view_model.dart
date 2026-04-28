import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/enums/confirm_action.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/local/local_firestore.dart';
import 'package:apapane/models/chat_log/chat_log.dart';
import 'package:apapane/models/story/story.dart';
import 'package:apapane/models/story/story_generation_config.dart';
import 'package:apapane/models/story/story_generation_draft.dart';
import 'package:apapane/repositories/api_repository.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class StoryViewModel extends ChangeNotifier {
  static const String _storyImageNegativePrompt =
      'blurry, low quality, distorted face, extra limbs, cropped, text, letters, readable words, subtitles, captions, speech bubbles, signage, logo, watermark, book page with readable writing, frame, photorealistic, 3d render, anime screencap, comic style, sketch, rough lineart, inconsistent art style, inconsistent character design, different outfit, different species';
  static const String _storyImageStylePrompt =
      'Family picture-book illustration, hand-painted gouache watercolor texture, soft pastel colors, rounded shapes, clean outlines, friendly expressions, gentle lighting, portrait orientation, vertical composition for a phone screen, no readable text, no watermark, same illustration genre across every page of the same story.';

  StoryViewModel(this._apiRepository, this._firestoreRepository);

  final ApiRepository _apiRepository;
  final FirestoreRepository _firestoreRepository;

  ConfirmAction confirmAction = ConfirmAction.initialValue;
  ToStoryPageType toStoryPageType = ToStoryPageType.initialValue;
  String _chatLogs = '';
  bool _isVolume = false;
  bool _isVoiceDownloading = false;
  final _player = AudioPlayer();
  final Map<int, Uint8List> _preparedStoryPageImages = {};
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _fallbackImageCache = {};
  final Map<String, Future<Uint8List>> _pendingGeneratedImages = {};
  final Map<int, String> _imageDiagnostics = {};
  static const Duration _imageFetchTimeout = Duration(seconds: 45);
  static const Duration _imageRecoveryTimeout = Duration(seconds: 45);
  bool _isOpeningSavedStory = false;
  List<Map<String, dynamic>> _storyPages = [];
  String _titleText = '';
  String _titleImage = '';
  StoryGenerationDraft? _transientNewStoryDraft;
  int? _transientNewStorySeed;
  StoryMode? _transientStoryMode;
  StoryOptions? _transientStoryOptions;
  StoryPreview? _transientStoryPreview;
  String? _transientGenerationRequestId;

  List<Map<String, dynamic>> get storyPages => _storyPages;
  String get titleText => _titleText;
  bool get isVolume => _isVolume;
  bool get isVoiceDownloading => _isVoiceDownloading;
  bool get isOpeningSavedStory => _isOpeningSavedStory;
  Uint8List? peekStoryPageImage({
    required int pageIndex,
    required String sentence,
    String? imageSource,
  }) {
    final preparedImage = _preparedStoryPageImages[pageIndex];
    if (preparedImage != null && preparedImage.isNotEmpty) {
      return preparedImage;
    }

    final trimmedSource = imageSource?.trim() ?? '';
    if (trimmedSource.isNotEmpty) {
      final cachedImage = _imageCache[trimmedSource];
      if (cachedImage != null && cachedImage.isNotEmpty) {
        return cachedImage;
      }
    }

    final fallbackKey = '$pageIndex::${sentence.trim()}';
    final fallbackImage = _fallbackImageCache[fallbackKey];
    if (fallbackImage != null && fallbackImage.isNotEmpty) {
      return fallbackImage;
    }

    return null;
  }

  String? imageDiagnosticForPage(int pageIndex) {
    final message = _imageDiagnostics[pageIndex]?.trim() ?? '';
    return message.isEmpty ? null : message;
  }

  void _playAudioFromBytes(Uint8List audioBytes) {
    _player.play(BytesSource(audioBytes, mimeType: 'audio/mpeg'));
  }

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  void _startVoiceDownloading() {
    _isVoiceDownloading = true;
    notifyListeners();
  }

  void _endVoiceDownloading() {
    _isVoiceDownloading = false;
    notifyListeners();
  }

  void getTitleTextAndImage({
    required String title,
    required String image,
  }) {
    _titleText = title;
    _titleImage = image;
    notifyListeners();
  }

  void setTransientNewStorySession({
    required StoryGenerationDraft draft,
    required int storySeed,
  }) {
    _transientNewStoryDraft = draft;
    _transientNewStorySeed = storySeed;
  }

  void setTransientStoryMetadata({
    required StoryMode mode,
    required StoryOptions storyOptions,
    required StoryPreview? preview,
    required String generationRequestId,
  }) {
    _transientStoryMode = mode;
    _transientStoryOptions = storyOptions;
    _transientStoryPreview = preview;
    _transientGenerationRequestId = generationRequestId;
  }

  void clearTransientNewStorySession() {
    _transientNewStoryDraft = null;
    _transientNewStorySeed = null;
    _transientStoryMode = null;
    _transientStoryOptions = null;
    _transientStoryPreview = null;
    _transientGenerationRequestId = null;
  }

  void updateStoryMaps({
    required List<Map<String, dynamic>> newStoryMaps,
  }) {
    _preparedStoryPageImages.clear();
    _imageDiagnostics.clear();
    _storyPages = StoryGenerationComposer.normalizeStoredPages(
      rawPages: newStoryMaps,
      titleText: _titleText,
    );
    notifyListeners();
  }

  Future<void> openSavedStory({
    required BuildContext context,
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) async {
    if (_isOpeningSavedStory) {
      return;
    }

    _isOpeningSavedStory = true;
    notifyListeners();

    final overlay = _buildStoryOpeningOverlay();
    Overlay.of(context, rootOverlay: true).insert(overlay);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 16));

      final myStoryMaps = storyDoc['stories'] as List<dynamic>;
      clearTransientNewStorySession();
      getTitleTextAndImage(
        title: storyDoc['titleText'].toString(),
        image: storyDoc['titleImage'].toString(),
      );
      updateStoryMaps(
        newStoryMaps: myStoryMaps.cast<Map<String, dynamic>>(),
      );
      toStoryPageType = ToStoryPageType.memoryStory;
      await prewarmStoryImages(isNew: false);

      if (!context.mounted) {
        return;
      }
      context.push('/story?isNew=false');
    } catch (error) {
      debugPrint('Failed to open saved story: $error');
      await UIHelper.showFlutterToast('おはなしの準備に失敗しました');
    } finally {
      overlay.remove();
      _isOpeningSavedStory = false;
      notifyListeners();
    }
  }

  Future<List<int>> prewarmStoryImages({
    required bool isNew,
    bool requireGeneratedImages = false,
  }) async {
    final failedPageIndexes = <int>{};
    final futures = <Future<void>>[];
    for (var pageIndex = 0; pageIndex < _storyPages.length; pageIndex += 1) {
      final page = _storyPages[pageIndex];
      final sentence = page['story']?.toString().trim() ?? '';
      if (sentence.isEmpty) {
        continue;
      }

      futures.add(
        (requireGeneratedImages
                ? _prefetchRequiredStoryPageImage(
                    pageIndex: pageIndex,
                    isNew: isNew,
                    imageSource: page['image']?.toString(),
                  )
                : _prefetchStoryPageImage(
                    sentence: sentence,
                    pageIndex: pageIndex,
                    isNew: isNew,
                    imageSource: page['image']?.toString(),
                  ))
            .catchError((Object error) {
          failedPageIndexes.add(pageIndex);
          debugPrint('Story image prewarm failed for page $pageIndex: $error');
        }),
      );
    }

    if (futures.isEmpty) {
      return failedPageIndexes.toList(growable: false);
    }

    await Future.wait(futures);

    if (requireGeneratedImages) {
      final sortedFailures = failedPageIndexes.toList(growable: false)..sort();
      return sortedFailures;
    }

    for (var pageIndex = 0; pageIndex < _storyPages.length; pageIndex += 1) {
      final page = _storyPages[pageIndex];
      final sentence = page['story']?.toString().trim() ?? '';
      if (sentence.isEmpty) {
        continue;
      }

      final preparedImage = peekStoryPageImage(
        pageIndex: pageIndex,
        sentence: sentence,
        imageSource: page['image']?.toString(),
      );
      if (preparedImage != null && preparedImage.isNotEmpty) {
        continue;
      }

      final fallbackImage = await buildFallbackStoryImage(
        sentence: sentence,
        pageIndex: pageIndex,
      );
      _preparedStoryPageImages[pageIndex] = fallbackImage;
    }

    final sortedFailures = failedPageIndexes.toList(growable: false)..sort();
    return sortedFailures;
  }

  void updateChatLogs({required String chatLogs}) {
    _chatLogs = chatLogs;
    notifyListeners();
  }

  Future<bool> endButtonPressed({
    required MainViewModel mainViewModel,
  }) async {
    _player.stop();
    try {
      switch (confirmAction) {
        case ConfirmAction.save:
          return await _saveStory(mainViewModel);
        case ConfirmAction.cancel:
        case ConfirmAction.initialValue:
          confirmAction = ConfirmAction.initialValue;
          return false;
      }
    } catch (error) {
      debugPrint('Error in endButtonPressed: $error');
      confirmAction = ConfirmAction.initialValue;
      await UIHelper.showFlutterToast('ストーリーの保存に失敗しました。');
    }
    return false;
  }

  Future<bool> _saveStory(MainViewModel mainViewModel) async {
    if (!mainViewModel.hasSyncedAccount) {
      await UIHelper.showFlutterToast(
        '端末をまたいでおはなしを保存するには、保護者がログインしてください。',
      );
      confirmAction = ConfirmAction.initialValue;
      return false;
    }

    final currentUserDoc = mainViewModel.currentUserDoc;
    final firestoreUser = mainViewModel.firestoreUser;
    final activeUid = currentUserDoc.id;
    final now = Timestamp.now();
    final id = IDCore.uuidV4();
    var saveTitleImage = _titleImage;
    final saveTitleText = _titleText;
    final saveStoryPages = List<Map<String, dynamic>>.from(_storyPages);
    final newChatLogs = _chatLogs;

    final chatLog = ChatLog(
      chatLog: newChatLogs,
      chatLogId: id,
      createdAt: now,
      uid: activeUid,
      userName: firestoreUser.userName,
      updatedAt: now,
    );

    final chatLogRef = ColRefCore.chatLogsColRef(activeUid).doc(id);
    final chatLogResult = await _firestoreRepository.createDoc(
      chatLogRef,
      chatLog.toJson(),
    );
    var didSaveChatLog = true;
    await chatLogResult.when(
      success: (_) async {},
      failure: (_) async {
        didSaveChatLog = false;
        await UIHelper.showFlutterToast('会話の記録を保存できませんでした。');
      },
    );

    if (!didSaveChatLog) {
      confirmAction = ConfirmAction.initialValue;
      return false;
    }

    final updatedStoryPages = <Map<String, dynamic>>[];
    for (var i = 0; i < saveStoryPages.length; i++) {
      final storyPage = saveStoryPages[i];
      final rawImage = storyPage['image'];
      if (rawImage == null || rawImage.toString().isEmpty) {
        updatedStoryPages.add({...storyPage});
        continue;
      }

      final imageSource = rawImage.toString();
      final storedImagePath = _isRemoteImageUrl(imageSource)
          ? imageSource
          : await _saveImageFromBase64(
              activeUid: activeUid,
              storyId: id,
              base64Image: imageSource,
            );
      final persistedImage =
          storedImagePath.isEmpty ? imageSource : storedImagePath;

      updatedStoryPages.add({
        ...storyPage,
        'image': persistedImage,
      });
      if (i == 0) {
        saveTitleImage = persistedImage;
      }
    }

    final story = Story(
      createdAt: now,
      chatLogRef: chatLogRef,
      isPublic: false,
      stories: updatedStoryPages,
      storyId: id,
      titleImage: saveTitleImage,
      titleText: saveTitleText,
      uid: activeUid,
      userImageURL: firestoreUser.userImageURL,
      userName: firestoreUser.userName,
      updatedAt: now,
    );
    final storyJson = story.toJson();
    final transientMode = _transientStoryMode;
    final transientOptions = _transientStoryOptions;
    final transientPreview = _transientStoryPreview;
    if (transientMode != null) {
      storyJson.addAll({
        'schemaVersion': 2,
        'mode': transientMode.key,
        'pageCount': transientMode.pageCount,
        'coinCost': transientMode.coinCost,
        if (transientOptions != null) 'storyOptions': transientOptions.toJson(),
        if (transientPreview != null) ...{
          'previewSummary': transientPreview.summary,
          'pagePlan': transientPreview.pagePlan,
        },
        if (_transientGenerationRequestId?.isNotEmpty == true)
          'generationRequestId': _transientGenerationRequestId,
      });
    }

    final saveStoryResult = await _firestoreRepository.createDoc(
      ColRefCore.storiesColRef(activeUid, id).doc(id),
      storyJson,
    );
    var didSaveStory = true;
    await saveStoryResult.when(
      success: (_) async {
        await UIHelper.showFlutterToast('ストーリーを保存しました。');
      },
      failure: (_) async {
        didSaveStory = false;
        await UIHelper.showFlutterToast('ストーリーの保存に失敗しました。');
      },
    );

    if (!didSaveStory) {
      confirmAction = ConfirmAction.initialValue;
      return false;
    }

    _titleImage = '';
    _titleText = '';
    _chatLogs = '';
    _storyPages = [];
    clearTransientNewStorySession();
    confirmAction = ConfirmAction.initialValue;
    notifyListeners();
    return true;
  }

  void onPageChanged() {
    _player.stop();
    _isVolume = false;
    notifyListeners();
  }

  void onVolumePressed({required String sentence}) async {
    _isVolume = !_isVolume;
    if (!_isVolume) {
      _player.stop();
    } else {
      try {
        _startVoiceDownloading();
        final result = await _apiRepository.getVoiceAudioBytes(sentence);
        result.when(
          success: (audioBytes) {
            if (audioBytes != null && audioBytes.isNotEmpty) {
              _playAudioFromBytes(audioBytes);
            }
          },
          failure: (_) async {
            await UIHelper.showFlutterToast('音声の読み上げに失敗しました。');
          },
        );
      } finally {
        _endVoiceDownloading();
      }
    }
    notifyListeners();
  }

  Future<String> _uploadImageToLocalStore({
    required String activeUid,
    required String storyId,
    required Uint8List imageData,
    required String fileName,
  }) async {
    String storedPath = '';
    final path = 'users/$activeUid/$storyId/$fileName';
    final result = await _firestoreRepository.uploadImage(path, imageData);
    result.when(
      success: (res) => storedPath = res,
      failure: (_) async {
        await UIHelper.showFlutterToast('画像の保存に失敗しました。');
      },
    );
    return storedPath;
  }

  Future<String> _saveImageFromBase64({
    required String activeUid,
    required String storyId,
    required String base64Image,
  }) async {
    final imageData = base64Decode(base64.normalize(base64Image));
    final fileName = IDCore.jpgFileName();
    return _uploadImageToLocalStore(
      activeUid: activeUid,
      storyId: storyId,
      imageData: imageData,
      fileName: fileName,
    );
  }

  Future<Uint8List?> fetchImageData(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (_imageCache.containsKey(imageUrl)) {
      return _imageCache[imageUrl];
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      final response =
          await http.get(Uri.parse(imageUrl)).timeout(_imageFetchTimeout);
      if (response.statusCode != 200) {
        throw Exception('画像を読み込めませんでした。');
      }
      final imageData = response.bodyBytes;
      _imageCache[imageUrl] = imageData;
      return imageData;
    }

    final file = File(imageUrl);
    if (!await file.exists()) {
      return null;
    }
    final imageData = await file.readAsBytes();
    _imageCache[imageUrl] = imageData;
    return imageData;
  }

  Future<Uint8List> resolveStoryPageImage({
    required String sentence,
    required int pageIndex,
    required bool isNew,
    String? imageSource,
  }) async {
    final preparedImage = _preparedStoryPageImages[pageIndex];
    if (preparedImage != null && preparedImage.isNotEmpty) {
      _clearImageDiagnostic(pageIndex);
      return preparedImage;
    }

    final trimmedSource = imageSource?.trim() ?? '';

    if (isNew &&
        trimmedSource.isNotEmpty &&
        !_isRemoteImageUrl(trimmedSource)) {
      if (trimmedSource.isNotEmpty) {
        try {
          final imageBytes = base64Decode(base64.normalize(trimmedSource));
          _imageCache[trimmedSource] = imageBytes;
          _preparedStoryPageImages[pageIndex] = imageBytes;
          _clearImageDiagnostic(pageIndex);
          return imageBytes;
        } catch (error) {
          debugPrint('Failed to decode generated image: $error');
        }
      }
    }

    try {
      final imageData = await fetchImageData(trimmedSource);
      if (imageData != null && imageData.isNotEmpty) {
        _preparedStoryPageImages[pageIndex] = imageData;
        _clearImageDiagnostic(pageIndex);
        return imageData;
      }
    } catch (error) {
      debugPrint('Failed to load stored story image: $error');
    }

    final pendingKey = '$pageIndex::${sentence.trim()}';
    final pending = _pendingGeneratedImages[pendingKey];
    if (pending != null) {
      _clearImageDiagnostic(pageIndex);
      return pending;
    }

    final future = _recoverMissingGeneratedImage(
      sentence: sentence,
      pageIndex: pageIndex,
      isNew: isNew,
    ).timeout(
      _imageRecoveryTimeout,
      onTimeout: () {
        _setImageDiagnostic(pageIndex, '画像生成が時間切れになりました。');
        return buildFallbackStoryImage(
          sentence: sentence,
          pageIndex: pageIndex,
        );
      },
    );
    _pendingGeneratedImages[pendingKey] = future;
    try {
      _clearImageDiagnostic(pageIndex);
      return await future;
    } finally {
      _pendingGeneratedImages.remove(pendingKey);
    }
  }

  Future<void> _prefetchStoryPageImage({
    required String sentence,
    required int pageIndex,
    required bool isNew,
    String? imageSource,
  }) async {
    try {
      await resolveStoryPageImage(
        sentence: sentence,
        pageIndex: pageIndex,
        isNew: isNew,
        imageSource: imageSource,
      );
    } catch (error) {
      debugPrint('Story image prewarm failed for page $pageIndex: $error');
    }
  }

  Future<void> _prefetchRequiredStoryPageImage({
    required int pageIndex,
    required bool isNew,
    String? imageSource,
  }) async {
    final imageData = await _resolveRequiredGeneratedImage(
      pageIndex: pageIndex,
      isNew: isNew,
      imageSource: imageSource,
    );
    _preparedStoryPageImages[pageIndex] = imageData;
  }

  Future<Uint8List> _resolveRequiredGeneratedImage({
    required int pageIndex,
    required bool isNew,
    String? imageSource,
  }) async {
    final trimmedSource = imageSource?.trim() ?? '';
    if (trimmedSource.isEmpty) {
      throw StateError('Generated image source is missing.');
    }

    if (isNew && !_isRemoteImageUrl(trimmedSource)) {
      final imageBytes = base64Decode(base64.normalize(trimmedSource));
      if (imageBytes.isEmpty) {
        throw StateError('Generated image bytes are empty.');
      }
      _imageCache[trimmedSource] = imageBytes;
      _clearImageDiagnostic(pageIndex, notify: false);
      return imageBytes;
    }

    final imageData = await fetchImageData(trimmedSource);
    if (imageData == null || imageData.isEmpty) {
      throw StateError('Generated image source did not return image bytes.');
    }

    _clearImageDiagnostic(pageIndex, notify: false);
    return imageData;
  }

  Future<Uint8List> _recoverMissingGeneratedImage({
    required String sentence,
    required int pageIndex,
    required bool isNew,
  }) async {
    final prompt = _buildRecoveryPrompt(
      titleText: _titleText,
      sentence: sentence,
      pageIndex: pageIndex,
      newStoryDraft: isNew ? _transientNewStoryDraft : null,
    );
    final result = await _apiRepository.getStableDiffusionImageWithRetry(
      prompt,
      _storyImageNegativePrompt,
      seed: _buildRecoverySeed(
        pageIndex: pageIndex,
        isNew: isNew,
      ),
    );

    return result.when(
      success: (res) async {
        final imageSource = _extractImageSource(res);
        if (imageSource == null) {
          _setImageDiagnostic(pageIndex, '画像データが返りませんでした。');
          final fallbackImage = await buildFallbackStoryImage(
            sentence: sentence,
            pageIndex: pageIndex,
          );
          _preparedStoryPageImages[pageIndex] = fallbackImage;
          return fallbackImage;
        }

        try {
          final imageBytes = await _resolveGeneratedImageBytes(imageSource);
          _cacheGeneratedStoryImage(
            pageIndex: pageIndex,
            imageSource: imageSource,
            imageBytes: imageBytes,
          );
          _clearImageDiagnostic(pageIndex);
          return imageBytes;
        } catch (error) {
          debugPrint('Failed to decode recovered image: $error');
          _setImageDiagnostic(pageIndex, _diagnosticFromError(error));
          final fallbackImage = await buildFallbackStoryImage(
            sentence: sentence,
            pageIndex: pageIndex,
          );
          _preparedStoryPageImages[pageIndex] = fallbackImage;
          return fallbackImage;
        }
      },
      failure: (error) async {
        debugPrint('Failed to recover story image: $error');
        _setImageDiagnostic(pageIndex, _diagnosticFromError(error));
        final fallbackImage = await buildFallbackStoryImage(
          sentence: sentence,
          pageIndex: pageIndex,
        );
        _preparedStoryPageImages[pageIndex] = fallbackImage;
        return fallbackImage;
      },
    );
  }

  void _cacheGeneratedStoryImage({
    required int pageIndex,
    required String imageSource,
    required Uint8List imageBytes,
  }) {
    if (pageIndex < 0 || pageIndex >= _storyPages.length) {
      return;
    }

    _storyPages[pageIndex] = {
      ..._storyPages[pageIndex],
      'image': imageSource,
    };
    _preparedStoryPageImages[pageIndex] = imageBytes;
    _imageCache[imageSource] = imageBytes;
    _clearImageDiagnostic(pageIndex, notify: false);

    if (pageIndex == 0) {
      _titleImage = imageSource;
    }

    notifyListeners();
  }

  void _setImageDiagnostic(int pageIndex, String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (_imageDiagnostics[pageIndex] == trimmed) {
      return;
    }
    _imageDiagnostics[pageIndex] = trimmed;
    notifyListeners();
  }

  void _clearImageDiagnostic(int pageIndex, {bool notify = true}) {
    if (_imageDiagnostics.remove(pageIndex) != null && notify) {
      notifyListeners();
    }
  }

  String _diagnosticFromError(Object? error) {
    final raw = error?.toString().trim() ?? '';
    final lower = raw.toLowerCase();
    if (lower.contains('resource-exhausted')) {
      return '画像生成の上限に達しました。1分ほど待ってもう一度お試しください。';
    }
    if (lower.contains('unauthenticated')) {
      return '画像生成の認証に失敗しました。';
    }
    if (lower.contains('permission-denied') ||
        lower.contains('forbidden') ||
        lower.contains('app check') ||
        lower.contains('appcheck')) {
      return 'Firebase の保護設定で画像生成が止められました。';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return '画像生成が時間切れになりました。';
    }
    if (lower.contains('did not return image data')) {
      return '画像データが返りませんでした。';
    }
    if (lower.contains('failed-precondition')) {
      return '画像生成の事前条件で失敗しました。';
    }
    return '画像生成に失敗しました。';
  }

  int _buildRecoverySeed({
    required int pageIndex,
    required bool isNew,
  }) {
    if (isNew && _transientNewStorySeed != null) {
      return StoryGenerationComposer.buildPageSeed(
        storySeed: _transientNewStorySeed!,
        pageIndex: pageIndex,
      );
    }
    return _storyPageSeed(pageIndex);
  }

  static String _buildRecoveryPrompt({
    required String titleText,
    required String sentence,
    required int pageIndex,
    StoryGenerationDraft? newStoryDraft,
  }) {
    if (newStoryDraft != null &&
        pageIndex >= 0 &&
        pageIndex < newStoryDraft.pages.length) {
      return StoryGenerationComposer.buildRetryImagePrompt(
        draft: newStoryDraft,
        pageIndex: pageIndex,
      );
    }
    return _defaultRecoveryPrompt(
      titleText: titleText,
      sentence: sentence,
    );
  }

  static String _defaultRecoveryPrompt({
    required String titleText,
    required String sentence,
  }) {
    final normalizedSentence = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedTitle = titleText.replaceAll(RegExp(r'\s+'), ' ').trim();

    final parts = <String>[
      _storyImageStylePrompt,
      if (normalizedTitle.isNotEmpty)
        'Story title motif: ${_truncatePromptTextStatic(normalizedTitle)}.',
      'Scene from a Japanese children\'s story: ${_truncatePromptTextStatic(normalizedSentence)}.',
      'Keep the same picture-book genre, brush texture, color palette, face design, body proportions, and costume details as the other pages in this story.',
      'One clear subject, simple background, soft pastel palette.',
      'No readable text anywhere in the illustration. No letters, subtitles, captions, speech bubbles, signs, logos, or watermarks.',
    ];

    return parts.join(' ');
  }

  int _storyPageSeed(int pageIndex) {
    final baseSeedSource = [
      _titleText,
      ..._storyPages
          .map((page) => page['story']?.toString().trim() ?? '')
          .where((story) => story.isNotEmpty),
    ].join('|');

    var hash = 17;
    for (final codeUnit in baseSeedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }

    final normalizedStorySeed = (hash & 0x7fffffff);
    final storySeed = normalizedStorySeed == 0 ? 1 : normalizedStorySeed;
    final normalizedPageSeed =
        (storySeed + ((pageIndex + 1) * 7919)) & 0x7fffffff;
    return normalizedPageSeed == 0 ? pageIndex + 1 : normalizedPageSeed;
  }

  String? _extractImageSource(Map<String, dynamic> response) {
    final imageUrl = response['imageUrl'];
    if (imageUrl is String && imageUrl.trim().isNotEmpty) {
      return imageUrl.trim();
    }

    final base64Image = response['base64'];
    if (base64Image is String && base64Image.trim().isNotEmpty) {
      return base64Image.trim();
    }

    return null;
  }

  Future<Uint8List> _resolveGeneratedImageBytes(String imageSource) async {
    if (_isRemoteImageUrl(imageSource)) {
      final imageData = await fetchImageData(imageSource);
      if (imageData == null || imageData.isEmpty) {
        throw StateError('Generated image URL did not return image bytes.');
      }
      return imageData;
    }

    final normalizedBase64 = base64.normalize(imageSource);
    return base64Decode(normalizedBase64);
  }

  bool _isRemoteImageUrl(String imageSource) {
    return imageSource.startsWith('http://') ||
        imageSource.startsWith('https://');
  }

  static String _truncatePromptTextStatic(String value, {int maxLength = 180}) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }

  @visibleForTesting
  static String recoveryPromptForTesting({
    required String titleText,
    required String sentence,
    required int pageIndex,
    StoryGenerationDraft? newStoryDraft,
  }) {
    return _buildRecoveryPrompt(
      titleText: titleText,
      sentence: sentence,
      pageIndex: pageIndex,
      newStoryDraft: newStoryDraft,
    );
  }

  Future<Uint8List> buildFallbackStoryImage({
    required String sentence,
    required int pageIndex,
  }) async {
    final normalizedSentence = sentence.trim();
    final cacheKey = '$pageIndex::$normalizedSentence';
    final cachedImage = _fallbackImageCache[cacheKey];
    if (cachedImage != null) {
      return cachedImage;
    }

    const width = 1080.0;
    const height = 1920.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const rect = Rect.fromLTWH(0, 0, width, height);
    final colors = _fallbackPalette[
        normalizedSentence.hashCode.abs() % _fallbackPalette.length];

    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(width, height),
        colors,
      );
    canvas.drawRect(rect, backgroundPaint);

    final glowPaint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawCircle(
      const Offset(170, 220),
      140,
      glowPaint,
    );
    canvas.drawCircle(
      const Offset(864, 360),
      180,
      glowPaint,
    );
    canvas.drawCircle(
      const Offset(512, 952.32),
      220,
      glowPaint..color = Colors.white.withValues(alpha: 0.08),
    );

    final badgeRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(72, 88, 320, 74),
      const Radius.circular(36),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    final badgePainter = TextPainter(
      text: const TextSpan(
        text: 'ものがたりのイメージ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);
    badgePainter.paint(canvas, const Offset(108, 106));

    final emojiPainter = TextPainter(
      text: TextSpan(
        text: _fallbackEmojiForSentence(normalizedSentence),
        style: const TextStyle(fontSize: 250),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    emojiPainter.paint(
      canvas,
      Offset((width - emojiPainter.width) / 2, 290),
    );

    final pagePainter = TextPainter(
      text: TextSpan(
        text: 'PAGE ${pageIndex + 1}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 44,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pagePainter.paint(
      canvas,
      Offset((width - pagePainter.width) / 2, 830),
    );

    final storyCardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(72, 940, 880, 420),
      const Radius.circular(42),
    );
    canvas.drawRRect(
      storyCardRect,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    final storyPainter = TextPainter(
      text: TextSpan(
        text: normalizedSentence.isEmpty
            ? 'おはなしのイメージを準備しています。'
            : normalizedSentence,
        style: const TextStyle(
          color: Color(0xFF3A2C2C),
          fontSize: 54,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 4,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 224);
    storyPainter.paint(canvas, const Offset(112, 1016));

    final footerPainter = TextPainter(
      text: TextSpan(
        text: 'AI画像が準備できないときは、このページ用のイラストを表示します。',
        style: TextStyle(
          color: const Color(0xFF5D4C4C).withValues(alpha: 0.82),
          fontSize: 30,
          height: 1.4,
        ),
      ),
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 224);
    footerPainter.paint(canvas, const Offset(112, 1260));

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
    _fallbackImageCache[cacheKey] = bytes;
    _preparedStoryPageImages[pageIndex] = bytes;
    return bytes;
  }

  static const List<List<Color>> _fallbackPalette = [
    [Color(0xFFFFD5C2), Color(0xFFFFB7B2)],
    [Color(0xFFB7E5DD), Color(0xFF7EC8E3)],
    [Color(0xFFFFE29A), Color(0xFFFFB996)],
    [Color(0xFFC9D9FF), Color(0xFFB7F0D8)],
    [Color(0xFFE3C8FF), Color(0xFFFFC7E8)],
  ];

  String _fallbackEmojiForSentence(String sentence) {
    final lowerCaseSentence = sentence.toLowerCase();
    if (_containsAny(lowerCaseSentence, ['うさぎ', 'rabbit'])) {
      return '🐰';
    }
    if (_containsAny(lowerCaseSentence, ['くま', 'bear'])) {
      return '🐻';
    }
    if (_containsAny(lowerCaseSentence, ['ねこ', 'cat'])) {
      return '🐱';
    }
    if (_containsAny(lowerCaseSentence, ['いぬ', 'dog'])) {
      return '🐶';
    }
    if (_containsAny(lowerCaseSentence, ['りゅう', 'dragon'])) {
      return '🐲';
    }
    if (_containsAny(lowerCaseSentence, ['ほし', 'star', 'そら', 'sky'])) {
      return '🌟';
    }
    if (_containsAny(lowerCaseSentence, ['うみ', 'sea', 'ocean'])) {
      return '🌊';
    }
    if (_containsAny(lowerCaseSentence, ['もり', 'forest', 'woods'])) {
      return '🌳';
    }
    return '✨';
  }

  bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  OverlayEntry _buildStoryOpeningOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    loadingText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '画像を準備しています',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
