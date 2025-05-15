import 'package:flutter/foundation.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// A service that tracks authentication-related events
class AuthAnalyticsService {
  static final AuthAnalyticsService _instance =
      AuthAnalyticsService._internal();
  final MixpanelService _analytics = MixpanelService();

  /// Factory constructor for singleton pattern
  factory AuthAnalyticsService() => _instance;

  /// Private constructor
  AuthAnalyticsService._internal();

  /// Track successful login event
  void trackLogin(String provider, String userId) {
    try {
      debugPrint(
        '🔍 AuthAnalytics: User logged in - ID: $userId, Provider: $provider',
      );

      // Identify the user first
      _analytics.identify(userId, {
        'auth_provider': provider,
        'last_login': DateTime.now().toIso8601String(),
      });

      // Track the login event
      _analytics.trackEvent('User Login', {
        'auth_provider': provider,
        'success': true,
      });
    } catch (e) {
      debugPrint('⚠️ AuthAnalytics Error: $e');
    }
  }

  /// Track successful registration event
  void trackRegistration(String provider, String userId) {
    try {
      debugPrint(
        '🔍 AuthAnalytics: User registered - ID: $userId, Provider: $provider',
      );

      // Identify the user first
      _analytics.identify(userId, {
        'auth_provider': provider,
        'signup_date': DateTime.now().toIso8601String(),
      });

      // Track the signup event
      _analytics.trackEvent('User Registration', {
        'auth_provider': provider,
        'success': true,
      });
    } catch (e) {
      debugPrint('⚠️ AuthAnalytics Error: $e');
    }
  }

  /// Track login/signup failure
  void trackAuthFailure(String provider, String reason) {
    try {
      debugPrint(
        '🔍 AuthAnalytics: Auth failed - Provider: $provider, Reason: $reason',
      );

      // Track the failure event
      _analytics.trackEvent('Auth Failed', {
        'auth_provider': provider,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('⚠️ AuthAnalytics Error: $e');
    }
  }

  /// Track logout event
  void trackLogout() {
    try {
      debugPrint('🔍 AuthAnalytics: User logged out');

      // Track the logout event
      _analytics.trackEvent('User Logout');

      // Reset user data
      _analytics.reset();
    } catch (e) {
      debugPrint('⚠️ AuthAnalytics Error: $e');
    }
  }

  /// Track password reset request
  void trackPasswordReset(String email) {
    try {
      // Mask email for privacy
      final maskedEmail = _maskEmail(email);

      debugPrint(
        '🔍 AuthAnalytics: Password reset requested - Email: $maskedEmail',
      );

      // Track the password reset event
      _analytics.trackEvent('Password Reset Requested', {
        'email_domain': email.split('@').last,
      });
    } catch (e) {
      debugPrint('⚠️ AuthAnalytics Error: $e');
    }
  }

  /// Mask email for privacy
  String _maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return '***@***.***';

      final name = parts[0];
      final domain = parts[1];

      String maskedName;
      if (name.length <= 2) {
        maskedName = '*' * name.length;
      } else {
        maskedName = name.substring(0, 2) + '*' * (name.length - 2);
      }

      return '$maskedName@$domain';
    } catch (e) {
      return '***@***.***';
    }
  }
}
