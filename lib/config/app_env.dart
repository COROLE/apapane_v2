import 'package:apapane/enums/env_key.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static const String _firebaseApiKeyName = 'FIREBASE_API_KEY';
  static const String _firebaseAndroidApiKeyName = 'FIREBASE_ANDROID_API_KEY';
  static const String _firebaseIosApiKeyName = 'FIREBASE_IOS_API_KEY';
  static const String _firebaseProjectIdName = 'FIREBASE_PROJECT_ID';
  static const String _firebaseMessagingSenderIdName =
      'FIREBASE_MESSAGING_SENDER_ID';
  static const String _firebaseStorageBucketName = 'FIREBASE_STORAGE_BUCKET';
  static const String _firebaseAndroidAppIdName = 'FIREBASE_ANDROID_APP_ID';
  static const String _firebaseIosAppIdName = 'FIREBASE_IOS_APP_ID';
  static const String _googleWebServerClientIdName =
      'GOOGLE_WEB_SERVER_CLIENT_ID';
  static const String _googleIosClientIdName = 'GOOGLE_IOS_CLIENT_ID';
  static const String _googleIosUrlSchemeName = 'GOOGLE_IOS_URL_SCHEME';
  static const String _supportEmailName = 'SUPPORT_EMAIL';
  static const String _privacyPolicyUrlName = 'PRIVACY_POLICY_URL';
  static const String _termsOfServiceUrlName = 'TERMS_OF_SERVICE_URL';

  static final Map<String, String> _defaults = {
    EnvKey.FIREBASE_API_KEY.name: '',
    EnvKey.FIREBASE_ANDROID_API_KEY.name:
        'AIzaSyBQQz0sj_q5L2lMpW969CMvO5kpekfITyE',
    EnvKey.FIREBASE_IOS_API_KEY.name: 'AIzaSyA2A1i_uNZEm-qNqyg7-0FEAL90JeYkX-E',
    EnvKey.FIREBASE_PROJECT_ID.name: 'apapane-94356',
    EnvKey.FIREBASE_MESSAGING_SENDER_ID.name: '712097133007',
    EnvKey.FIREBASE_STORAGE_BUCKET.name: 'apapane-94356.firebasestorage.app',
    EnvKey.FIREBASE_ANDROID_APP_ID.name:
        '1:712097133007:android:3f98b153fa4456d4c7e2ba',
    EnvKey.FIREBASE_IOS_APP_ID.name:
        '1:712097133007:ios:e3078cee373d3c23c7e2ba',
    EnvKey.GOOGLE_WEB_SERVER_CLIENT_ID.name:
        '712097133007-2tiejgepe2djqhluopr4c9efsah5kh6u.apps.googleusercontent.com',
    EnvKey.GOOGLE_IOS_CLIENT_ID.name:
        '712097133007-a944nfdcmf1ug7t7b59ee2jqf5umta32.apps.googleusercontent.com',
    EnvKey.GOOGLE_IOS_URL_SCHEME.name:
        'com.googleusercontent.apps.712097133007-a944nfdcmf1ug7t7b59ee2jqf5umta32',
    EnvKey.SUPPORT_EMAIL.name: 'contact@corole.co.jp',
    EnvKey.PRIVACY_POLICY_URL.name: 'https://corole.net/apapane/privacy',
    EnvKey.TERMS_OF_SERVICE_URL.name: 'https://corole.net/apapane/terms',
  };

  static final Map<String, String> _dartDefines = {
    _firebaseApiKeyName: const String.fromEnvironment(_firebaseApiKeyName),
    _firebaseAndroidApiKeyName:
        const String.fromEnvironment(_firebaseAndroidApiKeyName),
    _firebaseIosApiKeyName:
        const String.fromEnvironment(_firebaseIosApiKeyName),
    _firebaseProjectIdName:
        const String.fromEnvironment(_firebaseProjectIdName),
    _firebaseMessagingSenderIdName:
        const String.fromEnvironment(_firebaseMessagingSenderIdName),
    _firebaseStorageBucketName:
        const String.fromEnvironment(_firebaseStorageBucketName),
    _firebaseAndroidAppIdName:
        const String.fromEnvironment(_firebaseAndroidAppIdName),
    _firebaseIosAppIdName: const String.fromEnvironment(_firebaseIosAppIdName),
    _googleWebServerClientIdName:
        const String.fromEnvironment(_googleWebServerClientIdName),
    _googleIosClientIdName:
        const String.fromEnvironment(_googleIosClientIdName),
    _googleIosUrlSchemeName:
        const String.fromEnvironment(_googleIosUrlSchemeName),
    _supportEmailName: const String.fromEnvironment(_supportEmailName),
    _privacyPolicyUrlName: const String.fromEnvironment(_privacyPolicyUrlName),
    _termsOfServiceUrlName:
        const String.fromEnvironment(_termsOfServiceUrlName),
  };

  static Future<void> load() async {
    await dotenv.load(
      fileName: '.env.example',
      isOptional: true,
      mergeWith: _defaults,
    );
  }

  static String get(EnvKey key) => getByName(key.name);

  static String getByName(String keyName) => _firstNonEmpty([
        dotenv.env[keyName],
        _dartDefines[keyName],
        _defaults[keyName],
      ]);

  static bool hasFirebaseConfiguration() {
    final legacyApiKey = get(EnvKey.FIREBASE_API_KEY).trim();
    final androidApiKey = get(EnvKey.FIREBASE_ANDROID_API_KEY).trim().isNotEmpty
        ? get(EnvKey.FIREBASE_ANDROID_API_KEY).trim()
        : legacyApiKey;
    final iosApiKey = get(EnvKey.FIREBASE_IOS_API_KEY).trim().isNotEmpty
        ? get(EnvKey.FIREBASE_IOS_API_KEY).trim()
        : legacyApiKey;

    return androidApiKey.isNotEmpty &&
        iosApiKey.isNotEmpty &&
        get(EnvKey.FIREBASE_PROJECT_ID).trim().isNotEmpty &&
        get(EnvKey.FIREBASE_MESSAGING_SENDER_ID).trim().isNotEmpty &&
        get(EnvKey.FIREBASE_STORAGE_BUCKET).trim().isNotEmpty &&
        get(EnvKey.FIREBASE_ANDROID_APP_ID).trim().isNotEmpty &&
        get(EnvKey.FIREBASE_IOS_APP_ID).trim().isNotEmpty;
  }

  static String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}
