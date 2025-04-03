import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/data/api_endpoints.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service para realizar llamadas a la API
class ApiService {
  /// URL base para todas las llamadas API
  final String baseUrl;

  /// Cliente HTTP a utilizar
  final http.Client _client;

  /// Headers por defecto para todas las peticiones
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final FirebaseAuth _auth;

  /// Constructor del servicio API
  ApiService({required this.baseUrl, http.Client? client, FirebaseAuth? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? FirebaseAuth.instance;

  /// Realiza una petición GET
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    print('🌐 ApiService.get() called with endpoint: $endpoint');
    try {
      final token = await _auth.currentUser?.getIdToken();
      print('🔑 Firebase token: ${token != null ? 'Present' : 'Missing'}');

      final url = Uri.parse('$baseUrl$endpoint');
      print('🔗 Full URL: $url');

      final requestHeaders = {
        ..._defaultHeaders,
        ...?headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };
      print('📤 Headers: $requestHeaders');

      final response = await _client.get(url, headers: requestHeaders);

      print('📥 Response status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final parsedResponse = _handleResponse(response);
      print('📥 Parsed response: $parsedResponse');

      return parsedResponse;
    } catch (e) {
      print('❌ Error in ApiService.get(): $e');
      rethrow;
    }
  }

  /// Realiza una petición POST
  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          ..._defaultHeaders,
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform POST request: $e');
    }
  }

  /// Realiza una petición PUT
  Future<dynamic> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          ..._defaultHeaders,
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform PUT request: $e');
    }
  }

  /// Realiza una petición DELETE
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          ..._defaultHeaders,
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform DELETE request: $e');
    }
  }

  /// Maneja la respuesta HTTP y maneja errores comunes
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Authentication required');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 404) {
      throw Exception('Not found: The requested resource does not exist');
    } else {
      throw Exception(
        'API Error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
  }
}
