import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/responsive/responsive_guidelines.dart';
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';
import 'package:miniature_paint_finder/screens/debug_cache_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// A shared drawer widget to be used across all screens for consistent navigation
class SharedDrawer extends StatefulWidget {
  /// Current screen identifier to highlight the active item
  final String currentScreen;

  /// Constructs a SharedDrawer
  const SharedDrawer({Key? key, required this.currentScreen}) : super(key: key);

  @override
  State<SharedDrawer> createState() => _SharedDrawerState();
}

class _SharedDrawerState extends State<SharedDrawer>
    with SingleTickerProviderStateMixin {
  // Controller for tap animation
  late AnimationController _animationController;
  String? _tappedItem;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for tap effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to handle when a menu item is tapped
  void _onItemTap(String screen) {
    setState(() {
      _tappedItem = screen;
    });

    // Play the animation
    _animationController.forward().then((_) {
      _animationController.reset();
      // Navigate to the screen after the animation completes
      _navigateToScreen(context, screen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on theme mode
    final Color backgroundColor =
        isDarkMode
            ? AppTheme.marineBlueDark.withOpacity(
              0.97,
            ) // Semitransparent background in dark mode
            : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : AppTheme.marineBlue;

    // Use the orange accent color from the image for dark mode
    final Color accentColor =
        isDarkMode
            ? AppTheme
                .drawerOrange // Orange from the image for dark mode
            : AppTheme.marineBlue; // Dark blue for light mode

    // All navigation items with consistent outlined icons
    final List<Map<String, dynamic>> drawerItems = [
      // Herramientas de búsqueda
      {
        'icon': Icons.color_lens_outlined,
        'text': 'Paint Search',
        'screen': 'paint_search',
      },
      {
        'icon': Icons.qr_code_scanner_outlined,
        'text': 'Barcode Scanner',
        'screen': 'barcode_scanner',
      },

      // Secciones principales (separadas por un divisor visual)
      {'icon': Icons.home_outlined, 'text': 'Home', 'screen': 'home'},
      {
        'icon': Icons.inventory_outlined,
        'text': 'My Inventory',
        'screen': 'inventory',
      },
      {
        'icon': Icons.favorite_outline,
        'text': 'Wishlist',
        'screen': 'wishlist',
      },
      {
        'icon': Icons.grid_view_outlined,
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
        'icon': Icons.bug_report_outlined,
        'text': 'Debug Cache',
        'screen': 'debug_cache',
      },
      {
        'icon': Icons.person_outline,
        'text': 'Profile & Settings',
        'screen': 'profile_settings',
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
        width: MediaQuery.of(context).size.width * 0.82,
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
                  padding: EdgeInsets.symmetric(
                    vertical: 25.h,
                    horizontal: 24.w,
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
                        style: AppTheme.drawerHeaderTextStyle.copyWith(
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.drawerBorderRadius,
                          ),
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
                              size: AppTheme.drawerIconSize,
                              color: accentColor,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Find your perfect paint',
                              style: AppTheme.drawerSubtitleTextStyle.copyWith(
                                color:
                                    isDarkMode
                                        ? Colors.white.withOpacity(0.95)
                                        : AppTheme.marineBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // Main navigation items with spacing optimizado
                Expanded(
                  child: ListView.builder(
                    itemCount: drawerItems.length,
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 16.w,
                    ),
                    itemBuilder: (context, index) {
                      final item = drawerItems[index];
                      final String screen = item['screen'];
                      final bool isActive = widget.currentScreen == screen;
                      final bool isTapped = _tappedItem == screen;

                      // Add a divider after search tools (after index 1)
                      if (index == 2) {
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.h,
                                horizontal: 8.w,
                              ),
                              child: Divider(
                                color:
                                    isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                thickness: 1.5,
                              ),
                            ),
                            _buildDrawerItem(
                              context,
                              item,
                              screen,
                              isActive,
                              isTapped,
                              accentColor,
                              textColor,
                              iconColor:
                                  isActive
                                      ? accentColor
                                      : isDarkMode
                                      ? Colors.white.withOpacity(0.9)
                                      : AppTheme.marineBlue.withOpacity(0.85),
                            ),
                          ],
                        );
                      }

                      // Calculate color for active and inactive states
                      final Color itemTextColor =
                          isActive ? accentColor : textColor;
                      final Color iconColor =
                          isActive
                              ? accentColor
                              : isDarkMode
                              ? Colors.white.withOpacity(0.9)
                              : AppTheme.marineBlue.withOpacity(0.85);

                      return _buildDrawerItem(
                        context,
                        item,
                        screen,
                        isActive,
                        isTapped,
                        accentColor,
                        itemTextColor,
                        iconColor: iconColor,
                      );
                    },
                  ),
                ),

                // Bottom items (settings, help) pegados al fondo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Divider with more emphasis
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Divider(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        thickness: 1.5,
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bottomDrawerItems.length,
                      padding: EdgeInsets.symmetric(
                        vertical: 8.h,
                        horizontal: 16.w,
                      ),
                      itemBuilder: (context, index) {
                        final item = bottomDrawerItems[index];
                        final String screen = item['screen'];
                        final bool isTapped = _tappedItem == screen;

                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            // Apply a scale effect when tapped
                            final double scale =
                                isTapped
                                    ? 1.0 - (_animationController.value * 0.05)
                                    : 1.0;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: AppTheme.drawerItemSpacing,
                              ),
                              child: Transform.scale(
                                scale: scale,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _onItemTap(screen),
                                    splashColor: accentColor.withOpacity(0.3),
                                    highlightColor: accentColor.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.drawerBorderRadius,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.drawerBorderRadius,
                                        ),
                                        boxShadow:
                                            isTapped
                                                ? [
                                                  BoxShadow(
                                                    color: accentColor
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              AppTheme.drawerItemPadding,
                                          vertical:
                                              AppTheme.drawerItemPadding * 0.7,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              item['icon'],
                                              size: AppTheme.drawerIconSize,
                                              color:
                                                  isDarkMode
                                                      ? Colors.white
                                                          .withOpacity(0.85)
                                                      : AppTheme.marineBlue
                                                          .withOpacity(0.85),
                                            ),
                                            SizedBox(width: 18.w),
                                            Text(
                                              item['text'],
                                              style: AppTheme
                                                  .drawerItemTextStyle
                                                  .copyWith(color: textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, String? screen) {
    // Skip navigation if we're already on this screen or if tap animation is still running
    if (screen == null || screen == widget.currentScreen) {
      Navigator.pop(context); // Just close the drawer
      return;
    }

    // Close the drawer first
    Navigator.pop(context);

    // Add a slight delay before navigation for better user experience
    Future.delayed(const Duration(milliseconds: 50), () {
      switch (screen) {
        case 'paint_search':
          // Navigate to home screen with the Paint Search tab
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const HomeScreen(),
              settings: const RouteSettings(
                arguments: {'selectedIndex': 0, 'openSearch': true},
              ),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'barcode_scanner':
          // Navigate to the barcode scanner screen
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const BarcodeScannerScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
          break;
        case 'debug_cache':
          // Navigate to the debug cache screen
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const DebugCacheScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
          break;
        case 'home':
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const HomeScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'inventory':
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const InventoryScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'wishlist':
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const WishlistScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'library':
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const LibraryScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'palettes':
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const PaletteScreen(),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'profile_settings':
          // Navigate to home screen with Profile tab
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const HomeScreen(),
              settings: const RouteSettings(arguments: {'selectedIndex': 1}),
              transitionsBuilder: _buildTransition,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (Route<dynamic> route) => false,
          );
          break;
        case 'help':
          // TODO: Implement help screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Help & Feedback coming soon')),
          );
          break;
        case 'settings':
          // Redirect to profile_settings
          _navigateToScreen(context, 'profile_settings');
          break;
      }
    });
  }

  // Custom transition animation for smoother navigation
  Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.1, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // Helper method to build a drawer item
  Widget _buildDrawerItem(
    BuildContext context,
    Map<String, dynamic> item,
    String screen,
    bool isActive,
    bool isTapped,
    Color accentColor,
    Color textColor, {
    required Color iconColor,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Apply a scale effect when tapped
        final double scale =
            isTapped ? 1.0 - (_animationController.value * 0.05) : 1.0;

        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.drawerItemSpacing),
          child: Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onItemTap(screen),
                splashColor: accentColor.withOpacity(0.3),
                highlightColor: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  AppTheme.drawerBorderRadius,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Theme.of(context).brightness == Brightness.dark
                                ? accentColor.withOpacity(0.15)
                                : AppTheme.marineBlue.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppTheme.drawerBorderRadius,
                    ),
                    boxShadow:
                        isTapped
                            ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                            : null,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.drawerItemPadding,
                      vertical: AppTheme.drawerItemPadding,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'],
                          size: AppTheme.drawerIconSize,
                          color: iconColor,
                        ),
                        SizedBox(width: 18.w),
                        Text(
                          item['text'],
                          style: AppTheme.drawerItemTextStyle.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
