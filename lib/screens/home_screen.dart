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
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';

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
    if (!mounted) return;

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
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: 0, // Siempre usar índice 0 para Home
      title: 'Home',
      body: _screens[_selectedIndex],
      drawer: const SharedDrawer(currentScreen: 'home'),
      // Customizar el comportamiento solo si se agregan otras pestañas a esta pantalla
      onNavItemSelected: (index) {
        // Si estamos ya en Home y el usuario toca Home, no hacemos nada
        if (index == 0) {
          return true;
        }
        return false; // Dejar que AppScaffold maneje la navegación a otras pantallas
      },
    );
  }
}
