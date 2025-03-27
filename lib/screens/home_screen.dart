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
                  ? AppTheme.marineBlueDark
                  : Colors.white,
        ),
        child: Drawer(
          elevation: 10,
          width: MediaQuery.of(context).size.width * 0.75,
          child: SafeArea(
            child: Column(
              children: [
                // Cabecera del Drawer con gradiente Space Marine
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          Theme.of(context).brightness == Brightness.dark
                              ? [AppTheme.marineBlueDark, AppTheme.marineBlue]
                              : [AppTheme.marineBlue, AppTheme.marineBlueLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'MiniPaint',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.color_lens_outlined,
                              size: 16,
                              color: AppTheme.marineGold,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Find your perfect paint',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Elementos del menú
                Expanded(
                  child: ListView.builder(
                    itemCount: _drawerItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final item = _drawerItems[index];
                      final bool isActive = _selectedIndex == item['index'];

                      return ListTile(
                        leading: Icon(item['icon']),
                        title: Text(item['text']),
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
                        selected: isActive,
                        selectedTileColor: AppTheme.marineBlue.withOpacity(0.1),
                        selectedColor: AppTheme.primaryBlue,
                      );
                    },
                  ),
                ),

                const Divider(),

                // Elementos inferiores
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bottomDrawerItems.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  itemBuilder: (context, index) {
                    final item = _bottomDrawerItems[index];

                    return ListTile(
                      leading: Icon(item['icon']),
                      title: Text(item['text']),
                      onTap: () {
                        _closeDrawer();
                      },
                      dense: true,
                    );
                  },
                ),

                // Versión de la app
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                      fontSize: 12,
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
