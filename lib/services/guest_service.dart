import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';

/// Service to manage guest mode access and feature restrictions
class GuestService {
  /// The list of feature keys accessible to guest users
  static const List<String> guestAccessibleFeatures = [
    'library', // Paint library screen and search
    'colorPicker', // Color picker functionality
    'barcodeScanner', // Barcode scanner functionality
  ];

  /// Check if a feature is accessible to guest users
  ///
  /// Returns true if the feature is accessible to guests, false otherwise
  static bool isFeatureGuestAccessible(String featureKey) {
    return guestAccessibleFeatures.contains(featureKey);
  }

  /// Show appropriate UI for guest users in a restricted screen
  ///
  /// Displays a banner with sign-in prompt for guest users
  static Widget wrapScreenForGuest({
    required Widget child,
    required BuildContext context,
    required IAuthService authService,
    String featureKey = '',
  }) {
    // If not a guest or feature is accessible to guests, return the normal screen
    if (!authService.isGuestUser || isFeatureGuestAccessible(featureKey)) {
      return child;
    }

    // Wrap the screen with a guest mode banner
    return Column(
      children: [
        // Guest mode banner
        Container(
          width: double.infinity,
          color: Colors.amber.shade100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Guest Mode - Limited Access',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in to access all features',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(child: child),
      ],
    );
  }

  /// Build a widget that displays a sign-in prompt for restricted features
  ///
  /// Used to replace UI elements that require authentication
  static Widget buildRestrictedFeaturePrompt(
    BuildContext context, {
    String message = 'Sign in to access this feature',
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
