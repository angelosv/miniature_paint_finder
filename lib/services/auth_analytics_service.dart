import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// Wrapper para el servicio de autenticación que agrega tracking de eventos con Mixpanel
class AuthAnalyticsService {
  final IAuthService _authService;
  final MixpanelService _mixpanel = MixpanelService.instance;

  AuthAnalyticsService(this._authService);

  /// Trackea un evento de inicio de sesión exitoso
  void _trackSuccessfulLogin(User? user, String method) {
    _mixpanel.trackEvent('Login', {'method': method, 'success': true});

    // Identificar al usuario en Mixpanel
    if (user != null) {
      _mixpanel.identify(user.uid);
    }
  }

  /// Trackea un evento de inicio de sesión fallido
  void _trackFailedLogin(String method, String error) {
    _mixpanel.trackEvent('Login', {
      'method': method,
      'success': false,
      'error': error,
    });
  }

  /// Wrapper para signInWithEmailAndPassword con tracking
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
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

  /// Wrapper para createUserWithEmailAndPassword con tracking
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email,
        password,
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
    _mixpanel.logout();
    await _authService.signOut();
  }

  /// Delegación simple de otros métodos al servicio subyacente
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  User? get currentUser => _authService.currentUser;

  // Agrega más delegaciones según sea necesario para implementar IAuthService completo
}
