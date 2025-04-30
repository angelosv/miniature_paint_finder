class Env {
  static const bool isQA = bool.fromEnvironment('QA', defaultValue: false);
  static const bool isLocal = bool.fromEnvironment(
    'LOCAL',
    defaultValue: false,
  );

  static String get apiBaseUrl {
    if (isLocal) return 'http://localhost:8000/api';
    if (isQA) return 'https://paints-api.reachu.io/qa-api';
    return 'https://paints-api.reachu.io/api';
  }
}
