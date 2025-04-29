class Env {
  static const bool isQA = bool.fromEnvironment('QA', defaultValue: false);
  static const bool isLocal = bool.fromEnvironment(
    'LOCAL',
    defaultValue: false,
  );

  static String get apiBaseUrl {
    if (isLocal) return 'http://localhost:8000';
    if (isQA) return 'https://api-qa.tu-dominio.com';
    return 'https://paints-api.reachu.io';
  }
}
