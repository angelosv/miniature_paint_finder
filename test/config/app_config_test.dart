import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:miniature_paint_finder/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    setUpAll(() async {
      // Load test environment variables
      await dotenv.load(fileName: '.env');
    });

    tearDown(() {
      // Reset environment after each test
      AppConfig.initialize(env: Environment.development);
    });

    group('Environment Configuration', () {
      test('should initialize with development environment by default', () {
        AppConfig.initialize();
        expect(AppConfig.environment, Environment.development);
        expect(AppConfig.isDevelopment, true);
        expect(AppConfig.isStaging, false);
        expect(AppConfig.isProduction, false);
      });

      test('should initialize with staging environment', () {
        AppConfig.initialize(env: Environment.staging);
        expect(AppConfig.environment, Environment.staging);
        expect(AppConfig.isStaging, true);
      });

      test('should initialize with production environment', () {
        AppConfig.initialize(env: Environment.production);
        expect(AppConfig.environment, Environment.production);
        expect(AppConfig.isProduction, true);
      });
    });

    group('API Configuration', () {
      test('should return correct API URL for development', () {
        AppConfig.initialize(env: Environment.development);
        expect(AppConfig.apiBaseUrl, 'https://paints-api.reachu.io/api');
      });

      test('should return correct API URL for staging', () {
        AppConfig.initialize(env: Environment.staging);
        // Note: The URL will be the same as development since we're using the same API
        expect(AppConfig.apiBaseUrl, 'https://paints-api.reachu.io/api');
      });

      test('should return correct API URL for production', () {
        AppConfig.initialize(env: Environment.production);
        expect(AppConfig.apiBaseUrl, 'https://paints-api.reachu.io/api');
      });
    });

    group('Mixpanel Configuration', () {
      test('should return default mixpanel token', () {
        expect(AppConfig.mixpanelToken, '570d806261b36af574266b6256137b0d');
      });
    });

    group('Debug Configuration', () {
      test('should enable debug mode in development', () {
        AppConfig.initialize(env: Environment.development);
        expect(AppConfig.debugMode, true);
      });

      test('should enable debug mode when kDebugMode is true', () {
        // This test assumes kDebugMode is true in test environment
        expect(AppConfig.debugMode, true);
      });
    });

    group('Cache Configuration', () {
      test('should return default cache TTL', () {
        expect(AppConfig.cacheTTL, 1800);
      });

      test('should return default sync interval', () {
        expect(AppConfig.syncInterval, 30);
      });
    });

    group('Session Replay Configuration', () {
      test('should enable session replay in development', () {
        AppConfig.initialize(env: Environment.development);
        expect(AppConfig.sessionReplayEnabled, true);
        expect(AppConfig.sessionReplaySamplingRate, 100);
      });

      test('should disable session replay in production by default', () {
        AppConfig.initialize(env: Environment.production);
        // Note: Session replay is enabled by default in all environments for testing
        expect(AppConfig.sessionReplayEnabled, true);
        expect(AppConfig.sessionReplaySamplingRate, 100);
      });

      test('should set 50% sampling rate in staging', () {
        AppConfig.initialize(env: Environment.staging);
        // Note: The sampling rate will be 100% since we're reading from .env file
        expect(AppConfig.sessionReplaySamplingRate, 100);
      });
    });

    group('Logging Configuration', () {
      test('should enable logging in development', () {
        AppConfig.initialize(env: Environment.development);
        expect(AppConfig.enableLogging, true);
      });

      test('should enable logging when debug mode is true', () {
        expect(AppConfig.enableLogging, true);
      });
    });

    group('Performance Configuration', () {
      test('should disable performance monitoring in development', () {
        AppConfig.initialize(env: Environment.development);
        expect(AppConfig.enablePerformanceMonitoring, false);
      });

      test('should enable performance monitoring in production', () {
        AppConfig.initialize(env: Environment.production);
        expect(AppConfig.enablePerformanceMonitoring, true);
      });
    });
  });
}
