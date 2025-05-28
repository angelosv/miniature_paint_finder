/// Configuration for GraphQL client
class ReachuGraphQLConfig {
  /// Base URL for the GraphQL API
  static const String baseUrl = 'https://api.reachu.com/graphql';

  /// Default headers for all requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get headers with authentication token
  static Map<String, String> getHeadersWithAuth(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  /// Default timeout duration for requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Default retry count for failed requests
  static const int defaultRetryCount = 3;

  /// Default retry delay for failed requests
  static const Duration defaultRetryDelay = Duration(seconds: 1);
}
