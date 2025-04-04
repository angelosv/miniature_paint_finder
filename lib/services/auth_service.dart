import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:miniature_paint_finder/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

// Verifica si estamos en Android
bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

// Verifica si estamos en iOS
bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

// Verifica si estamos en macOS
bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

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
      // En Android, usamos la autenticación simulada
      if (_isAndroid) {
        print('Using mock auth for Android');
        _currentUser = null;
        _authStateController.add(_currentUser);
        return;
      }

      // Para otras plataformas, usamos Firebase Auth
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

      // En Android, usamos autenticación simulada
      if (_isAndroid) {
        print('Using mock auth for Android');
        // Simular inicio de sesión exitoso
        await Future.delayed(const Duration(seconds: 1));

        // Comprobar credenciales de demo
        if (email == 'demo@example.com' && password == 'password123') {
          _currentUser = User(
            id: 'android-mock-user-id',
            name: 'Android Demo User',
            email: email,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            authProvider: 'email',
          );
          _authStateController.add(_currentUser);
          return _currentUser!;
        } else {
          throw AuthException(
            AuthErrorCode.wrongPassword,
            'Invalid email or password',
          );
        }
      }

      // Para otras plataformas, usamos Firebase Auth
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

      // En Android, usamos autenticación simulada
      if (_isAndroid) {
        print('Using mock auth for Android');
        // Simular retraso de red
        await Future.delayed(const Duration(seconds: 1));

        // Simular el registro
        _currentUser = User(
          id: 'android-mock-user-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          authProvider: 'email',
        );
        _authStateController.add(_currentUser);
        return _currentUser!;
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
      // En Android, simplemente reseteamos el usuario
      if (_isAndroid) {
        print('Using mock auth for Android');
        _currentUser = null;
        _authStateController.add(_currentUser);
        return;
      }

      // Sign out from Firebase
      await firebase.FirebaseAuth.instance.signOut();

      // Sign out from Google
      await GoogleSignIn().signOut();

      // Clear local user data
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

      // En Android, simplemente simulamos el reseteo
      if (_isAndroid) {
        print('Using mock auth for Android');
        await Future.delayed(const Duration(seconds: 1));
        return;
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
      // En Android, usamos autenticación simulada
      if (_isAndroid) {
        print('Using mock auth for Android');
        // Simular inicio de sesión con Google
        await Future.delayed(const Duration(seconds: 1));

        _currentUser = User(
          id: 'android-mock-google-user-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Android Google User',
          email: 'google@example.com',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          authProvider: 'google',
        );
        _authStateController.add(_currentUser);
        return _currentUser!;
      }

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
      // Verificar si el método es compatible con la plataforma actual
      if (!isProviderAvailable(AuthProvider.apple)) {
        throw AuthException(
          AuthErrorCode.platformNotSupported,
          'Sign in with Apple is not available on this platform',
        );
      }

      // En Android, lanzamos una excepción ya que no está soportado
      if (_isAndroid) {
        throw AuthException(
          AuthErrorCode.platformNotSupported,
          'Sign in with Apple is not available on Android',
        );
      }

      // Ejecutamos el Sign In con Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print('Apple Sign In successful');
      print('Authorization Code: ${appleCredential.authorizationCode}');
      print('Identity Token: ${appleCredential.identityToken}');

      // Crear un credential para Firebase
      final oauthCredential = firebase.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Iniciar sesión en Firebase con el credential de Apple
      final userCredential = await firebase.FirebaseAuth.instance
          .signInWithCredential(oauthCredential);

      print('Firebase User ID: ${userCredential.user!.uid}');

      // Determinar el nombre del usuario
      String name = 'Apple User';
      if (appleCredential.givenName != null &&
          appleCredential.familyName != null) {
        name = '${appleCredential.givenName} ${appleCredential.familyName}';
      } else if (userCredential.user!.displayName != null) {
        name = userCredential.user!.displayName!;
      }

      // Determinar el email del usuario
      String email = '';
      if (appleCredential.email != null) {
        email = appleCredential.email!;
      } else if (userCredential.user!.email != null) {
        email = userCredential.user!.email!;
      }

      print('User Name: $name');
      print('User Email: $email');

      // Hacer el POST al endpoint para crear usuario
      try {
        final response = await http.post(
          Uri.parse('https://paints-api.reachu.io/auth/create-user'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': userCredential.user!.uid,
            'email': email,
            'name': name,
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

      // Convertir el usuario de Firebase a nuestro modelo de User
      _currentUser = User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'apple',
      );

      _authStateController.add(_currentUser);

      return _currentUser!;
    } catch (e) {
      print('Error in Apple Sign In: $e');

      // Si el usuario canceló el inicio de sesión
      if (e.toString().contains('canceled')) {
        throw AuthException(
          AuthErrorCode.cancelled,
          'Apple sign in was cancelled',
        );
      }

      // Si es una AuthException personalizada, reenviarla
      if (e is AuthException) {
        rethrow;
      }

      // Para cualquier otro error
      throw AuthException(
        AuthErrorCode.unknown,
        'Apple authentication failed: $e',
      );
    }
  }

  /// Sign in with custom token
  @override
  Future<User> signInWithCustomToken(String token) async {
    try {
      // En Android, usamos autenticación simulada
      if (_isAndroid) {
        print('Using mock auth for Android');
        await Future.delayed(const Duration(seconds: 1));

        _currentUser = User(
          id: 'android-mock-token-user-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Android Token User',
          email: 'token@example.com',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          authProvider: 'custom',
        );
        _authStateController.add(_currentUser);
        return _currentUser!;
      }

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
    if (_isAndroid) {
      print('Using mock auth for Android');
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = User(
        id: 'android-mock-phone-user-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Android Phone User',
        email: '',
        phoneNumber: '+1234567890',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'phone',
      );
      _authStateController.add(_currentUser);
      return;
    }

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
    if (_isAndroid) {
      print('Using mock auth for Android');
      await Future.delayed(const Duration(seconds: 1));

      // Simular envío de código con un ID de verificación mock
      onCodeSent('android-mock-verification-id', 123456);
      return;
    }

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
    if (_isAndroid) {
      print('Using mock auth for Android');
      await Future.delayed(const Duration(seconds: 1));

      // Verificar que el código sea el esperado (para pruebas)
      if (code == '123456') {
        _currentUser = User(
          id: 'android-mock-phone-verified-user',
          name: 'Android Phone User',
          email: '',
          phoneNumber: '+1234567890',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          authProvider: 'phone',
        );
        _authStateController.add(_currentUser);
        return;
      } else {
        throw AuthException(AuthErrorCode.unknown, 'Invalid verification code');
      }
    }

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
        // Sólo disponible en iOS, macOS y web
        return _isIOS || _isMacOS || kIsWeb;
      case AuthProvider.phone:
        return true; // Disponible en todas las plataformas
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
}
