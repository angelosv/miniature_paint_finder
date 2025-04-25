import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:miniature_paint_finder/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

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
  static const String notImplemented = 'not-implemented';
  static const String platformNotSupported = 'platform-not-supported';
}

/// Authentication provider types
enum AuthProvider { email, google, apple, phone, custom }

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

  /// Sign in with Apple
  Future<User> signInWithApple();

  /// Sign in with custom token
  Future<User> signInWithCustomToken(String token);

  /// Sign in with phone
  Future<void> signInWithPhone();

  /// Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
  });

  /// Verify code
  Future<void> verifyCode({
    required String verificationId,
    required String code,
  });

  /// Check if a provider is available on the current platform
  bool isProviderAvailable(AuthProvider provider);

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
      // Check for existing Firebase Auth session
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // User is already signed in
        _currentUser = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          createdAt: DateTime.now(), // We don't have the actual creation date
          lastLoginAt: DateTime.now(),
          authProvider: _getAuthProvider(firebaseUser),
        );
      } else {
        _currentUser = null;
      }

      // Listen to auth state changes
      firebase.FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
        if (firebaseUser != null) {
          _currentUser = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            phoneNumber: firebaseUser.phoneNumber,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            authProvider: _getAuthProvider(firebaseUser),
          );
        } else {
          _currentUser = null;
        }
        _authStateController.add(_currentUser);
      });

      _authStateController.add(_currentUser);
    } catch (e) {
      print('Error initializing auth service: $e');
      throw AuthException(
        AuthErrorCode.unknown,
        'Failed to initialize auth service: $e',
      );
    }
  }

  // Helper method to determine auth provider
  String _getAuthProvider(firebase.User user) {
    if (user.providerData.isEmpty) return 'unknown';

    final provider = user.providerData[0].providerId;
    switch (provider) {
      case 'google.com':
        return 'google';
      case 'apple.com':
        return 'apple';
      case 'password':
        return 'email';
      case 'phone':
        return 'phone';
      default:
        return provider;
    }
  }

  /// Sign in with email and password
  @override
  Future<User> signInWithEmailPassword(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');

      // Validate email and password
      _validateCredentials(email, password);

      // Sign in with Firebase
      final userCredential = await firebase.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print('Firebase sign in successful');
      print('User ID: ${userCredential.user?.uid}');
      print('User Email: ${userCredential.user?.email}');
      print('User Display Name: ${userCredential.user?.displayName}');

      // Convert Firebase user to our User model
      _currentUser = User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email ?? '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'email',
      );

      _authStateController.add(_currentUser);

      return _currentUser!;
    } on firebase.FirebaseAuthException catch (e) {
      print('Firebase Auth Error:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Stack trace: ${e.stackTrace}');

      switch (e.code) {
        case 'user-not-found':
          throw AuthException(
            AuthErrorCode.userNotFound,
            'No user found with this email address',
          );
        case 'wrong-password':
          throw AuthException(
            AuthErrorCode.wrongPassword,
            'Wrong password provided',
          );
        case 'invalid-email':
          throw AuthException(
            AuthErrorCode.invalidEmail,
            'Invalid email address',
          );
        default:
          throw AuthException(
            AuthErrorCode.unknown,
            'Firebase authentication failed: ${e.message}',
          );
      }
    } catch (e) {
      print('General error during sign in:');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
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

      // Create user with Firebase Auth
      final userCredential = await firebase.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update the user's display name
      await userCredential.user!.updateDisplayName(name);

      // Convert Firebase user to our User model
      _currentUser = User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'email',
      );

      _authStateController.add(_currentUser);
      return _currentUser!;
    } on firebase.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException(
            AuthErrorCode.emailAlreadyInUse,
            'This email is already in use',
          );
        case 'weak-password':
          throw AuthException(
            AuthErrorCode.weakPassword,
            'Password is too weak',
          );
        case 'invalid-email':
          throw AuthException(
            AuthErrorCode.invalidEmail,
            'Invalid email address',
          );
        default:
          throw AuthException(
            AuthErrorCode.unknown,
            'Account creation failed: ${e.message}',
          );
      }
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
      // Sign out from Firebase
      await firebase.FirebaseAuth.instance.signOut();

      // Try to sign out from Google if available
      try {
        await GoogleSignIn().signOut();
      } catch (e) {
        // Ignore errors from Google sign out
        print('Error signing out from Google: $e');
      }

      // Clear local user data
      _currentUser = null;
      _authStateController.add(null);
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

      // Send password reset email with Firebase
      await firebase.FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Success - no return needed
    } on firebase.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw AuthException(
            AuthErrorCode.userNotFound,
            'No user found with this email address',
          );
        case 'invalid-email':
          throw AuthException(
            AuthErrorCode.invalidEmail,
            'Invalid email address',
          );
        default:
          throw AuthException(
            AuthErrorCode.unknown,
            'Password reset failed: ${e.message}',
          );
      }
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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Access Token: ${googleAuth.accessToken}');
      print('ID Token: ${googleAuth.idToken}');

      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase.UserCredential userCredential = await firebase
          .FirebaseAuth
          .instance
          .signInWithCredential(credential);

      print('Firebase User ID: ${userCredential.user!.uid}');
      print('Firebase User Email: ${userCredential.user!.email}');
      print('Firebase User Display Name: ${userCredential.user!.displayName}');

      // Hacer el POST al endpoint para crear usuario
      try {
        final response = await http.post(
          Uri.parse('https://paints-api.reachu.io/auth/create-user'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'name': userCredential.user!.displayName,
          }),
        );

        final responseData = jsonDecode(response.body);
        if (responseData['executed'] == false) {
          throw AuthException(
            AuthErrorCode.unknown,
            responseData['message'] ?? 'Error creating user',
          );
        }

        print('Server response create-user: ${response.body}');
      } catch (e) {
        print('Error making POST request to create-user server: $e');
        throw AuthException(
          AuthErrorCode.unknown,
          e is AuthException ? e.message : 'Error creating user on server',
        );
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
      throw AuthException(
        AuthErrorCode.unknown,
        'Google authentication failed: $e',
      );
    }
  }

  /// Sign in with Apple
  @override
  Future<User> signInWithApple() async {
    try {
      print('Starting Apple Sign In process v2');

      // Generate nonce for Apple sign-in
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      print('Generated secure nonce: ${nonce.substring(0, 10)}...');

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('Received credential from Apple');
      print(
        'Authorization code available: ${appleCredential.authorizationCode != null}',
      );
      print(
        'Identity token available: ${appleCredential.identityToken != null}',
      );

      if (appleCredential.identityToken == null) {
        print('Error: Apple returned null identity token');
        throw AuthException(
          AuthErrorCode.unknown,
          'Apple sign in failed: No identity token returned',
        );
      }

      // Extract Apple provided details
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      final email = appleCredential.email;

      print(
        'Got data from Apple - Name: ${givenName ?? "null"} ${familyName ?? "null"}, Email: ${email ?? "null"}',
      );

      // Directly creating auth credential for Firebase
      final credential = firebase.OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      print('Created Firebase credential, attempting sign in');

      // Sign in with Firebase
      final userCredential = await firebase.FirebaseAuth.instance
          .signInWithCredential(credential);

      print('Firebase sign in successful: ${userCredential.user?.uid}');

      // Get or update display name
      String displayName = 'User';
      // Use name from Apple credential if available
      if (givenName != null || familyName != null) {
        final parts =
            [
              givenName ?? '',
              familyName ?? '',
            ].where((name) => name.isNotEmpty).toList();

        if (parts.isNotEmpty) {
          displayName = parts.join(' ');

          // Update Firebase user profile if needed
          if (userCredential.user != null &&
              (userCredential.user!.displayName == null ||
                  userCredential.user!.displayName!.isEmpty)) {
            await userCredential.user!.updateDisplayName(displayName);
            print('Updated Firebase user display name to: $displayName');
          }
        }
      }
      // Use existing Firebase display name as fallback
      else if (userCredential.user?.displayName != null &&
          userCredential.user!.displayName!.isNotEmpty) {
        displayName = userCredential.user!.displayName!;
      }

      // Create User model
      _currentUser = User(
        id: userCredential.user!.uid,
        name: displayName,
        email: userCredential.user!.email ?? email ?? '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'apple',
      );

      _authStateController.add(_currentUser);

      print('Apple sign in completed successfully');
      return _currentUser!;
    } catch (e) {
      print('Apple Sign In Error: $e');
      if (e is SignInWithAppleAuthorizationException) {
        print(
          'SignInWithAppleAuthorizationException: ${e.code} - ${e.message}',
        );
        if (e.code == AuthorizationErrorCode.canceled) {
          throw AuthException(
            AuthErrorCode.cancelled,
            'Apple sign in was cancelled',
          );
        } else {
          throw AuthException(
            AuthErrorCode.unknown,
            'Apple sign in error: ${e.code} - ${e.message}',
          );
        }
      } else if (e is firebase.FirebaseAuthException) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
        throw AuthException(e.code, 'Firebase auth error: ${e.message}');
      } else if (e is AuthException) {
        rethrow;
      } else {
        throw AuthException(AuthErrorCode.unknown, 'Apple sign in failed: $e');
      }
    }
  }

  /// Sign in with custom token
  @override
  Future<User> signInWithCustomToken(String token) async {
    try {
      // Sign in with Firebase
      final userCredential = await firebase.FirebaseAuth.instance
          .signInWithCustomToken(token);

      // Convert Firebase user to our User model
      _currentUser = User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email ?? '',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'custom',
      );

      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      print('Error signing in with custom token: $e');
      throw AuthException(
        AuthErrorCode.unknown,
        'Failed to sign in with custom token: $e',
      );
    }
  }

  /// Sign in with phone
  @override
  Future<void> signInWithPhone() async {
    throw AuthException(
      AuthErrorCode.notImplemented,
      'Phone authentication is not fully implemented',
    );
  }

  /// Verify phone number
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
  }) async {
    throw AuthException(
      AuthErrorCode.notImplemented,
      'Phone verification is not fully implemented',
    );
  }

  /// Verify code
  @override
  Future<void> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    throw AuthException(
      AuthErrorCode.notImplemented,
      'Code verification is not fully implemented',
    );
  }

  /// Check if a provider is available on the current platform
  @override
  bool isProviderAvailable(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.email:
        return true; // Disponible en todas las plataformas
      case AuthProvider.google:
        return true; // Disponible en todas las plataformas
      case AuthProvider.apple:
        // Solo disponible en iOS, no en web ni macOS
        return defaultTargetPlatform == TargetPlatform.iOS;
      case AuthProvider.phone:
        return false; // No disponible en ninguna plataforma
      case AuthProvider.custom:
        return true;
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
        'Please provide an email address',
      );
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      throw AuthException(
        AuthErrorCode.invalidEmail,
        'Please provide a valid email address',
      );
    }

    if (password.isEmpty) {
      throw AuthException(
        AuthErrorCode.wrongPassword,
        'Please provide a password',
      );
    }
  }

  String _generateNonce() {
    // Este método genera un nonce seguro criptográficamente
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      32,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    // Este método genera un hash SHA-256 de una cadena de entrada
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _updateDisplayNameIfNeeded() async {
    // Este método actualiza el nombre de usuario si es necesario
    final user = firebase.FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != _currentUser?.name) {
      await user.updateDisplayName(_currentUser?.name);
    }
  }
}
