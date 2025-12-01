/// Configuration for E2E tests
class TestConfig {
  
  /// Test timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration shortTimeout = Duration(seconds: 10);
  
  /// Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Test data
  static const String testEmail = 'e2e.test@miniaturepaintfinder.com';
  static const String testPassword = 'E2ETestPassword123!';
  static const String testUserName = 'E2E Test User';
  
  /// Performance thresholds
  static const Duration maxLoadTime = Duration(seconds: 5);
  static const Duration maxNavigationTime = Duration(seconds: 3);
  static const Duration maxSyncTime = Duration(seconds: 10);
  
  /// Test environment
  static const bool enableScreenshots = true;
  static const bool enableDetailedLogging = true;
  static const bool cleanupAfterTests = true;
  
  /// Device configuration
  static const String defaultDevice = 'iPhone 15 Pro';
  static const List<String> supportedDevices = [
    'iPhone 15 Pro',
    'iPhone 14',
    'iPhone 13',
    'iPad Pro (12.9-inch)',
  ];
  
  /// Test data limits
  static const int maxTestProjects = 10;
  static const int maxTestPalettes = 5;
  static const int bulkOperationSize = 20;
  
  /// Network simulation
  static const Duration networkDelay = Duration(milliseconds: 500);
  static const Duration offlineTestDuration = Duration(seconds: 30);
  
  /// Cache configuration
  static const Duration cacheValidityPeriod = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  
  /// UI interaction delays
  static const Duration tapDelay = Duration(milliseconds: 100);
  static const Duration typeDelay = Duration(milliseconds: 50);
  static const Duration animationDelay = Duration(milliseconds: 300);
  
  /// Test result configuration
  static const bool generateDetailedReports = true;
  static const bool uploadArtifacts = true;
  static const int reportRetentionDays = 30;
  
  /// Feature flags for tests
  static const bool testOfflineFunctionality = true;
  static const bool testPerformance = true;
  static const bool testAccessibility = false; // Future enhancement
  static const bool testSecurity = false; // Future enhancement
  
  /// Environment-specific settings
  static Map<String, dynamic> getEnvironmentConfig(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
        return {
          'apiBaseUrl': 'https://paints-api.reachu.io/qa-api',
          'enableMockData': true,
          'skipAuthTests': false,
        };
      case 'staging':
        return {
          'apiBaseUrl': 'https://paints-api.reachu.io/staging-api',
          'enableMockData': false,
          'skipAuthTests': false,
        };
      case 'production':
        return {
          'apiBaseUrl': 'https://paints-api.reachu.io/api',
          'enableMockData': false,
          'skipAuthTests': true, // Don't run auth tests in production
        };
      default:
        return {
          'apiBaseUrl': 'https://paints-api.reachu.io/qa-api',
          'enableMockData': true,
          'skipAuthTests': false,
        };
    }
  }
  
  /// Test suite configuration
  static Map<String, bool> get testSuiteEnabled => {
    'auth': true,
    'navigation': true,
    'projects': true,
    'palettes': true,
    'inventory': true,
    'wishlist': true,
    'offline': testOfflineFunctionality,
    'performance': testPerformance,
  };
  
  /// Logging levels
  static const String logLevel = 'INFO'; // DEBUG, INFO, WARN, ERROR
  
  /// Screenshot configuration
  static const bool screenshotOnFailure = true;
  static const bool screenshotOnSuccess = false;
  static const String screenshotPath = 'screenshots/';
  
  /// Parallel execution
  static const bool enableParallelExecution = false; // Disable for now
  static const int maxParallelTests = 2;
}

