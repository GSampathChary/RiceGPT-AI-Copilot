class AppConfig {
  static const appName = 'RiceGPT AI';
  static const appVersion = '1.0.0';
  static const defaultProvider = 'gemini';
  static const defaultLanguage = 'English';
  static const publicBackendUrl = 'https://ricegpt-ai-copilot.onrender.com';
  static const String productionBaseUrl = String.fromEnvironment(
    'RICEGPT_API_BASE_URL',
    defaultValue: '',
  );

  static String get defaultBaseUrl {
    if (productionBaseUrl.isNotEmpty) {
      return productionBaseUrl;
    }
    return publicBackendUrl;
  }
}
