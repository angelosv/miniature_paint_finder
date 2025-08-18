import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/utils/env.dart';

class ImageUploadService {
  /// Base URL for API endpoints
  final String baseUrl;

  /// HTTP client for making requests (injected for testing)
  final http.Client _client;

  /// FirebaseAuth instance (injected for testing)
  final FirebaseAuth _auth;

  /// Constructs the service, allowing dependency injection of baseUrl, client, and auth
  ImageUploadService({String? baseUrl, http.Client? client, FirebaseAuth? auth})
    : baseUrl = baseUrl ?? Env.apiBaseUrl,
      _client = client ?? http.Client(),
      _auth = auth ?? FirebaseAuth.instance;

  Future<String> uploadImage(File imageFile) async {
    try {
      String token = '';
      // Get Firebase token
      final user = _auth.currentUser;
      if (user != null) {
        token = await user.getIdToken() ?? '';
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/image/upload-file'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add authentication token
      request.headers['Authorization'] = 'Bearer $token';

      // Send request
      var response = await _client.send(request);
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['url'] as String;
      } else {
        throw Exception('Error uploading image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
