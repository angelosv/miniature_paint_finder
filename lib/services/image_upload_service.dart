import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  static const String _baseUrl = 'https://paints-api.reachu.io/api';

  Future<String> uploadImage(File imageFile) async {
    try {
      String token = '';
      // Get Firebase token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        token = await user.getIdToken() ?? '';
      }

      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/image/upload-file'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Add authentication token
      request.headers['Authorization'] = 'Bearer $token';

      // Send request
      var response = await request.send();
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