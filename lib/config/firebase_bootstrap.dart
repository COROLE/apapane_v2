import 'package:apapane/config/app_env.dart';
import 'package:apapane/enums/env_key.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!AppEnv.hasFirebaseConfiguration()) {
      throw StateError(
        'Firebase の公開設定が不足しています。.env または --dart-define に Firebase の公開設定を入力してください。',
      );
    }

    await Firebase.initializeApp(options: _currentPlatformOptions());
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    _initialized = true;
  }

  static FirebaseOptions _currentPlatformOptions() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: _platformApiKey(
            EnvKey.FIREBASE_ANDROID_API_KEY,
          ),
          appId: _require(EnvKey.FIREBASE_ANDROID_APP_ID),
          messagingSenderId: _require(EnvKey.FIREBASE_MESSAGING_SENDER_ID),
          projectId: _require(EnvKey.FIREBASE_PROJECT_ID),
          storageBucket: _require(EnvKey.FIREBASE_STORAGE_BUCKET),
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: _platformApiKey(
            EnvKey.FIREBASE_IOS_API_KEY,
          ),
          appId: _require(EnvKey.FIREBASE_IOS_APP_ID),
          messagingSenderId: _require(EnvKey.FIREBASE_MESSAGING_SENDER_ID),
          projectId: _require(EnvKey.FIREBASE_PROJECT_ID),
          storageBucket: _require(EnvKey.FIREBASE_STORAGE_BUCKET),
          iosClientId: _optional(EnvKey.GOOGLE_IOS_CLIENT_ID),
          iosBundleId: _require(EnvKey.FIREBASE_IOS_BUNDLE_ID),
        );
      default:
        throw UnsupportedError(
          'アパパネの公開版は Android と iOS のみ対応しています。',
        );
    }
  }

  static String _require(EnvKey key) {
    final value = AppEnv.get(key).trim();
    if (value.isEmpty) {
      throw StateError('必須設定が不足しています: ${key.name}');
    }
    return value;
  }

  static String _platformApiKey(EnvKey platformKey) {
    final platformValue = AppEnv.get(platformKey).trim();
    if (platformValue.isNotEmpty) {
      return platformValue;
    }
    return _require(EnvKey.FIREBASE_API_KEY);
  }

  static String? _optional(EnvKey key) {
    final value = AppEnv.get(key).trim();
    return value.isEmpty ? null : value;
  }
}
