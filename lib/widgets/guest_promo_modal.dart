import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';
/// A promotional modal to encourage guest users to register
class GuestPromoModal {
  static const String _prefDismissedKey = 'guest_promo_dismissed';
  static const String _prefLastShownKey = 'guest_promo_last_shown';

  /// Shows the promotional modal if it hasn't been dismissed by the user
  static Future<void> showIfNeeded(
    BuildContext context, {
    bool forceShow = false,
  }) async {
    // Always show the modal, ignoring previous dismissals or frequency
    if (context.mounted) {
      show(context);
    }
  }

  /// Shows the promotional modal for restricted features
  static Future<void> showForRestrictedFeature(
    BuildContext context,
    String featureName,
  ) async {
    // Always show for restricted features, regardless of previous dismissal
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: _GuestPromoContent(restrictedFeature: featureName),
          );
        },
      );
    }
  }

  /// Shows the promotional modal immediately
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: _GuestPromoContent(restrictedFeature: 'Premium Features'),
        );
      },
    );
  }

  /// Marks the promo as dismissed - no longer used, but kept for compatibility
  static Future<void> markAsDismissed() async {
    // No longer store dismissal status
    return;
  }

  /// Resets the dismissal status (for debugging)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDismissedKey);
    await prefs.remove(_prefLastShownKey);
  }
}

/// Content of the promotional modal
class _GuestPromoContent extends StatelessWidget {
  final String? restrictedFeature;

  const _GuestPromoContent({this.restrictedFeature});

  @override
  Widget build(BuildContext context) {
    final String title =
        restrictedFeature != null
            ? 'Register to Access ${restrictedFeature}'
            : 'Unlock All Features!';

    final String subtitle =
        restrictedFeature != null
            ? 'Create a free account to use this feature'
            : 'Create your free account to access all features:';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.marineBlueDark, Color(0xFF1A3060)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/space_marine.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // List of benefits (only show for full promo, not for restricted feature)
          if (restrictedFeature == null) ...[
            _buildBenefitItem(
              context,
              Icons.inventory_2_outlined,
              'Manage your paint inventory',
            ),
            _buildBenefitItem(
              context,
              Icons.favorite_outline,
              'Save your favorite paints',
            ),
            _buildBenefitItem(
              context,
              Icons.palette_outlined,
              'Create custom paint palettes',
            ),
            _buildBenefitItem(
              context,
              Icons.backup_outlined,
              'Save your data in the cloud',
            ),
            const SizedBox(height: 24),
          ],

          // Register button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Navigate to registration screen
                final authService = Provider.of<IAuthService>(context, listen: false);
                await authService.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                  arguments: {'showRegistration': true},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.marineGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Create Account - 100% FREE'),
            ),
          ),

          const SizedBox(height: 16),

          // Button to continue as guest
          TextButton(
            onPressed: () async {
              // Mark the promo as dismissed
              await GuestPromoModal.markAsDismissed();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            child: Text('Continue as Guest'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.marineGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: AppTheme.marineGold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
