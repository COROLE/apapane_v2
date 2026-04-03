import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/local/local_firestore.dart';
import 'package:apapane/models/auth/local_session_user.dart';
import 'package:apapane/models/firestore_user/firestore_user.dart';
import 'package:apapane/models/result/result.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/services/auth/auth_service.dart';
import 'package:apapane/typedefs/result_typedef.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  AuthRepository(this._authService, this._firestoreRepository);

  final AuthService _authService;
  final FirestoreRepository _firestoreRepository;

  FutureResult<LocalSessionUser?> restoreSession() async {
    try {
      final user = await _authService.restoreSession();
      if (user != null) {
        await _ensureLocalProfile(user);
      }
      return Result.success(user);
    } catch (error) {
      debugPrint(error.toString());
      return Result.failure(error);
    }
  }

  FutureResult<LocalSessionUser> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      await _ensureLocalProfile(user);
      return Result.success(user);
    } catch (error) {
      debugPrint(error.toString());
      return Result.failure(error);
    }
  }

  FutureResult<LocalSessionUser> signInWithApple() async {
    try {
      final user = await _authService.signInWithApple();
      await _ensureLocalProfile(user);
      return Result.success(user);
    } catch (error) {
      debugPrint(error.toString());
      return Result.failure(error);
    }
  }

  FutureResult<bool> signOut() async {
    try {
      await _authService.signOut();
      return const Result.success(true);
    } catch (error) {
      return Result.failure(error);
    }
  }

  FutureResult<bool> updateCurrentUser({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _authService.updateCurrentUser(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return const Result.success(true);
    } catch (error) {
      return Result.failure(error);
    }
  }

  FutureResult<bool> deleteCurrentUser() async {
    try {
      await _authService.deleteCurrentUser();
      return const Result.success(true);
    } catch (error) {
      return Result.failure(error);
    }
  }

  Future<void> _ensureLocalProfile(LocalSessionUser user) async {
    if (user.isGuest) {
      return;
    }

    final profileRef = ColRefCore.publicUsersColRef().doc(user.uid);
    final currentProfileResult = await _firestoreRepository.getDoc(profileRef);
    final currentProfile = currentProfileResult.when(
      success: (doc) => doc.data(),
      failure: (_) => null,
    );

    if (currentProfile != null) {
      final updates = <String, dynamic>{};
      if ((currentProfile['userName']?.toString().trim().isEmpty ?? true) &&
          user.displayName.trim().isNotEmpty) {
        updates['userName'] = user.displayName.trim();
      }
      final currentPhoto = currentProfile['userImageURL']?.toString() ?? '';
      if (currentPhoto.isEmpty && user.photoUrl.isNotEmpty) {
        updates['userImageURL'] = user.photoUrl;
      }
      if (updates.isNotEmpty) {
        updates['updatedAt'] = Timestamp.now();
        await _firestoreRepository.updateDoc(profileRef, updates);
      }
      return;
    }

    final now = Timestamp.now();
    final firestoreUser = FirestoreUser(
      age: 0,
      coins: 0,
      createdAt: now,
      favoriteMyStoryCount: 0,
      followerCount: 0,
      followingCount: 0,
      isAdmin: false,
      consumables: const [],
      silverSubscription: const {},
      updatedAt: now,
      userName: user.displayName,
      userImageURL: user.photoUrl,
      uid: user.uid,
    );
    await _firestoreRepository.createDoc(profileRef, firestoreUser.toJson());
  }
}
