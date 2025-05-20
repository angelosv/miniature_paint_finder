import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/components/paint_list_tab.dart';
import 'package:miniature_paint_finder/components/profile_tab.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/screens/inventory_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/wishlist_screen.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:miniature_paint_finder/services/push_notification_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:miniature_paint_finder/widgets/app_scaffold.dart';
import 'package:miniature_paint_finder/widgets/shared_drawer.dart';
import 'package:miniature_paint_finder/widgets/guest_promo_modal.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';
import 'package:miniature_paint_finder/providers/guest_logic.dart';
import 'package:miniature_paint_finder/screens/screen_analytics.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, ScreenAnalyticsMixin {
  int _selectedIndex = 0;
  bool _pushInitialized = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerAnimController;
  bool _showPromoButton = false;

  // Screens
  static const List<Widget> _screens = <Widget>[PaintListTab(), ProfileTab()];

  @override
  String get screenName => 'Home Screen';

  @override
  void initState() {
    super.initState();

    _drawerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Check navigation arguments and guest status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePushNotifications();
      _checkNavigationArguments();
      _checkPromoButtonVisibility();
      _trackUserProperties();
    });
  }

  void _initializePushNotifications() {
    if (_pushInitialized) return;
    final authService = Provider.of<IAuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    if (authService.currentUser != null) {
      PushNotificationService(
        apiService: apiService,
        authService: authService,
      ).init();
      _pushInitialized = true;
    }
  }

  void _checkPromoButtonVisibility() async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;
    if (!isGuestUser) {
      setState(() {
        _showPromoButton = false;
      });
      return;
    }

    // Always show the promo button for guest users
    setState(() {
      _showPromoButton = true;
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
      // Select specific tab if requested
      if (arguments.containsKey('selectedIndex')) {
        final index = arguments['selectedIndex'] as int;
        if (index >= 0 && index < _screens.length) {
          setState(() {
            _selectedIndex = index;
          });
        }
      }

      // Arguments will be automatically passed to individual tabs
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });

    // Trackear cambio de tab
    trackEvent('Tab Changed', {
      'tab_index': index,
      'tab_name': index == 0 ? 'Paint List' : 'Profile',
    });
  }

  @override
  Widget build(BuildContext context) {
    final guestLogicProvider = Provider.of<GuestLogicProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;

    // Modificación: Usar un Future.microtask para navegar fuera del ciclo de build
    // y solo si es un usuario anónimo real (no durante autenticación)
    if (!guestLogicProvider.guestLogic &&
        isGuestUser &&
        currentUser?.isAnonymous == true) {
      // Solo manejar la redirección si es un usuario realmente anónimo
      // y no durante el proceso de autenticación
      Future.microtask(() {
        if (mounted) {
          final authService = Provider.of<IAuthService>(context, listen: false);
          authService.signOut();
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
            arguments: {'showRegistration': true},
          );
        }
      });
    }

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: 0, // Always use index 0 for Home
      title: 'Home',
      body: _screens[_selectedIndex],
      drawer: const SharedDrawer(currentScreen: 'home'),
      // Customize behavior only if other tabs are added to this screen
      onNavItemSelected: (index) {
        // Si es la navegación principal, trackear el evento
        if (index != 0) {
          MixpanelService.instance.trackEvent('Navigation', {
            'from': 'Home',
            'to': _getScreenNameFromIndex(index),
          });
        }

        // If we're already on Home and user taps Home, do nothing
        if (index == 0) {
          return true;
        }
        return false; // Let AppScaffold handle navigation to other screens
      },
      floatingActionButton: _showPromoButton ? _buildGuestPromoButton() : null,
    );
  }

  // Función auxiliar para obtener el nombre de pantalla a partir del índice
  String _getScreenNameFromIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Palettes';
      case 2:
        return 'Library';
      case 3:
        return 'Wishlist';
      case 4:
        return 'Inventory';
      default:
        return 'Unknown';
    }
  }

  Widget _buildGuestPromoButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Trackear clic en botón de promoción
        trackEvent('Guest Promo Button Clicked');
        GuestPromoModal.showForRestrictedFeature(context, 'Premium Features');
      },
      label: Text('Unlock More!'),
      icon: Icon(Icons.star),
      backgroundColor: AppTheme.marineGold,
      foregroundColor: Colors.black87,
    );
  }

  // Método para trackear propiedades adicionales del usuario
  void _trackUserProperties() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final analytics = MixpanelService.instance;
      final isGuestUser = currentUser.isAnonymous;

      // Obtener información sobre el dispositivo
      final prefs = await SharedPreferences.getInstance();
      final firstVisit = prefs.getBool('first_visit') ?? true;
      final visitCount = prefs.getInt('visit_count') ?? 0;

      // Actualizar contador de visitas
      await prefs.setInt('visit_count', visitCount + 1);

      // Si es primera visita, registrar
      if (firstVisit) {
        await prefs.setBool('first_visit', false);
        await prefs.setString(
          'first_visit_date',
          DateTime.now().toIso8601String(),
        );
      }

      // Calcular días desde primera visita
      int daysSinceFirstVisit = 0;
      final firstVisitDateStr = prefs.getString('first_visit_date');
      if (firstVisitDateStr != null) {
        final firstVisitDate = DateTime.parse(firstVisitDateStr);
        daysSinceFirstVisit = DateTime.now().difference(firstVisitDate).inDays;
      }

      // Trackear visita
      analytics.trackVisitCount(visitCount + 1, daysSinceFirstVisit);

      // Si no es usuario anónimo, completar perfil
      if (!isGuestUser) {
        // Actualizar propiedades adicionales del usuario
        analytics.updateUserProperty(
          'last_seen',
          DateTime.now().toIso8601String(),
        );
        analytics.updateUserProperty('home_screen_visits', visitCount + 1);

        // Adjuntar propiedades sobre uso de pestañas
        if (_selectedIndex == 0) {
          analytics.incrementUserProperty('paint_list_tab_views', 1.0);
        } else if (_selectedIndex == 1) {
          analytics.incrementUserProperty('profile_tab_views', 1.0);
        }

        // Trackear frecuencia de uso
        if (daysSinceFirstVisit > 0) {
          final visitsPerDay = (visitCount + 1) / daysSinceFirstVisit;
          final isFrequentUser =
              visitsPerDay > 0.5; // Más de una visita cada 2 días

          analytics.trackUsageFrequency(
            'daily',
            visitCount + 1,
            daysSinceFirstVisit,
          );

          analytics.updateUserProperty('is_frequent_user', isFrequentUser);
          analytics.updateUserProperty('visits_per_day', visitsPerDay);
        }
      }
    } catch (e) {
      print('Error tracking user properties: $e');
      // No propagar error para no afectar la experiencia del usuario
    }
  }
}
