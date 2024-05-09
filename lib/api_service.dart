import 'dart:io';

class ApiService {
  static String get baseUrl {
    // プラットフォームごとに異なる URL を返す
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      // 他のプラットフォームに対するデフォルトの URL
      return 'http://localhost:8000';
    }
  }
}