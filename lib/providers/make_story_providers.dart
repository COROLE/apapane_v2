import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/services/firestore/firestore_service.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/api_service.dart';
import '../repositories/api_repository.dart';
import '../view_models/chat_view_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository(
    ref.read(apiServiceProvider),
  );
});
final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(
    ref.read(firestoreServiceProvider),
  );
});

final storyViewModelProvider = ChangeNotifierProvider<StoryViewModel>((ref) {
  return StoryViewModel(
      ref.read(apiRepositoryProvider), ref.read(firestoreRepositoryProvider));
});

final chatViewModelProvider = ChangeNotifierProvider<ChatViewModel>((ref) {
  return ChatViewModel(ref.read(apiRepositoryProvider));
});
