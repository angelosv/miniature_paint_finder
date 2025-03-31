import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// A shared drawer widget to be used across all screens for consistent navigation
class SharedDrawer extends StatelessWidget {
  /// Current screen identifier to highlight the active item
  final String currentScreen;

  /// Constructs a SharedDrawer
  const SharedDrawer({Key? key, required this.currentScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // All navigation items
    final List<Map<String, dynamic>> drawerItems = [
      {'icon': Icons.home_outlined, 'text': 'Home', 'screen': 'home'},
      {
        'icon': Icons.inventory_2_outlined,
        'text': 'My Inventory',
        'screen': 'inventory',
      },
      {'icon': Icons.favorite_border, 'text': 'Wishlist', 'screen': 'wishlist'},
      {
        'icon': Icons.auto_awesome_mosaic,
        'text': 'Library',
        'screen': 'library',
      },
      {
        'icon': Icons.palette_outlined,
        'text': 'My Palettes',
        'screen': 'palettes',
      },
    ];

    // Settings and help items
    final List<Map<String, dynamic>> bottomDrawerItems = [
      {
        'icon': Icons.settings_outlined,
        'text': 'Settings',
        'screen': 'settings',
      },
      {'icon': Icons.help_outline, 'text': 'Help & Feedback', 'screen': 'help'},
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
        drawerTheme: DrawerThemeData(
          backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
          scrimColor: Colors.black54,
        ),
      ),
      child: Drawer(
        elevation: 10,
        width: MediaQuery.of(context).size.width * 0.75,
        backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
            boxShadow:
                isDarkMode
                    ? [
                      BoxShadow(
                        color: Colors.black26,
                        offset: const Offset(1, 0),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ]
                    : [],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MiniPaint',
                        style: TextStyle(
                          fontSize: 28,
                          color:
                              isDarkMode ? Colors.white : AppTheme.marineBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : AppTheme.marineBlue.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.color_lens_outlined,
                              size: 18,
                              color:
                                  isDarkMode
                                      ? AppTheme.marineGold
                                      : AppTheme.marineBlue,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Find your perfect paint',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.9)
                                        : AppTheme.marineBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Main navigation items
                Expanded(
                  child: ListView.builder(
                    itemCount: drawerItems.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = drawerItems[index];
                      final bool isActive = currentScreen == item['screen'];

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              () => _navigateToScreen(context, item['screen']),
                          splashColor: (isDarkMode
                                  ? AppTheme.marineGold
                                  : AppTheme.marineBlue)
                              .withOpacity(0.2),
                          highlightColor: (isDarkMode
                                  ? AppTheme.marineGold
                                  : AppTheme.marineBlue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? isDarkMode
                                          ? AppTheme.marineGold.withOpacity(
                                            0.15,
                                          )
                                          : AppTheme.marineBlue.withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'],
                                  size: 22,
                                  color:
                                      isActive
                                          ? isDarkMode
                                              ? AppTheme.marineGold
                                              : AppTheme.marineBlue
                                          : isDarkMode
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.black.withOpacity(0.75),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  item['text'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isActive
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    color:
                                        isActive
                                            ? isDarkMode
                                                ? AppTheme.marineGold
                                                : AppTheme.marineBlue
                                            : isDarkMode
                                            ? Colors.white
                                            : Colors.black.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Divider before bottom items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    thickness: 1,
                  ),
                ),

                // Bottom items (settings, help)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bottomDrawerItems.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = bottomDrawerItems[index];

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToScreen(context, item['screen']),
                        splashColor: (isDarkMode
                                ? AppTheme.marineGold
                                : AppTheme.marineBlue)
                            .withOpacity(0.2),
                        highlightColor: (isDarkMode
                                ? AppTheme.marineGold
                                : AppTheme.marineBlue)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['icon'],
                                size: 22,
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.9)
                                        : Colors.black.withOpacity(0.75),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                item['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Version number at bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String? screen) {
    // First close the drawer
    Navigator.pop(context);

    // Skip navigation if we're already on this screen
    if (screen == null || screen == currentScreen) return;

    switch (screen) {
      case 'home':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
        break;
      case 'inventory':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
          (Route<dynamic> route) => false,
        );
        break;
      case 'wishlist':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WishlistScreen()),
          (Route<dynamic> route) => false,
        );
        break;
      case 'library':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LibraryScreen()),
          (Route<dynamic> route) => false,
        );
        break;
      case 'palettes':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PaletteScreen()),
          (Route<dynamic> route) => false,
        );
        break;
      case 'settings':
        // TODO: Implement settings screen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
        break;
      case 'help':
        // TODO: Implement help screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help & Feedback coming soon')),
        );
        break;
    }
  }
}
