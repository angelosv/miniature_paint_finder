import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/profile_menu_item.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
              onPressed: () {
                // Login functionality will be added later
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
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
