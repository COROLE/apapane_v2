import 'dart:convert';

import 'package:apapane/enums/env_key.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _anthropicApiUrl =
      'https://api.anthropic.com/v1/messages';
  static const String _stabilityApiUrl =
      "https://api.stability.ai/v1/generation/stable-diffusion-v1-6/text-to-image";
  static const String _voicevoxApiUrl = 'api.tts.quest';

  Future<String> callClaude(
      String prompt, String systemPrompt, String apiKeyName) async {
    // const String model = "claude-3-haiku-20240307";
    const String model = "claude-3-5-sonnet-20240620";
    final String apiKey = dotenv.get(apiKeyName);

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
        Uri.parse(_anthropicApiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        try {
          final SDMap responseData =
              jsonDecode(utf8.decode(response.bodyBytes));
          return responseData['content'][0]['text'];
        } catch (e) {
          debugPrint('Error decoding response: $e');
          return "";
        }
      } else if (response.statusCode == 529) {
        retries++;
        await Future.delayed(Duration(seconds: 2 * retries));
        debugPrint('Retrying due to overloaded error. Retry count: $retries');
      } else {
        debugPrint(
            'Error response: ${response.statusCode}, ${response.body} in callClaude');
        return "error";
      }
    }
    return "error";
  }

  Future<SDMap> callStableDiffusion(
      String prompt, String negativePrompt, String apiKey,
      {int seed = 0}) async {
    try {
      final response = await http.post(
        Uri.parse(_stabilityApiUrl),
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
          final SDMap responseData = jsonDecode(response.body);
          return responseData["artifacts"][0];
        } catch (e) {
          debugPrint('Error decoding image: $e');
          return {};
        }
      } else {
        debugPrint(
            'Error response: ${response.statusCode}, ${response.body} in callStableDiffusion');
        return {};
      }
    } catch (e) {
      debugPrint('Error in callStableDiffusion: $e');
      return {};
    }
  }

  Future<String?> fetchVoicevoxAudioUrl(String text) async {
    final queryParams = {
      'speaker': "3",
      'text': text,
      'key': dotenv.get(EnvKey.VOICEVOX_API_KEY.name),
    };
    final uri =
        Uri.https(_voicevoxApiUrl, '/v3/voicevox/synthesis', queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      debugPrint('Success to load voice');
      return jsonResponse['mp3StreamingUrl'];
    } else {
      debugPrint('Failed to load voice');
      return null;
    }
  }
}
