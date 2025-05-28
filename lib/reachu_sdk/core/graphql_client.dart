import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/graphql_config.dart';

/// A singleton GraphQL client for ReachU API
class ReachuGraphQLClient {
  static ReachuGraphQLClient? _instance;
  late final GraphQLClient _client;
  String? _authToken;

  /// Private constructor
  ReachuGraphQLClient._();

  /// Factory constructor to get the singleton instance
  factory ReachuGraphQLClient() {
    _instance ??= ReachuGraphQLClient._();
    return _instance!;
  }

  /// Initialize the client with optional auth token
  void initialize({String? authToken}) {
    _authToken = authToken;
    _setupClient();
  }

  /// Update the auth token
  void updateAuthToken(String token) {
    _authToken = token;
    _setupClient();
  }

  /// Get the GraphQL client instance
  GraphQLClient get client => _client;

  /// Setup the GraphQL client with proper configuration
  void _setupClient() {
    final httpLink = HttpLink(
      ReachuGraphQLConfig.baseUrl,
      defaultHeaders:
          _authToken != null
              ? ReachuGraphQLConfig.getHeadersWithAuth(_authToken!)
              : ReachuGraphQLConfig.defaultHeaders,
    );

    final errorLink = ErrorLink(
      onGraphQLError: (request, forward, response) {
        // Handle GraphQL errors
        print('GraphQL Error: ${response.errors}');
        return forward(request);
      },
      onException: (request, forward, exception) {
        // Handle network/other errors
        print('Network Error: $exception');
        return forward(request);
      },
    );

    final dedupeLink = DedupeLink();

    final transformLink = TransformLink(
      requestTransformer: (request) {
        // Add any request transformations here
        return request;
      },
      responseTransformer: (response) {
        // Add any response transformations here
        return response;
      },
    );

    _client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.from([errorLink, dedupeLink, transformLink, httpLink]),
    );
  }

  /// Execute a GraphQL query
  Future<QueryResult> query(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
  }) async {
    try {
      return await _client.query(
        QueryOptions(
          document: gql(document),
          variables: variables ?? const {},
          fetchPolicy: fetchPolicy ?? FetchPolicy.cacheFirst,
        ),
      );
    } catch (e) {
      print('Query Error: $e');
      rethrow;
    }
  }

  /// Execute a GraphQL mutation
  Future<QueryResult> mutate(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
  }) async {
    try {
      return await _client.mutate(
        MutationOptions(
          document: gql(document),
          variables: variables ?? const {},
          fetchPolicy: fetchPolicy ?? FetchPolicy.noCache,
        ),
      );
    } catch (e) {
      print('Mutation Error: $e');
      rethrow;
    }
  }

  /// Clear the cache
  Future<void> clearCache() async {
    await _client.cache.reset();
  }
}
