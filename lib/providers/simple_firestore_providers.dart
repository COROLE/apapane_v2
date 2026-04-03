import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/view_models/admin_view_model.dart';
import 'package:apapane/view_models/archive_view_model.dart';
import 'package:apapane/view_models/edit_profile_view_model.dart';
import 'package:apapane/view_models/profile_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final archiveViewModelProvider =
    ChangeNotifierProvider<ArchiveViewModel>((ref) {
  return ArchiveViewModel(ref.read(firestoreRepositoryProvider));
});

final profileViewModelProvider =
    ChangeNotifierProvider<ProfileViewModel>((ref) {
  return ProfileViewModel(ref.read(firestoreRepositoryProvider));
});

final editProfileViewModelProvider =
    ChangeNotifierProvider<EditProfileViewModel>((ref) {
  return EditProfileViewModel(
    ref.read(firestoreRepositoryProvider),
    ref.read(authRepositoryProvider),
  );
});

final adminViewModelProvider = ChangeNotifierProvider<AdminViewModel>((ref) {
  return AdminViewModel();
});
