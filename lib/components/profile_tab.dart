import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/components/profile_menu_item.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/models/user.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Obtiene el avatar del usuario (foto o iniciales)
  Widget _buildUserAvatar(BuildContext context, User? user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.marineBlueLight : AppTheme.marineBlue;

    if (user?.profileImage != null && user!.profileImage!.isNotEmpty) {
      // Mostrar la imagen de perfil si existe
      return CircleAvatar(
        radius: 50.r,
        backgroundImage: NetworkImage(user.profileImage!),
      );
    } else {
      // Mostrar iniciales si no hay imagen
      String initials = '';
      if (user?.name != null && user!.name.isNotEmpty) {
        final nameParts = user.name.split(' ');
        if (nameParts.isNotEmpty) {
          initials = nameParts[0][0];
          if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
            initials += nameParts[1][0];
          }
        }
      } else {
        initials = '?';
      }

      return CircleAvatar(
        radius: 50.r,
        backgroundColor: backgroundColor,
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  // Obtiene texto descriptivo del proveedor de autenticación
  String _getAuthProviderText(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return 'Signed in with Google';
      case 'apple':
        return 'Signed in with Apple';
      case 'email':
        return 'Signed in with Email';
      case 'phone':
        return 'Signed in with Phone';
      default:
        return 'Signed in with ${provider.capitalize()}';
    }
  }

  // Obtiene icono correspondiente al proveedor de autenticación
  IconData _getAuthProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone_android;
      default:
        return Icons.person;
    }
  }

  // Muestra el modal de confirmación para eliminar cuenta
  void _showDeleteAccountModal(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 16.r),
                  width: 40.r,
                  height: 4.r,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: 16.r),

              Text(
                'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),

              SizedBox(height: 24.r),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDarkMode ? Colors.white30 : Colors.black26,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.r),
                      ),
                      child: Text('Cancel', style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                  SizedBox(width: 16.r),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coming soon: Account deletion'),
                            backgroundColor: AppTheme.marineOrange,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.r),
                      ),
                      child: Text('Delete', style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.r),
            ],
          ),
        );
      },
    );
  }

  // Muestra una notificación "Coming Soon"
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coming soon: $feature'),
        backgroundColor: AppTheme.marineOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<IAuthService>(context);
    final user = authService.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundGrey;

    final cardColor = isDarkMode ? AppTheme.darkSurface : Colors.white;

    final textColor = isDarkMode ? Colors.white : AppTheme.textDark;

    final subTextColor = isDarkMode ? Colors.white70 : AppTheme.textGrey;

    void _handleSignOut() async {
      try {
        await authService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorDialog(context, 'Error signing out: $e');
        }
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.r),

              // User Profile Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _buildUserAvatar(context, user),
                    SizedBox(height: 16.r),
                    Text(
                      user?.name ?? 'User',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 4.r),
                    Text(
                      user?.email ?? 'No email available',
                      style: TextStyle(fontSize: 16.sp, color: subTextColor),
                    ),
                    SizedBox(height: 12.r),
                    if (user?.authProvider != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.r,
                          vertical: 6.r,
                        ),
                        decoration: BoxDecoration(
                          color: (isDarkMode
                                  ? AppTheme.marineBlueLight
                                  : AppTheme.marineBlue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAuthProviderIcon(user!.authProvider),
                              size: 18.r,
                              color:
                                  isDarkMode
                                      ? AppTheme.marineBlueLight
                                      : AppTheme.marineBlue,
                            ),
                            SizedBox(width: 6.r),
                            Text(
                              _getAuthProviderText(user.authProvider),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color:
                                    isDarkMode
                                        ? AppTheme.marineBlueLight
                                        : AppTheme.marineBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20.r),

              // Settings Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16.r),

                    ProfileMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your notification settings',
                      onTap: () => _showComingSoon(context, 'Notifications'),
                    ),

                    ProfileMenuItem(
                      icon: Icons.email_outlined,
                      title: 'Email Preferences',
                      subtitle: 'Customize email notifications',
                      onTap:
                          () => _showComingSoon(context, 'Email preferences'),
                    ),

                    ProfileMenuItem(
                      icon: Icons.security_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your security settings',
                      onTap: () => _showComingSoon(context, 'Privacy settings'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.r),

              // Theme Settings Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16.r),

                    RadioListTile<String>(
                      title: Text(
                        'System Theme',
                        style: TextStyle(color: textColor, fontSize: 16.sp),
                      ),
                      value: ThemeProvider.SYSTEM_THEME,
                      groupValue: themeProvider.themePreference,
                      activeColor: AppTheme.marineOrange,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),

                    RadioListTile<String>(
                      title: Text(
                        'Light Theme',
                        style: TextStyle(color: textColor, fontSize: 16.sp),
                      ),
                      value: ThemeProvider.LIGHT_THEME,
                      groupValue: themeProvider.themePreference,
                      activeColor: AppTheme.marineOrange,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),

                    RadioListTile<String>(
                      title: Text(
                        'Dark Theme',
                        style: TextStyle(color: textColor, fontSize: 16.sp),
                      ),
                      value: ThemeProvider.DARK_THEME,
                      groupValue: themeProvider.themePreference,
                      activeColor: AppTheme.marineOrange,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.r),

              // Developer Options (solo visible en modo debug)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer Options',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16.r),

                    ProfileMenuItem(
                      icon: Icons.analytics_outlined,
                      title: 'Mixpanel Diagnostics',
                      subtitle: 'Verify analytics tracking',
                      onTap: () {
                        Navigator.of(context).pushNamed('/mixpanel_diagnostic');
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.r),

              // Account Actions Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16.r),

                    ElevatedButton.icon(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout),
                      label: Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.marineOrange,
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(50.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.r),

                    OutlinedButton.icon(
                      onPressed: () => _showDeleteAccountModal(context),
                      icon: const Icon(Icons.delete_forever),
                      label: Text('Delete Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: Size.fromHeight(50.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.r),
            ],
          ),
        ),
      ),
    );
  }
}

// Extensión para capitalizar strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
