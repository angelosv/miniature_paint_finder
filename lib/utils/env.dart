class Env {
  static const isQA = bool.fromEnvironment('QA', defaultValue: false);

  static String get apiBaseUrl =>
      isQA ? 'https://api-qa.tu-dominio.com' : 'https://paints-api.reachu.io';
}
