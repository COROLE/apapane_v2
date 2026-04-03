import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/repositories/api_repository.dart';
import 'package:apapane/services/api/api_service.dart';
import 'package:apapane/view_models/chat_view_model.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository(ref.read(apiServiceProvider));
});

final storyViewModelProvider = ChangeNotifierProvider<StoryViewModel>((ref) {
  return StoryViewModel(
    ref.read(apiRepositoryProvider),
    ref.read(firestoreRepositoryProvider),
  );
});

final chatViewModelProvider = ChangeNotifierProvider<ChatViewModel>((ref) {
  return ChatViewModel(ref.read(apiRepositoryProvider));
});
