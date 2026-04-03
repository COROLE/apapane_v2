import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apapane/config/app_env.dart';
import 'package:apapane/enums/env_key.dart';
import 'package:apapane/local/local_auth_session.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;
  static const Duration _functionCallTimeout = Duration(seconds: 45);

  Future<String> callClaude(
    String prompt,
    String systemPrompt,
    String apiKeyName, {
    bool jsonOutput = false,
    SDMap? responseJsonSchema,
  }) async {
    final data = await _callFunction(
      'generateStory',
      {
        'prompt': prompt,
        'systemPrompt': systemPrompt,
        'profile': apiKeyName,
        'jsonOutput': jsonOutput,
        if (responseJsonSchema != null) 'responseSchema': responseJsonSchema,
      },
    );
    final text = data['text'];
    if (text is! String || text.trim().isEmpty) {
      throw StateError('generateStory returned an empty response.');
    }
    return text.trim();
  }

  Future<SDMap> callStableDiffusion(String prompt, String negativePrompt,
      {int seed = 0}) async {
    final payload = {
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'seed': seed,
    };

    try {
      final data = await _callImageHttp(payload);
      _ensureImageData(
        data,
        errorMessage: 'generateImageHttp did not return image data.',
      );
      return data;
    } catch (httpError) {
      final data = await _callFunction('generateImage', payload);
      _ensureImageData(
        data,
        errorMessage: 'generateImage did not return image data.',
      );
      return data;
    }
  }

  Future<Uint8List?> fetchVoiceAudioBytes(String text) async {
    final data = await _callFunction(
      'synthesizeVoice',
      {
        'text': text,
      },
    );
    final audioBase64 = data['audioBase64'];
    if (audioBase64 is! String || audioBase64.trim().isEmpty) {
      return null;
    }
    return base64Decode(audioBase64.trim());
  }

  Future<SDMap> _callFunction(String name, SDMap payload) async {
    final callable = _functions.httpsCallable(name);
    final guestSessionId =
        await LocalAuthSession.instance.ensureCallableSessionId();
    final mergedPayload = {
      ...payload,
      if (guestSessionId.isNotEmpty) 'guestSessionId': guestSessionId,
    };
    final result = await callable.call(mergedPayload).timeout(
          _functionCallTimeout,
          onTimeout: () => throw TimeoutException('$name timed out.'),
        );
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw StateError('$name returned an unexpected payload.');
  }

  Future<SDMap> _callImageHttp(SDMap payload) async {
    final guestSessionId =
        await LocalAuthSession.instance.ensureCallableSessionId();
    final projectId = AppEnv.get(EnvKey.FIREBASE_PROJECT_ID).trim();
    if (projectId.isEmpty) {
      throw StateError('Firebase project ID is missing.');
    }
    final appCheckToken = await _tryAppCheckToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (appCheckToken.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken;
    }

    final url = Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/generateImageHttp',
    );
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            ...payload,
            if (guestSessionId.isNotEmpty) 'guestSessionId': guestSessionId,
          }),
        )
        .timeout(
          _functionCallTimeout,
          onTimeout: () =>
              throw TimeoutException('generateImageHttp timed out.'),
        );

    final rawBody = utf8.decode(response.bodyBytes);
    final decodedBody = _decodeHttpJson(rawBody);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractHttpErrorMessage(decodedBody, rawBody);
      throw StateError(
        'generateImageHttp failed (${response.statusCode}): $message',
      );
    }

    if (decodedBody is Map<String, dynamic>) {
      return decodedBody;
    }
    throw StateError('generateImageHttp returned an unexpected payload.');
  }

  Future<String> _tryAppCheckToken() async {
    try {
      return await _appCheckToken();
    } catch (_) {
      return '';
    }
  }

  dynamic _decodeHttpJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return rawBody;
    }
  }

  String _extractHttpErrorMessage(dynamic decodedBody, String rawBody) {
    if (decodedBody is Map) {
      final error = decodedBody['error'];
      final message = decodedBody['message'];
      if (error is String && message is String && message.trim().isNotEmpty) {
        return '$error: ${message.trim()}';
      }
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    }
    return rawBody.trim().isNotEmpty ? rawBody.trim() : 'unknown error';
  }

  Future<String> _appCheckToken() async {
    try {
      final limitedUseToken =
          await FirebaseAppCheck.instance.getLimitedUseToken();
      final normalizedLimitedUseToken = limitedUseToken.trim();
      if (normalizedLimitedUseToken.isNotEmpty) {
        return normalizedLimitedUseToken;
      }
    } catch (_) {
      // Fall back to the standard App Check token when limited-use tokens
      // are unavailable on the current platform/runtime.
    }

    final token = await FirebaseAppCheck.instance.getToken();
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      throw StateError('App Check token is missing.');
    }
    return normalizedToken;
  }

  void _ensureImageData(
    SDMap data, {
    required String errorMessage,
  }) {
    final base64 = data['base64'];
    final imageUrl = data['imageUrl'];
    final hasBase64 = base64 is String && base64.trim().isNotEmpty;
    final hasImageUrl = imageUrl is String && imageUrl.trim().isNotEmpty;
    if (!hasBase64 && !hasImageUrl) {
      throw StateError(errorMessage);
    }
  }
}
