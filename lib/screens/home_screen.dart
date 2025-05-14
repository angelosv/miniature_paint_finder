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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _pushInitialized = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerAnimController;
  bool _showPromoButton = false;

  // Screens
  static const List<Widget> _screens = <Widget>[PaintListTab(), ProfileTab()];

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
  }

  @override
  Widget build(BuildContext context) {
    final guestLogicProvider = Provider.of<GuestLogicProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGuestUser = currentUser == null || currentUser.isAnonymous;
    if (!guestLogicProvider.guestLogic && isGuestUser) {
      final authService = Provider.of<IAuthService>(context, listen: false);
      authService.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
        arguments: {'showRegistration': true},
      );
    }

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      selectedIndex: 0, // Always use index 0 for Home
      title: 'Home',
      body: _screens[_selectedIndex],
      drawer: const SharedDrawer(currentScreen: 'home'),
      // Customize behavior only if other tabs are added to this screen
      onNavItemSelected: (index) {
        // If we're already on Home and user taps Home, do nothing
        if (index == 0) {
          return true;
        }
        return false; // Let AppScaffold handle navigation to other screens
      },
      floatingActionButton: _showPromoButton ? _buildGuestPromoButton() : null,
    );
  }

  Widget _buildGuestPromoButton() {
    return FloatingActionButton.extended(
      onPressed:
          () => GuestPromoModal.showForRestrictedFeature(
            context,
            'Premium Features',
          ),
      label: Text('Unlock More!'),
      icon: Icon(Icons.star),
      backgroundColor: AppTheme.marineGold,
      foregroundColor: Colors.black87,
    );
  }
}
