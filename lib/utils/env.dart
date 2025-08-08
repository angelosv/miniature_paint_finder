import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    const fromBuild = String.fromEnvironment('API_BASE_URL');
    if (fromBuild.isNotEmpty) {
      print('🚀 Using API_BASE_URL from --dart-define (build time).');
      return fromBuild;
    }

    final fromEnv = dotenv.env['API_BASE_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      print('📄 Using API_BASE_URL from .env (dotenv).');
      return fromEnv;
    }

    print('🛟 Using default API_BASE_URL (fallback).');
    return 'https://paints-api.reachu.io/api';
  }
}
