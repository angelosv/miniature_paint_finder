import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/widgets/custom_bottom_nav.dart';
import 'package:provider/provider.dart';

/// Scaffold personalizado para usar en todas las pantallas de la aplicación
/// Proporciona una barra de navegación inferior coherente y un AppBar personalizado opcional
class AppScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showBackButton;
  final int? selectedIndex;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? drawer;
  final bool Function(int)? onNavItemSelected;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.showBackButton = false,
    this.selectedIndex = 0,
    this.scaffoldKey,
    this.drawer,
    this.onNavItemSelected,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  }) : super(key: key);

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex ?? 0;
  }

  void _onItemSelected(int index) {
    if (_currentIndex == index) return;

    // Give the parent widget a chance to handle the navigation
    if (widget.onNavItemSelected != null && widget.onNavItemSelected!(index)) {
      setState(() {
        _currentIndex = index;
      });
      return;
    }

    // Update state before navigation
    setState(() {
      _currentIndex = index;
    });

    // Use a post-frame callback to ensure the state update is completed
    // before navigating to prevent potential state updates on unmounted widgets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Navegar a la pantalla correspondiente usando MaterialPageRoute y pushAndRemoveUntil
      switch (index) {
        case 0:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
          break;
        case 1:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InventoryScreen()),
            (Route<dynamic> route) => false,
          );
          break;
        case 2:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WishlistScreen()),
            (Route<dynamic> route) => false,
          );
          break;
        case 3:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LibraryScreen()),
            (Route<dynamic> route) => false,
          );
          break;
        case 4:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PaletteScreen()),
            (Route<dynamic> route) => false,
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: widget.scaffoldKey,
      appBar:
          widget.showAppBar ? _buildAppBar(isDarkMode, themeProvider) : null,
      body: widget.body,
      drawer: widget.drawer,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  AppBar? _buildAppBar(bool isDarkMode, ThemeProvider themeProvider) {
    if (!widget.showAppBar) return null;

    return AppBar(
      centerTitle: true,
      leading:
          widget.showBackButton
              ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: isDarkMode ? Colors.white : AppTheme.marineBlue,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              )
              : IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: isDarkMode ? Colors.white : AppTheme.marineBlue,
                  size: 26,
                ),
                onPressed: () {
                  if (widget.scaffoldKey?.currentState != null) {
                    widget.scaffoldKey!.currentState!.openDrawer();
                  }
                },
              ),
      title: Text(
        widget.title ?? 'MiniPaint',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : AppTheme.marineBlue,
        ),
      ),
      actions:
          widget.actions ??
          [
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
    );
  }
}
