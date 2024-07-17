import 'package:apapane/models/result/result.dart';
import 'package:apapane/services/auth/auth_service.dart';
import 'package:apapane/typedefs/result_typedef.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  FutureResult<User> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final res =
          await _authService.createUserWithEmailAndPassword(email, password);
      final user = res.user;
      return (user == null) ? throw Error() : Result.success(user);
    } catch (e) {
      debugPrint(e.toString());
      return Result.failure(e);
    }
  }

  FutureResult<User> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final res =
          await _authService.signInWithEmailAndPassword(email, password);
      final user = res.user;
      return (user == null) ? throw Error() : Result.success(user);
    } catch (e) {
      debugPrint(e.toString());
      return Result.failure(e);
    }
  }

  FutureResult<bool> signOut() async {
    try {
      await _authService.signOut();
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> sendEmailVerification(User user) async {
    try {
      await _authService.sendEmailVerification(user);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> reauthenticateWithCredential(
      User user, String password) async {
    try {
      await _authService.reauthenticateWithCredential(user, password);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> verifyBeforeUpdateEmail(User user, String newEmail) async {
    try {
      await _authService.verifyBeforeUpdateEmail(user, newEmail);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> updatePassword(User user, String newPassword) async {
    try {
      await _authService.updatePassword(user, newPassword);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> delete(User user) async {
    try {
      await _authService.delete(user);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }
}
