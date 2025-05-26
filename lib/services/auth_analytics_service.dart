import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';
import 'package:miniature_paint_finder/models/user.dart';

/// Wrapper para el servicio de autenticación que agrega tracking de eventos con Mixpanel
class AuthAnalyticsService {
  final IAuthService _authService;
  final MixpanelService _mixpanel = MixpanelService.instance;

  AuthAnalyticsService(this._authService);

  /// Trackea un evento de inicio de sesión exitoso con identificación completa del usuario
  void _trackSuccessfulLogin(User? user, String method) {
    _mixpanel.trackEvent('Login', {'method': method, 'success': true});

    // Identificar al usuario en Mixpanel con información completa
    if (user != null) {
      // Determinar si es un usuario nuevo (primera vez que se identifica)
      final isNewUser =
          method.contains('New User') || method.contains('Registration');

      // Usar identificación completa en lugar de la básica
      _mixpanel.identifyUserWithDetails(
        userId: user.id,
        name: user.name.isNotEmpty ? user.name : null,
        email: user.email.isNotEmpty ? user.email : null,
        phoneNumber: user.phoneNumber,
        authProvider: user.authProvider,
        isNewUser: isNewUser,
        additionalUserProperties: {
          'last_login_method': method,
          'creation_time': user.createdAt.toIso8601String(),
          'last_login_time': user.lastLoginAt?.toIso8601String(),
          'profile_image': user.profileImage,
          'has_preferences': user.preferences != null,
          'preferences_count': user.preferences?.length ?? 0,
          'is_guest_user': user.authProvider == 'guest',
        },
      );

      // Trackear métricas de uso
      _mixpanel.incrementUserProperty('total_logins', 1.0);

      // Actualizar última fecha de login
      _mixpanel.updateUserProperty(
        'last_login_at',
        DateTime.now().toIso8601String(),
      );

      // Trackear el método de login más reciente
      _mixpanel.updateUserProperty('last_login_method', method);
    }
  }

  /// Trackea un evento de inicio de sesión fallido
  void _trackFailedLogin(String method, String error) {
    _mixpanel.trackEvent('Login', {
      'method': method,
      'success': false,
      'error': error,
      'error_type': _categorizeAuthError(error),
    });
  }

  /// Categoriza los errores de autenticación para mejor análisis
  String _categorizeAuthError(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('user-not-found') ||
        errorLower.contains('user not found')) {
      return 'user_not_found';
    } else if (errorLower.contains('wrong-password') ||
        errorLower.contains('invalid-credential')) {
      return 'wrong_credentials';
    } else if (errorLower.contains('too-many-requests')) {
      return 'rate_limited';
    } else if (errorLower.contains('network') ||
        errorLower.contains('connection')) {
      return 'network_error';
    } else if (errorLower.contains('cancelled')) {
      return 'user_cancelled';
    } else if (errorLower.contains('invalid-email')) {
      return 'invalid_email';
    } else if (errorLower.contains('weak-password')) {
      return 'weak_password';
    } else if (errorLower.contains('email-already-in-use')) {
      return 'email_in_use';
    }

    return 'unknown_error';
  }

  /// Wrapper para signInWithEmailAndPassword con tracking
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final user = await _authService.signInWithEmailPassword(email, password);
      _trackSuccessfulLogin(user, 'Email/Password');
      return user;
    } catch (e) {
      _trackFailedLogin('Email/Password', e.toString());
      rethrow; // Permitir que el error se propague para su manejo
    }
  }

  /// Wrapper para signInWithGoogle con tracking
  Future<User?> signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      _trackSuccessfulLogin(user, 'Google');
      return user;
    } catch (e) {
      _trackFailedLogin('Google', e.toString());
      rethrow;
    }
  }

  /// Wrapper para signInWithApple con tracking
  Future<User?> signInWithApple() async {
    try {
      final user = await _authService.signInWithApple();
      _trackSuccessfulLogin(user, 'Apple');
      return user;
    } catch (e) {
      _trackFailedLogin('Apple', e.toString());
      rethrow;
    }
  }

  /// Wrapper para signUpWithEmailPassword con tracking
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final user = await _authService.signUpWithEmailPassword(
        email,
        password,
        name,
      );
      _mixpanel.trackEvent('Registration', {
        'method': 'Email/Password',
        'success': true,
      });
      _trackSuccessfulLogin(user, 'Email/Password - New User');
      return user;
    } catch (e) {
      _mixpanel.trackEvent('Registration', {
        'method': 'Email/Password',
        'success': false,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Wrapper para signOut con tracking
  Future<void> signOut() async {
    // Trackear el evento de logout con información del usuario actual
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _mixpanel.trackEvent('Logout', {
        'user_id': currentUser.id,
        'auth_provider': currentUser.authProvider,
        'session_duration_minutes': _calculateSessionDuration(currentUser),
      });
    }

    _mixpanel.logout();
    await _authService.signOut();
  }

  /// Calcular duración de la sesión en minutos
  int? _calculateSessionDuration(User user) {
    if (user.lastLoginAt != null) {
      final duration = DateTime.now().difference(user.lastLoginAt!);
      return duration.inMinutes;
    }
    return null;
  }

  /// Actualizar perfil de usuario existente en Mixpanel
  Future<void> updateUserProfile(User user) async {
    await _mixpanel.identifyUserWithDetails(
      userId: user.id,
      name: user.name.isNotEmpty ? user.name : null,
      email: user.email.isNotEmpty ? user.email : null,
      phoneNumber: user.phoneNumber,
      authProvider: user.authProvider,
      isNewUser: false,
      additionalUserProperties: {
        'profile_updated_at': DateTime.now().toIso8601String(),
        'creation_time': user.createdAt.toIso8601String(),
        'last_login_time': user.lastLoginAt?.toIso8601String(),
        'profile_image': user.profileImage,
        'has_preferences': user.preferences != null,
        'preferences_count': user.preferences?.length ?? 0,
        'is_guest_user': user.authProvider == 'guest',
      },
    );
  }

  /// Trackear cuando un usuario cambia su configuración
  Future<void> trackUserPreferenceChange(
    String preferenceName,
    dynamic oldValue,
    dynamic newValue,
  ) async {
    _mixpanel.trackEvent('User Preference Changed', {
      'preference_name': preferenceName,
      'old_value': oldValue?.toString(),
      'new_value': newValue?.toString(),
    });
  }

  /// Trackear eventos relacionados con usuarios guest
  Future<void> trackGuestUserActivity(
    String activity, {
    Map<String, dynamic>? additionalData,
  }) async {
    _mixpanel.trackEvent('Guest User Activity', {
      'activity': activity,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Wrapper para continueAsGuest con tracking mejorado
  Future<User?> continueAsGuest() async {
    try {
      final user = await _authService.continueAsGuest();

      // Identificar al usuario guest
      if (user != null) {
        _mixpanel.identifyUserWithDetails(
          userId: user.id,
          name: 'Guest User',
          email: '',
          authProvider: 'guest',
          isNewUser: true,
          additionalUserProperties: {
            'guest_session_start': DateTime.now().toIso8601String(),
            'is_guest_user': true,
          },
        );

        _mixpanel.trackEvent('Guest Login', {
          'guest_user_id': user.id,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return user;
    } catch (e) {
      _mixpanel.trackEvent('Guest Login Failed', {'error': e.toString()});
      rethrow;
    }
  }

  /// Delegación simple de otros métodos al servicio subyacente
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  User? get currentUser => _authService.currentUser;
}
