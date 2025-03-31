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

    // Define colors based on theme mode
    final Color backgroundColor =
        isDarkMode ? AppTheme.marineBlueDark : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : AppTheme.marineBlue;

    // Use a softer orange accent color for dark mode
    final Color accentColor =
        isDarkMode
            ? const Color(0xFFF3A183) // Softer orange for dark mode
            : AppTheme.marineBlue; // Dark blue for light mode

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
        canvasColor: backgroundColor,
        drawerTheme: DrawerThemeData(
          backgroundColor: backgroundColor,
          scrimColor: Colors.black54,
        ),
      ),
      child: Drawer(
        elevation: 10,
        width:
            MediaQuery.of(context).size.width * 0.82, // Slightly wider drawer
        backgroundColor: backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
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
                // Header with more prominence
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
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
                          fontSize: 32, // Larger app name
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto', // Ensure app font
                        ),
                      ),
                      const SizedBox(height: 20), // More spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            14,
                          ), // Slightly larger radius
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
                              size: 20, // Slightly larger icon
                              color: accentColor,
                            ),
                            const SizedBox(width: 12), // More spacing
                            Text(
                              'Find your perfect paint',
                              style: TextStyle(
                                fontSize: 16, // Larger text
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.95)
                                        : AppTheme.marineBlue,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto', // Ensure app font
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16), // More spacing after header
                // Main navigation items with larger spacing
                Expanded(
                  child: ListView.builder(
                    itemCount: drawerItems.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = drawerItems[index];
                      final bool isActive = currentScreen == item['screen'];

                      // Calculate color for active and inactive states
                      final Color itemTextColor =
                          isActive ? accentColor : textColor;
                      final Color iconColor =
                          isActive
                              ? accentColor
                              : isDarkMode
                              ? Colors.white.withOpacity(0.9)
                              : AppTheme.marineBlue.withOpacity(0.85);

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16,
                        ), // More spacing between items
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                () =>
                                    _navigateToScreen(context, item['screen']),
                            splashColor: accentColor.withOpacity(0.2),
                            highlightColor: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              14,
                            ), // Slightly larger radius
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color:
                                    isActive
                                        ? isDarkMode
                                            ? accentColor.withOpacity(0.15)
                                            : AppTheme.marineBlue.withOpacity(
                                              0.1,
                                            )
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  14,
                                ), // Slightly larger radius
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18, // Taller items
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'],
                                    size: 26, // Larger icons
                                    color: iconColor,
                                  ),
                                  const SizedBox(
                                    width: 18,
                                  ), // More spacing between icon and text
                                  Text(
                                    item['text'],
                                    style: TextStyle(
                                      fontSize: 18, // Larger font
                                      fontWeight:
                                          isActive
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      color: itemTextColor,
                                      fontFamily: 'Roboto', // Ensure app font
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Divider with more emphasis
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    thickness: 1.5, // Slightly thicker divider
                  ),
                ),

                // Bottom items (settings, help) with more spacing
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bottomDrawerItems.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16, // More padding
                    horizontal: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = bottomDrawerItems[index];

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 16,
                      ), // More spacing between items
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              () => _navigateToScreen(context, item['screen']),
                          splashColor: accentColor.withOpacity(0.2),
                          highlightColor: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            14,
                          ), // Slightly larger radius
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16, // Taller items
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'],
                                  size: 24, // Larger icon
                                  color:
                                      isDarkMode
                                          ? Colors.white.withOpacity(0.85)
                                          : AppTheme.marineBlue.withOpacity(
                                            0.85,
                                          ),
                                ),
                                const SizedBox(
                                  width: 18,
                                ), // More spacing between icon and text
                                Text(
                                  item['text'],
                                  style: TextStyle(
                                    fontSize: 18, // Larger font
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                    fontFamily: 'Roboto', // Ensure app font
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Version number at bottom with more spacing
                Padding(
                  padding: const EdgeInsets.all(24.0), // More padding
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14, // Slightly larger
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      fontFamily: 'Roboto', // Ensure app font
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
