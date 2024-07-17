import 'package:apapane/enums/env_key.dart';
import 'package:apapane/models/result/result.dart';
import 'package:apapane/services/api/api_service.dart';
import 'package:apapane/typedefs/result_typedef.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiRepository {
  final ApiService _apiService;

  ApiRepository(this._apiService);

  FutureResult<String> getClaudeResponse(
      String prompt, String systemPrompt, String apiKeyName) async {
    try {
      final result =
          await _apiService.callClaude(prompt, systemPrompt, apiKeyName);
      return Result.success(result);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<Map<String, dynamic>> getStableDiffusionImage(
      String prompt, String negativePrompt,
      {int seed = 0}) async {
    try {
      final String apiKey = dotenv.get(EnvKey.STABLE_DIFFUSION_API_KEY.name);
      final result = await _apiService
          .callStableDiffusion(prompt, negativePrompt, apiKey, seed: seed);
      return Result.success(result);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<String?> getVoicevoxAudioUrl(String text) async {
    try {
      final result = await _apiService.fetchVoicevoxAudioUrl(text);
      return Result.success(result);
    } catch (e) {
      return const Result.failure();
    }
  }
}
