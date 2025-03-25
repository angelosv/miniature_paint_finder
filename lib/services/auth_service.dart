import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException: [$code] $message';
}

/// Error codes for authentication
class AuthErrorCode {
  static const String invalidEmail = 'invalid-email';
  static const String wrongPassword = 'wrong-password';
  static const String userNotFound = 'user-not-found';
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String weakPassword = 'weak-password';
  static const String networkError = 'network-error';
  static const String tooManyRequests = 'too-many-requests';
  static const String unknown = 'unknown';
  static const String cancelled = 'cancelled';
}

/// Abstract interface for authentication service
abstract class IAuthService {
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Current authenticated user
  User? get currentUser;

  /// Initialize the service
  Future<void> init();

  /// Sign in with email and password
  Future<User> signInWithEmailPassword(String email, String password);

  /// Sign up with email, password and name
  Future<User> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  );

  /// Sign out the current user
  Future<void> signOut();

  /// Request password reset
  Future<void> resetPassword(String email);

  /// Sign in with Google
  Future<User> signInWithGoogle();

  /// Dispose resources
  void dispose();
}

/// Implementation of the authentication service
/// This class handles user authentication operations
class AuthService implements IAuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor for singleton pattern
  factory AuthService() => _instance;

  /// Private internal constructor
  AuthService._internal();

  // Stream controller for auth state changes
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Current user
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  /// Service initialization
  @override
  Future<void> init() async {
    try {
      // Check for stored credentials
      // In real app, this would check secure storage
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo, we'll start with no user logged in
      _currentUser = null;
      _authStateController.add(_currentUser);
    } catch (e) {
      throw AuthException(
        AuthErrorCode.unknown,
        'Failed to initialize auth service: $e',
      );
    }
  }

  /// Sign in with email and password
  @override
  Future<User> signInWithEmailPassword(String email, String password) async {
    try {
      // Validate email and password
      _validateCredentials(email, password);

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo, validate against demo account
      if (email != User.demoUser.email &&
          email != 'demo@miniaturepaintfinder.com') {
        throw AuthException(
          AuthErrorCode.userNotFound,
          'No user found with this email address',
        );
      }

      // Password check (would be done server-side in real app)
      if (password != 'password123') {
        throw AuthException(AuthErrorCode.wrongPassword, 'Incorrect password');
      }

      // In real app, this would make an API call
      _currentUser = User.demoUser;
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(AuthErrorCode.unknown, 'Authentication failed: $e');
    }
  }

  /// Sign up with email, password and name
  @override
  Future<User> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Validate fields
      if (name.isEmpty) {
        throw AuthException(AuthErrorCode.unknown, 'Name is required');
      }

      _validateCredentials(email, password);

      // Check password strength
      if (password.length < 8) {
        throw AuthException(
          AuthErrorCode.weakPassword,
          'Password should be at least 8 characters',
        );
      }

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // In real app, this would make an API call to create account

      // Check if email is already in use (demo: check against demo email)
      if (email == User.demoUser.email) {
        throw AuthException(
          AuthErrorCode.emailAlreadyInUse,
          'This email is already in use',
        );
      }

      final newUser = User(
        id: 'new-user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'email',
      );

      _currentUser = newUser;
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(AuthErrorCode.unknown, 'Account creation failed: $e');
    }
  }

  /// Sign out the current user
  @override
  Future<void> signOut() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In real app, this would clear tokens, etc.
      _currentUser = null;
      _authStateController.add(_currentUser);
    } catch (e) {
      throw AuthException(AuthErrorCode.unknown, 'Sign out failed: $e');
    }
  }

  /// Request password reset
  @override
  Future<void> resetPassword(String email) async {
    try {
      // Validate email
      if (email.isEmpty) {
        throw AuthException(
          AuthErrorCode.invalidEmail,
          'Please provide an email address',
        );
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
        throw AuthException(
          AuthErrorCode.invalidEmail,
          'Please provide a valid email address',
        );
      }

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // In real app, this would trigger a password reset email
      // For demo, we just check if it's the demo email
      if (email != User.demoUser.email &&
          email != 'demo@miniaturepaintfinder.com') {
        throw AuthException(
          AuthErrorCode.userNotFound,
          'No user found with this email address',
        );
      }

      // Success - no return needed
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(AuthErrorCode.unknown, 'Password reset failed: $e');
    }
  }

  /// Sign in with Google
  @override
  Future<User> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw AuthException(
          AuthErrorCode.cancelled,
          'Google sign in was cancelled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Access Token: ${googleAuth.accessToken}');
      print('ID Token: ${googleAuth.idToken}');

      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase.UserCredential userCredential = 
          await firebase.FirebaseAuth.instance.signInWithCredential(credential);
      
      print('Firebase User ID: ${userCredential.user!.uid}');
      print('Firebase User Email: ${userCredential.user!.email}');
      print('Firebase User Display Name: ${userCredential.user!.displayName}');

      // Hacer el POST al endpoint para crear usuario
      try {
        final response = await http.post(
          Uri.parse('https://paints-api.reachu.io/auth/create-user'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'name': userCredential.user!.displayName,
          }),
        );

        print('Respuesta del servidor create-user: ${response.body}');
      } catch (e) {
        print('Error al hacer POST al servidor create-user: $e');
      }
      
      // Convert Firebase user to our User model
      _currentUser = User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'Google User',
        email: userCredential.user!.email ?? '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'google',
      );
      
      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      print('Error en Google Sign In: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(AuthErrorCode.unknown, 'Google authentication failed: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _authStateController.close();
  }

  /// Helper method to validate credentials
  void _validateCredentials(String email, String password) {
    if (email.isEmpty) {
      throw AuthException(
        AuthErrorCode.invalidEmail,
        'Email address is required',
      );
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      throw AuthException(
        AuthErrorCode.invalidEmail,
        'Please provide a valid email address',
      );
    }

    if (password.isEmpty) {
      throw AuthException(AuthErrorCode.wrongPassword, 'Password is required');
    }
  }
}
