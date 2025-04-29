// This file contains stub implementations for disabled authentication methods
// to prevent runtime errors when certain packages are commented out or unavailable.

import 'package:miniature_paint_finder/services/auth_service.dart';

/// Stub implementation of Apple sign-in classes
class SignInWithApple {
  /// Stub method that always throws an exception
  static Future<AppleCredential> getAppleIDCredential({
    required List<dynamic> scopes,
    String? nonce,
    String? state,
    String? webAuthenticationOptions,
  }) async {
    throw AuthException(
      AuthErrorCode.platformNotSupported,
      'Sign in with Apple is not available in this build',
    );
  }
}

/// Stub Apple ID Authorization Scopes
class AppleIDAuthorizationScopes {
  static const String email = 'email';
  static const String fullName = 'fullName';
}

/// Stub Apple Sign In Authorization Exception
class SignInWithAppleAuthorizationException implements Exception {
  final AuthorizationErrorCode code;
  final String message;

  SignInWithAppleAuthorizationException(this.code, this.message);
}

/// Stub Authorization Error Codes
class AuthorizationErrorCode {
  static const canceled = 1000;
}

/// Stub Apple Credential
class AppleCredential {
  final String? identityToken;
  final String? authorizationCode;
  final String? givenName;
  final String? familyName;
  final String? email;

  AppleCredential({
    this.identityToken,
    this.authorizationCode,
    this.givenName,
    this.familyName,
    this.email,
  });
}
