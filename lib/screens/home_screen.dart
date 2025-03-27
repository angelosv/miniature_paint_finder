import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/paint_list_tab.dart';
import 'package:miniature_paint_finder/components/profile_tab.dart';
import 'package:miniature_paint_finder/components/search_tab.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  static const List<Widget> _screens = <Widget>[
    PaintListTab(),
    SearchTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();

    // Verificar si hay argumentos de navegación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNavigationArguments();
    });
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDarkMode ? Colors.white : AppTheme.marineBlue,
            size: 26,
          ),
          onPressed: _openDrawer,
          tooltip: 'Menu',
        ),
        title: Text(
          'MiniPaint',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.marineBlue,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDarkMode ? AppTheme.marineGold : AppTheme.marineBlue,
            ),
            tooltip: 'Toggle theme',
            onPressed: () {
              final newTheme =
                  isDarkMode
                      ? ThemeProvider.LIGHT_THEME
                      : ThemeProvider.DARK_THEME;
              themeProvider.setThemeMode(newTheme);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: isDarkMode ? Colors.white : AppTheme.marineBlue,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: isDarkMode ? AppTheme.marineBlueDark : Colors.white,
        elevation: 0,
      ),
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkBackground
                  : Colors.white,
        ),
        child: Drawer(
          elevation: 8,
          width: MediaQuery.of(context).size.width * 0.75,
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
                    color: isDarkMode ? AppTheme.darkBackground : Colors.white,
                    boxShadow: [
                      if (isDarkMode)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
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
                                      : AppTheme.marineOrange,
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

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (item['index'] >= 0) {
                              _onItemTapped(item['index']);
                              _closeDrawer();
                            } else if (item['screen'] != null) {
                              _navigateToScreen(item['screen']);
                            } else {
                              _closeDrawer();
                            }
                          },
                          splashColor: (isDarkMode
                                  ? AppTheme.marineGold
                                  : AppTheme.marineOrange)
                              .withOpacity(0.1),
                          highlightColor: (isDarkMode
                                  ? AppTheme.marineGold
                                  : AppTheme.marineOrange)
                              .withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            leading: Icon(
                              item['icon'],
                              color:
                                  isActive
                                      ? (isDarkMode
                                          ? AppTheme.marineGold
                                          : AppTheme.marineOrange)
                                      : isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
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
                                    isActive
                                        ? (isDarkMode
                                            ? AppTheme.marineGold
                                            : AppTheme.marineOrange)
                                        : isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            selected: isActive,
                            selectedTileColor:
                                isDarkMode
                                    ? AppTheme.marineBlue.withOpacity(0.2)
                                    : AppTheme.marineOrange.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

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
                                : AppTheme.marineOrange)
                            .withOpacity(0.1),
                        highlightColor: (isDarkMode
                                ? AppTheme.marineGold
                                : AppTheme.marineOrange)
                            .withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(
                            item['icon'],
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 22,
                          ),
                          title: Text(
                            item['text'],
                            style: AppTheme.buttonStyle.copyWith(
                              fontSize: 15,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
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
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppTheme.marineBlueDark
                : Colors.white,
        selectedItemColor: AppTheme.marineOrange,
        unselectedItemColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
