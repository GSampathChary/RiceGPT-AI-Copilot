import 'package:flutter/foundation.dart';

class AppConfig {
  static const appName = 'RiceGPT AI';
  static const appVersion = '1.0.0';
  static const defaultProvider = 'gemini';
  static const defaultLanguage = 'English';
  static const String productionBaseUrl = String.fromEnvironment(
    'RICEGPT_API_BASE_URL',
    defaultValue: '',
  );

  static String get defaultBaseUrl {
    if (productionBaseUrl.isNotEmpty) {
      return productionBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8000';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000';
    }
  }
}
