import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/paint_list_tab.dart';
import 'package:miniature_paint_finder/components/profile_tab.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerAnimController;

  // Lista de elementos del drawer
  final List<Map<String, dynamic>> _drawerItems = [
    {
      'icon': Icons.inventory_2_outlined,
      'text': 'My Inventory',
      'index': -1,
      'screen': 'inventory',
    },
    {
      'icon': Icons.favorite_border,
      'text': 'Wishlist',
      'index': -1,
      'screen': 'wishlist',
    },
    {
      'icon': Icons.auto_awesome_mosaic,
      'text': 'Library',
      'index': -2,
      'screen': 'library',
    },
    {
      'icon': Icons.palette_outlined,
      'text': 'My Palettes',
      'index': -1,
      'screen': 'palettes',
    },
  ];

  final List<Map<String, dynamic>> _bottomDrawerItems = [
    {'icon': Icons.settings_outlined, 'text': 'Settings', 'index': -1},
    {'icon': Icons.help_outline, 'text': 'Help & Feedback', 'index': -1},
  ];

  // Actualizado: solo dos pantallas ahora (eliminamos Search)
  static const List<Widget> _screens = <Widget>[PaintListTab(), ProfileTab()];

  @override
  void initState() {
    super.initState();

    _drawerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Verificar si hay argumentos de navegación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNavigationArguments();
    });
  }

  @override
  void dispose() {
    _drawerAnimController.dispose();
    super.dispose();
  }

  void _checkNavigationArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      // Seleccionar pestaña específica si se solicita
      if (arguments.containsKey('selectedIndex')) {
        final index = arguments['selectedIndex'] as int;
        if (index >= 0 && index < _screens.length) {
          setState(() {
            _selectedIndex = index;
          });
        }
      }

      // Pasar los argumentos a la pestaña seleccionada si es necesario
      // Los argumentos se pasarán automáticamente a las pestañas individuales
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _closeDrawer() {
    Navigator.pop(context);
  }

  void _navigateToScreen(String screen) {
    _closeDrawer();

    switch (screen) {
      case 'library':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LibraryScreen()),
        );
        break;

      case 'inventory':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
        );
        break;

      case 'wishlist':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WishlistScreen()),
        );
        break;

      case 'palettes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaletteScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: 0, // Esta es la página Home
      body: _screens[_selectedIndex],
      drawer: _buildDrawer(isDarkMode),
    );
  }

  Widget _buildDrawer(bool isDarkMode) {
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
                // Cabecera del Drawer - limpia y moderna
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
                        style: AppTheme.headingStyle.copyWith(
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
                              style: AppTheme.buttonStyle.copyWith(
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

                // Elementos del menú con mejor espaciado y diseño
                Expanded(
                  child: ListView.builder(
                    itemCount: _drawerItems.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = _drawerItems[index];
                      final bool isActive = _selectedIndex == item['index'];

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween<double>(begin: 1.0, end: 1.0),
                            builder: (context, double value, child) {
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      // Animate on tap
                                      _drawerAnimController.forward().then((_) {
                                        _drawerAnimController.reverse();
                                      });
                                    });

                                    // Allow animation to complete before navigation
                                    Future.delayed(
                                      const Duration(milliseconds: 150),
                                      () {
                                        if (item['index'] >= 0) {
                                          _onItemTapped(item['index']);
                                          _closeDrawer();
                                        } else if (item['screen'] != null) {
                                          _navigateToScreen(item['screen']);
                                        } else {
                                          _closeDrawer();
                                        }
                                      },
                                    );
                                  },
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
                                                  ? AppTheme.marineGold
                                                      .withOpacity(0.15)
                                                  : AppTheme.marineBlue
                                                      .withOpacity(0.1)
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        item['icon'],
                                        color:
                                            isDarkMode
                                                ? isActive
                                                    ? AppTheme.marineGold
                                                    : Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                : isActive
                                                ? AppTheme.marineBlue
                                                : AppTheme.marineBlue
                                                    .withOpacity(0.7),
                                        size: 24,
                                      ),
                                      title: Text(
                                        item['text'],
                                        style: AppTheme.buttonStyle.copyWith(
                                          fontSize: 16,
                                          fontWeight:
                                              isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                          color:
                                              isDarkMode
                                                  ? isActive
                                                      ? AppTheme.marineGold
                                                      : Colors.white
                                                  : AppTheme.marineBlue,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 8,
                                          ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                Divider(
                  height: 1,
                  color:
                      isDarkMode
                          ? Colors.white24
                          : AppTheme.marineBlue.withOpacity(0.1),
                ),

                // Elementos inferiores
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bottomDrawerItems.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = _bottomDrawerItems[index];

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _closeDrawer();
                        },
                        splashColor: (isDarkMode
                                ? AppTheme.marineGold
                                : AppTheme.marineBlue)
                            .withOpacity(0.2),
                        highlightColor: (isDarkMode
                                ? AppTheme.marineGold
                                : AppTheme.marineBlue)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(
                            item['icon'],
                            color:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : AppTheme.marineBlue.withOpacity(0.7),
                            size: 22,
                          ),
                          title: Text(
                            item['text'],
                            style: AppTheme.buttonStyle.copyWith(
                              fontSize: 15,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : AppTheme.marineBlue,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Versión de la app
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Version 1.0.0',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12,
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : AppTheme.marineBlue.withOpacity(0.6),
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
}
