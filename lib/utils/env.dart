import '../config/app_config.dart';

class Env {
  // Legacy method - now uses AppConfig
  static String get apiBaseUrl {
    return AppConfig.apiBaseUrl;
  }

  // Additional convenience methods
  static String get mixpanelToken => AppConfig.mixpanelToken;
  static bool get debugMode => AppConfig.debugMode;
  static int get cacheTTL => AppConfig.cacheTTL;
  static int get syncInterval => AppConfig.syncInterval;
  static bool get sessionReplayEnabled => AppConfig.sessionReplayEnabled;
  static int get sessionReplaySamplingRate =>
      AppConfig.sessionReplaySamplingRate;

  // Environment helpers
  static bool get isDevelopment => AppConfig.isDevelopment;
  static bool get isStaging => AppConfig.isStaging;
  static bool get isProduction => AppConfig.isProduction;
  static bool get isQA => AppConfig.isQA;
}
