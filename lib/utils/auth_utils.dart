import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';

/// Utility class for authentication-related helpers
class AuthUtils {
  /// Check if a feature requires authentication and handle accordingly
  ///
  /// Returns true if the user can access the feature, false otherwise.
  /// If the user is a guest and the feature requires authentication,
  /// it will show a dialog prompting them to sign in.
  static Future<bool> checkFeatureAccess(
    BuildContext context, {
    bool requireAuth = true,
  }) async {
    if (!requireAuth) {
      // Feature doesn't require authentication, allow access
      return true;
    }

    final authService = Provider.of<IAuthService>(context, listen: false);

    // Check if user is authenticated (non-guest)
    if (authService.currentUser != null && !authService.isGuestUser) {
      // User is authenticated, allow access
      return true;
    }

    // User is guest or not authenticated, show sign-in prompt
    final shouldSignIn =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sign in Required'),
              content: const Text(
                'You need to be signed in to access this feature. Would you like to sign in now?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Sign In'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldSignIn) {
      // Navigate to auth screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }

    return false;
  }

  /// List of features that guest users can access
  static const List<String> guestAccessibleFeatures = [
    'library', // Paint library search
    'colorPicker', // Color picker
  ];

  /// Check if a specific feature is accessible to guest users
  static bool isFeatureGuestAccessible(String featureKey) {
    return guestAccessibleFeatures.contains(featureKey);
  }
}
