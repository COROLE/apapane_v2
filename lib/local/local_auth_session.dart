import 'dart:convert';

import 'package:apapane/config/app_env.dart';
import 'package:apapane/models/auth/local_session_user.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalAuthSession {
  LocalAuthSession._();

  static final LocalAuthSession instance = LocalAuthSession._();
  static const _guestSessionStorageKey = 'guest_session_user';

  GoogleSignIn? _googleSignIn;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  LocalSessionUser? _currentUser;

  LocalSessionUser? get currentUser => _currentUser;
  String get guestSessionId {
    final currentUid = _currentUser?.uid.trim() ?? '';
    if (currentUid.isNotEmpty) {
      return currentUid;
    }

    final restoredUid = _guestSessionId?.trim() ?? '';
    return restoredUid;
  }
  String? _guestSessionId;

  Future<void> restore() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _currentUser = LocalSessionUser.fromFirebaseUser(user);
      _guestSessionId = user.uid;
      return;
    }

    _currentUser = await _restoreLocalGuestSession();
    _guestSessionId = _currentUser?.uid;
  }

  Future<LocalSessionUser?> ensureGuestSession() async {
    if (_hasValidCurrentUser) {
      return _currentUser;
    }
    _currentUser = null;
    _guestSessionId = null;

    final existing = _firebaseAuth.currentUser;
    if (existing != null) {
      _currentUser = LocalSessionUser.fromFirebaseUser(existing);
      _guestSessionId = existing.uid;
      return _currentUser;
    }

    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        return _createLocalGuestSession();
      }
      _currentUser = LocalSessionUser.fromFirebaseUser(user);
      _guestSessionId = user.uid;
      return _currentUser;
    } catch (_) {
      return _createLocalGuestSession();
    }
  }

  Future<LocalSessionUser> signInWithGoogle() async {
    final googleSignIn = _buildGoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw const LocalAuthException(
        code: 'sign_in_canceled',
        message: 'Googleログインをキャンセルしました。',
      );
    }

    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
    final currentUser = _firebaseAuth.currentUser;
    final userCredential = currentUser?.isAnonymous == true
        ? await _linkOrSignInWithCredential(credential)
        : await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw const LocalAuthException(
        code: 'sign_in_failed',
        message: 'Googleログインの結果を確認できませんでした。',
      );
    }

    _currentUser = LocalSessionUser.fromFirebaseUser(user);
    _guestSessionId = user.uid;
    await _clearLocalGuestSession();
    return _currentUser!;
  }

  Future<LocalSessionUser> signInWithApple() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      throw const LocalAuthException(
        code: 'unsupported_platform',
        message: 'Appleでログインできるのは iOS のみです。',
      );
    }

    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final currentUser = _firebaseAuth.currentUser;
    final userCredential = currentUser?.isAnonymous == true
        ? await _linkOrSignInWithProvider(provider)
        : await _firebaseAuth.signInWithProvider(provider);
    final user = userCredential.user;
    if (user == null) {
      throw const LocalAuthException(
        code: 'sign_in_failed',
        message: 'Appleログインの結果を確認できませんでした。',
      );
    }

    _currentUser = LocalSessionUser.fromFirebaseUser(user);
    _guestSessionId = user.uid;
    await _clearLocalGuestSession();
    return _currentUser!;
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _firebaseAuth.signOut();
    _currentUser = null;
    _guestSessionId = null;
    await ensureGuestSession();
  }

  Future<String> ensureCallableSessionId() async {
    final currentSessionId = guestSessionId.trim();
    if (currentSessionId.isNotEmpty) {
      return currentSessionId;
    }

    final user = await ensureGuestSession();
    return user?.uid.trim() ?? '';
  }

  Future<void> updateCurrentUser({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      if (_currentUser?.isGuest == true && displayName != null) {
        _currentUser = _currentUser!.copyWith(displayName: displayName);
        await _persistLocalGuestSession(_currentUser!);
      }
      return;
    }
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
    await user.reload();
    final refreshed = _firebaseAuth.currentUser;
    _currentUser =
        refreshed == null ? null : LocalSessionUser.fromFirebaseUser(refreshed);
    _guestSessionId = _currentUser?.uid;
  }

  Future<void> deleteCurrentUser() async {
    final callable = _functions.httpsCallable('deleteAccount');
    await callable.call();
    await signOut();
    await ensureGuestSession();
  }

  Future<LocalSessionUser?> _restoreLocalGuestSession() async {
    final preferences = await SharedPreferences.getInstance();
    final rawJson = preferences.getString(_guestSessionStorageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      final restoredUser = LocalSessionUser.fromJson(
        Map<String, dynamic>.from(
          _decodeJson(rawJson),
        ),
      );
      if (restoredUser.uid.trim().isEmpty) {
        await preferences.remove(_guestSessionStorageKey);
        return null;
      }
      return restoredUser;
    } catch (_) {
      await preferences.remove(_guestSessionStorageKey);
      return null;
    }
  }

  Future<LocalSessionUser> _createLocalGuestSession() async {
    const uuid = Uuid();
    final guestUser = LocalSessionUser(
      id: 'guest-${uuid.v4()}',
      email: '',
      displayName: 'ゲスト',
      photoUrl: '',
      isAnonymous: true,
    );
    _currentUser = guestUser;
    _guestSessionId = guestUser.uid;
    await _persistLocalGuestSession(guestUser);
    return guestUser;
  }

  Future<void> _persistLocalGuestSession(LocalSessionUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _guestSessionStorageKey,
      _encodeJson(user.toJson()),
    );
  }

  Future<void> _clearLocalGuestSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_guestSessionStorageKey);
  }

  bool get _hasValidCurrentUser =>
      _currentUser != null && _currentUser!.uid.trim().isNotEmpty;

  Map<String, dynamic> _decodeJson(String rawJson) {
    return Map<String, dynamic>.from(
      jsonDecode(rawJson) as Map,
    );
  }

  String _encodeJson(Map<String, dynamic> value) {
    return jsonEncode(value);
  }

  GoogleSignIn _buildGoogleSignIn() {
    final existing = _googleSignIn;
    if (existing != null) {
      return existing;
    }

    final serverClientId =
        AppEnv.getByName('GOOGLE_WEB_SERVER_CLIENT_ID').trim();
    final iosClientId = AppEnv.getByName('GOOGLE_IOS_CLIENT_ID').trim();

    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
      clientId: iosClientId.isEmpty ? null : iosClientId,
    );
    return _googleSignIn!;
  }

  Future<UserCredential> _linkOrSignInWithCredential(
    AuthCredential credential,
  ) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      return _firebaseAuth.signInWithCredential(credential);
    }

    try {
      return await currentUser.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' ||
          error.code == 'provider-already-linked' ||
          error.code == 'email-already-in-use') {
        return _firebaseAuth.signInWithCredential(credential);
      }
      rethrow;
    }
  }

  Future<UserCredential> _linkOrSignInWithProvider(
    AuthProvider provider,
  ) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      return _firebaseAuth.signInWithProvider(provider);
    }

    try {
      return await currentUser.linkWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' ||
          error.code == 'provider-already-linked' ||
          error.code == 'email-already-in-use') {
        return _firebaseAuth.signInWithProvider(provider);
      }
      rethrow;
    }
  }
}

class LocalAuthException implements Exception {
  const LocalAuthException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}
