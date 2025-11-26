import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

enum Environment { development, staging, production, qa }

class AppConfig {
  static Environment _environment = Environment.development;

  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static void initialize({Environment? env}) {
    _environment = env ?? _detectEnvironmentFromBranch();
  }

  /// Detecta automáticamente el ambiente basado en la rama de Git
  static Environment _detectEnvironmentFromBranch() {
    try {
      // Primero intentar obtener de variables de entorno
      final envFromEnv = dotenv.env['ENVIRONMENT']?.toLowerCase();
      if (envFromEnv != null) {
        switch (envFromEnv) {
          case 'production':
          case 'prod':
            return Environment.production;
          case 'staging':
          case 'stage':
            return Environment.staging;
          case 'qa':
          case 'testing':
            return Environment.qa;
          case 'development':
          case 'dev':
          default:
            return Environment.development;
        }
      }

      // Si no hay variable de entorno, detectar por rama Git
      final result = Process.runSync('git', ['branch', '--show-current']);
      if (result.exitCode == 0) {
        final branch = result.stdout.toString().trim().toLowerCase();

        if (branch.contains('main') ||
            branch.contains('master') ||
            branch.contains('prod')) {
          return Environment.production;
        } else if (branch.contains('staging') || branch.contains('stage')) {
          return Environment.staging;
        } else if (branch.contains('qa') || branch.contains('test')) {
          return Environment.qa;
        } else {
          return Environment.development;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not detect environment from Git branch: $e');
    }

    // Fallback a development
    return Environment.development;
  }

  static Environment get environment => _environment;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  static bool get isQA => _environment == Environment.qa;

  // API Configuration
  static String get apiBaseUrl {
    // Priority: 1. Build-time define, 2. .env file, 3. Environment-specific .env, 4. Default
    const fromBuild = String.fromEnvironment('API_BASE_URL');
    if (fromBuild.isNotEmpty) {
      return fromBuild;
    }

    final fromEnv = dotenv.env['API_BASE_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    // Check for environment-specific URL override
    final envSpecificUrl =
        dotenv.env['${_environment.name.toUpperCase()}_API_URL'];
    if (envSpecificUrl != null && envSpecificUrl.isNotEmpty) {
      return envSpecificUrl;
    }

    // Default URLs per environment
    switch (_environment) {
      case Environment.development:
        return 'https://paints-api.reachu.io/qa-api';
      case Environment.qa:
        return 'https://paints-api.reachu.io/qa-api';
      case Environment.staging:
        return 'https://staging-paints-api.reachu.io/api';
      case Environment.production:
        return 'https://paints-api.reachu.io/api';
    }
  }

  // Mixpanel Configuration
  static String get mixpanelToken {
    const fromBuild = String.fromEnvironment('MIXPANEL_TOKEN');
    if (fromBuild.isNotEmpty) {
      return fromBuild;
    }

    final fromEnv = dotenv.env['MIXPANEL_TOKEN'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    return '570d806261b36af574266b6256137b0d'; // Default token
  }

  // Debug Configuration
  static bool get debugMode {
    const fromBuild = String.fromEnvironment('DEBUG_MODE');
    if (fromBuild.isNotEmpty) {
      return fromBuild.toLowerCase() == 'true';
    }

    final fromEnv = dotenv.env['DEBUG_MODE'];
    if (fromEnv != null) {
      return fromEnv.toLowerCase() == 'true';
    }

    return kDebugMode || _environment == Environment.development;
  }

  // Cache Configuration
  static int get cacheTTL {
    const fromBuild = String.fromEnvironment('CACHE_TTL');
    if (fromBuild.isNotEmpty) {
      return int.tryParse(fromBuild) ?? 1800;
    }

    final fromEnv = dotenv.env['CACHE_TTL'];
    if (fromEnv != null) {
      return int.tryParse(fromEnv) ?? 1800;
    }

    return 1800; // 30 minutes default
  }

  static int get syncInterval {
    const fromBuild = String.fromEnvironment('SYNC_INTERVAL');
    if (fromBuild.isNotEmpty) {
      return int.tryParse(fromBuild) ?? 30;
    }

    final fromEnv = dotenv.env['SYNC_INTERVAL'];
    if (fromEnv != null) {
      return int.tryParse(fromEnv) ?? 30;
    }

    return 30; // 30 seconds default
  }

  // Session Replay Configuration
  static bool get sessionReplayEnabled {
    const fromBuild = String.fromEnvironment('SESSION_REPLAY_ENABLED');
    if (fromBuild.isNotEmpty) {
      return fromBuild.toLowerCase() == 'true';
    }

    final fromEnv = dotenv.env['SESSION_REPLAY_ENABLED'];
    if (fromEnv != null) {
      return fromEnv.toLowerCase() == 'true';
    }

    return _environment !=
        Environment.production; // Disabled in production by default
  }

  static int get sessionReplaySamplingRate {
    const fromBuild = String.fromEnvironment('SESSION_REPLAY_SAMPLING_RATE');
    if (fromBuild.isNotEmpty) {
      return int.tryParse(fromBuild) ?? 100;
    }

    final fromEnv = dotenv.env['SESSION_REPLAY_SAMPLING_RATE'];
    if (fromEnv != null) {
      return int.tryParse(fromEnv) ?? 100;
    }

    switch (_environment) {
      case Environment.development:
        return 100; // 100% in development
      case Environment.qa:
        return 100; // 100% in QA for testing
      case Environment.staging:
        return 50; // 50% in staging
      case Environment.production:
        return 10; // 10% in production
    }
  }

  // Logging Configuration
  static bool get enableLogging {
    return debugMode || _environment == Environment.development;
  }

  // Performance Configuration
  static bool get enablePerformanceMonitoring {
    return _environment != Environment.development &&
        _environment != Environment.qa;
  }

  // Git Branch Detection
  static String? get currentGitBranch {
    try {
      final result = Process.runSync('git', ['branch', '--show-current']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('⚠️ Could not get Git branch: $e');
    }
    return null;
  }

  // Print current configuration (for debugging)
  static void printConfig() {
    if (!enableLogging) return;

    print('🔧 App Configuration:');
    print('  Environment: $_environment');
    print('  Git Branch: ${currentGitBranch ?? "unknown"}');
    print('  API Base URL: $apiBaseUrl');
    print('  Debug Mode: $debugMode');
    print('  Cache TTL: ${cacheTTL}s');
    print('  Sync Interval: ${syncInterval}s');
    print(
      '  Session Replay: $sessionReplayEnabled (${sessionReplaySamplingRate}%)',
    );
    print('  Logging: $enableLogging');
  }
}
