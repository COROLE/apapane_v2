import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/services/firestore/firestore_service.dart';
import 'package:apapane/view_models/admin_view_model.dart';
import 'package:apapane/view_models/archive_view_model.dart';
import 'package:apapane/view_models/profile_view_model.dart';
import 'package:apapane/view_models/public_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(
    ref.read(firestoreServiceProvider),
  );
});

final archiveViewModelProvider =
    ChangeNotifierProvider<ArchiveViewModel>((ref) {
  return ArchiveViewModel(ref.read(firestoreRepositoryProvider));
});

final publicViewModelProvider = ChangeNotifierProvider<PublicViewModel>((ref) {
  return PublicViewModel(ref.read(firestoreRepositoryProvider));
});

final profileViewModelProvider =
    ChangeNotifierProvider<ProfileViewModel>((ref) {
  return ProfileViewModel(ref.read(firestoreRepositoryProvider));
});
final adminViewModelProvider = ChangeNotifierProvider<AdminViewModel>((ref) {
  return AdminViewModel(ref.read(firestoreRepositoryProvider));
});
