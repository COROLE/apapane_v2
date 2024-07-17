import 'package:apapane/repositories/auth_repository.dart';
import 'package:apapane/services/auth/auth_service.dart';
import 'package:apapane/view_models/login_view_model.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/services/firestore/firestore_service.dart';
import 'package:apapane/view_models/signup_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(
    ref.read(firestoreServiceProvider),
  );
});
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(authServiceProvider),
  );
});

final mainViewModelProvider = ChangeNotifierProvider<MainViewModel>((ref) {
  return MainViewModel(
      ref.read(firestoreRepositoryProvider), ref.read(authRepositoryProvider));
});

final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>((ref) {
  return LoginViewModel(ref.read(authRepositoryProvider));
});
final signUpViewModelProvider = ChangeNotifierProvider<SignUpViewModel>((ref) {
  return SignUpViewModel(
      ref.read(firestoreRepositoryProvider), ref.read(authRepositoryProvider));
});
