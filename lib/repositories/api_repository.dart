import 'dart:typed_data';

import 'package:apapane/models/result/result.dart';
import 'package:apapane/services/api/api_service.dart';
import 'package:apapane/typedefs/result_typedef.dart';

class ApiRepository {
  final ApiService _apiService;

  ApiRepository(this._apiService);

  FutureResult<String> getClaudeResponse(
    String prompt,
    String systemPrompt,
    String apiKeyName, {
    bool jsonOutput = false,
    Map<String, dynamic>? responseJsonSchema,
    String? storyMode,
    Map<String, dynamic>? storyOptions,
    Map<String, dynamic>? preview,
  }) async {
    try {
      final result = await _apiService.callClaude(
        prompt,
        systemPrompt,
        apiKeyName,
        jsonOutput: jsonOutput,
        responseJsonSchema: responseJsonSchema,
        storyMode: storyMode,
        storyOptions: storyOptions,
        preview: preview,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> generateStoryPreview({
    required String chatLogs,
    required String summaryMainSettings,
    required String mode,
    required Map<String, dynamic> storyOptions,
  }) async {
    try {
      final result = await _apiService.generateStoryPreview(
        chatLogs: chatLogs,
        summaryMainSettings: summaryMainSettings,
        mode: mode,
        storyOptions: storyOptions,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> generateImageSpecs({
    required String title,
    required String story,
    required List<Map<String, dynamic>> pages,
    required Map<String, dynamic> characterSheet,
    required String mode,
    Map<String, dynamic>? storyCanon,
    String extraRequirements = '',
  }) async {
    try {
      final result = await _apiService.generateImageSpecs(
        title: title,
        story: story,
        pages: pages,
        characterSheet: characterSheet,
        mode: mode,
        storyCanon: storyCanon,
        extraRequirements: extraRequirements,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> getStoryCreationStatus() async {
    try {
      final result = await _apiService.getStoryCreationStatus();
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> reserveStoryGeneration({
    required String mode,
    required String requestId,
  }) async {
    try {
      final result = await _apiService.reserveStoryGeneration(
        mode: mode,
        requestId: requestId,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> completeStoryGeneration({
    required String requestId,
  }) async {
    try {
      final result = await _apiService.completeStoryGeneration(
        requestId: requestId,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> cancelStoryGeneration({
    required String requestId,
    required String reason,
  }) async {
    try {
      final result = await _apiService.cancelStoryGeneration(
        requestId: requestId,
        reason: reason,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> getStableDiffusionImage(
    String prompt,
    String negativePrompt, {
    int seed = 0,
    Map<String, dynamic>? imagePageSpec,
    Map<String, dynamic>? characterProfile,
    String? pageSummary,
  }) async {
    try {
      final result = await _apiService.callStableDiffusion(
        prompt,
        negativePrompt,
        seed: seed,
        imagePageSpec: imagePageSpec,
        characterProfile: characterProfile,
        pageSummary: pageSummary,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  FutureResult<Map<String, dynamic>> getStableDiffusionImageWithRetry(
    String prompt,
    String negativePrompt, {
    int seed = 0,
    Map<String, dynamic>? imagePageSpec,
    Map<String, dynamic>? characterProfile,
    String? pageSummary,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 2),
    bool Function(Map<String, dynamic> value)? isValid,
    Object Function(Map<String, dynamic> value)? invalidResultError,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      final result = await getStableDiffusionImage(
        prompt,
        negativePrompt,
        seed: seed,
        imagePageSpec: imagePageSpec,
        characterProfile: characterProfile,
        pageSummary: pageSummary,
      );

      var didSucceed = false;
      late Map<String, dynamic> successValue;

      result.when(
        success: (value) {
          didSucceed = true;
          successValue = value;
        },
        failure: (error) {
          lastError = error;
        },
      );

      if (didSucceed) {
        final passesValidation = isValid == null || isValid(successValue);
        if (passesValidation) {
          return Result.success(successValue);
        }
        lastError = invalidResultError?.call(successValue) ??
            StateError('Image generation returned invalid data.');
      }

      final canRetry =
          attempt < maxAttempts && _shouldRetryImageGenerationError(lastError);
      if (!canRetry) {
        break;
      }

      await Future.delayed(_retryDelay(initialDelay, attempt));
    }

    return Result.failure(lastError);
  }

  FutureResult<Uint8List?> getVoiceAudioBytes(String text) async {
    try {
      final result = await _apiService.fetchVoiceAudioBytes(text);
      return Result.success(result);
    } catch (e) {
      return Result.failure(e);
    }
  }

  bool _shouldRetryImageGenerationError(Object? error) {
    final message = error?.toString().toLowerCase().trim() ?? '';
    if (message.isEmpty) {
      return true;
    }

    const nonRetryableMarkers = [
      'failed-precondition',
      'permission-denied',
      'forbidden',
      'unauthenticated',
      'invalid-argument',
      'resource-exhausted',
      'billing hard limit',
      'insufficient_quota',
      'quota',
      'app check',
      'appcheck',
    ];

    for (final marker in nonRetryableMarkers) {
      if (message.contains(marker)) {
        return false;
      }
    }

    return true;
  }

  Duration _retryDelay(Duration initialDelay, int attempt) {
    final multiplier = 1 << (attempt - 1);
    return Duration(
      milliseconds: initialDelay.inMilliseconds * multiplier,
    );
  }
}
