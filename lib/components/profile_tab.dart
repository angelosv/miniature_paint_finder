import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/profile_menu_item.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<IAuthService>(context);

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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            const Text(
              'User Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ProfileMenuItem(
              icon: Icons.collections,
              title: 'My Collection',
              onTap: () {
                // Navigate to collection screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.favorite,
              title: 'Favorites',
              onTap: () {
                // Navigate to favorites screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.history,
              title: 'Recent Searches',
              onTap: () {
                // Navigate to recent searches
              },
            ),
            ProfileMenuItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                // Navigate to settings screen
              },
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('System Theme'),
                    value: ThemeProvider.SYSTEM_THEME,
                    groupValue: themeProvider.themePreference,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Light Theme'),
                    value: ThemeProvider.LIGHT_THEME,
                    groupValue: themeProvider.themePreference,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Dark Theme'),
                    value: ThemeProvider.DARK_THEME,
                    groupValue: themeProvider.themePreference,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setThemeMode(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
