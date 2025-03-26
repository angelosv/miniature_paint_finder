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
  static const String notImplemented = 'not-implemented';
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

  /// Sign in with custom token
  @override
  Future<User> signInWithCustomToken(String token) async {
    try {
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
    try {
      // Crear un nuevo PhoneAuthProvider
      final phoneAuthProvider = firebase.PhoneAuthProvider();

      // Mostrar un diálogo para ingresar el número de teléfono
      // Nota: En una implementación real, esto debería ser manejado por la UI
      // y el número de teléfono debería ser pasado como parámetro
      final phoneNumber = '+1234567890'; // Este es un número de ejemplo

      // Verificar el número de teléfono
      await firebase.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Auto-verificación completada (Android)
          try {
            final userCredential = await firebase.FirebaseAuth.instance
                .signInWithCredential(credential);

            // Convertir el usuario de Firebase a nuestro modelo de Usuario
            _currentUser = User(
              id: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Phone User',
              email: userCredential.user!.email ?? '',
              phoneNumber: userCredential.user!.phoneNumber,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              authProvider: 'phone',
            );

            _authStateController.add(_currentUser);
          } catch (e) {
            print('Error en verificación automática: $e');
            throw AuthException(
              AuthErrorCode.unknown,
              'Error en verificación automática: $e',
            );
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          print('Error en verificación: ${e.code} - ${e.message}');
          throw AuthException(
            AuthErrorCode.unknown,
            'Error en verificación: ${e.message}',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          // Guardar el verificationId para usarlo cuando se ingrese el código
          // En una implementación real, esto debería ser manejado por la UI
          print('Código de verificación enviado');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Tiempo de espera para la auto-recuperación del código
          print('Tiempo de espera para recuperación automática');
        },
      );
    } catch (e) {
      print('Error en autenticación por teléfono: $e');
      throw AuthException(
        AuthErrorCode.unknown,
        'Error en autenticación por teléfono: $e',
      );
    }
  }

  /// Verify phone number
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
  }) async {
    try {
      print('Starting phone verification for: $phoneNumber');

      // Validate phone number format
      if (!RegExp(r'^\+[0-9]{10,15}$').hasMatch(phoneNumber)) {
        throw AuthException(
          AuthErrorCode.invalidEmail,
          'Please enter a valid phone number with country code (e.g., +1234567890)',
        );
      }

      // Clear Firebase cache
      try {
        await firebase.FirebaseAuth.instance.signOut();
        print('Firebase cache cleared');
      } catch (e) {
        print('Error clearing cache: $e');
      }

      // Verify Firebase Auth is initialized
      if (firebase.FirebaseAuth.instance == null) {
        throw AuthException(
          AuthErrorCode.unknown,
          'Firebase Auth is not properly initialized',
        );
      }

      // Verify phone number is not empty
      if (phoneNumber.trim().isEmpty) {
        throw AuthException(
          AuthErrorCode.unknown,
          'Phone number cannot be empty',
        );
      }

      // Attempt to verify phone number
      try {
        await firebase.FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (
            firebase.PhoneAuthCredential credential,
          ) async {
            print('Auto verification completed');
            try {
              final userCredential = await firebase.FirebaseAuth.instance
                  .signInWithCredential(credential);
              print(
                'User authenticated successfully: ${userCredential.user?.uid}',
              );

              _currentUser = User(
                id: userCredential.user!.uid,
                name: userCredential.user!.displayName ?? 'Phone User',
                email: userCredential.user!.email ?? '',
                phoneNumber: userCredential.user!.phoneNumber,
                createdAt: DateTime.now(),
                lastLoginAt: DateTime.now(),
                authProvider: 'phone',
              );

              _authStateController.add(_currentUser);
            } catch (e) {
              print('Error in auto verification: $e');
              print('Stack trace: ${StackTrace.current}');
              throw AuthException(
                AuthErrorCode.unknown,
                'Error in auto verification: $e',
              );
            }
          },
          verificationFailed: (firebase.FirebaseAuthException e) {
            print('Verification error:');
            print('Code: ${e.code}');
            print('Message: ${e.message}');
            print('Stack trace: ${e.stackTrace}');

            String errorMessage;
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = 'Invalid phone number';
                break;
              case 'too-many-requests':
                errorMessage =
                    'Too many attempts. Please wait a few minutes before trying again.';
                break;
              case 'operation-not-allowed':
                errorMessage =
                    'Phone authentication is not enabled in Firebase';
                break;
              case 'internal-error':
                errorMessage =
                    'Internal Firebase error. Please check Firebase configuration and ensure phone authentication is enabled.';
                break;
              default:
                errorMessage = e.message ?? 'Unknown verification error';
            }

            throw AuthException(AuthErrorCode.unknown, errorMessage);
          },
          codeSent: (String verificationId, int? resendToken) {
            print('Verification code sent');
            print('Verification ID: $verificationId');
            print('Resend Token: $resendToken');
            onCodeSent(verificationId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('Auto retrieval timeout');
            print('Verification ID: $verificationId');
          },
        );
      } catch (e) {
        print('Error calling verifyPhoneNumber:');
        print('Error: $e');
        print('Stack trace: ${StackTrace.current}');
        throw AuthException(
          AuthErrorCode.unknown,
          'Error starting phone verification: $e',
        );
      }
    } catch (e) {
      print('General error in phone authentication:');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');

      if (e is AuthException) {
        rethrow;
      }

      throw AuthException(
        AuthErrorCode.unknown,
        'Error in phone authentication: $e',
      );
    }
  }

  /// Verify code
  @override
  Future<void> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final userCredential = await firebase.FirebaseAuth.instance
          .signInWithCredential(credential);

      _currentUser = User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'Phone User',
        email: userCredential.user!.email ?? '',
        phoneNumber: userCredential.user!.phoneNumber,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        authProvider: 'phone',
      );

      _authStateController.add(_currentUser);
    } catch (e) {
      print('Error verificando código: $e');
      throw AuthException(
        AuthErrorCode.unknown,
        'Error verificando código: $e',
      );
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
