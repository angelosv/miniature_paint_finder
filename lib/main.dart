import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miniature_paint_finder/controllers/palette_controller.dart';
import 'package:miniature_paint_finder/controllers/paint_library_controller.dart';
import 'package:miniature_paint_finder/controllers/wishlist_controller.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/repositories/paint_repository.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/screens/library_screen.dart';
import 'package:miniature_paint_finder/screens/palette_screen.dart';
import 'package:miniature_paint_finder/screens/debug_analytics_screen.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/image_cache_service.dart';
import 'package:miniature_paint_finder/providers/guest_logic.dart';
import 'package:miniature_paint_finder/services/push_notification_service.dart'
    show firebaseMessagingBackgroundHandler;
import 'package:miniature_paint_finder/platform_config/linux_plugins_config.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';
import 'package:miniature_paint_finder/utils/analytics_route_observer.dart';
import 'dart:async';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure platform-specific behavior
  configureLinuxPlugins();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Continuamos con la app incluso si Firebase falla
  }

  // Initialize image cache management
  final imageCacheService = ImageCacheService();
  await imageCacheService.clearCacheIfNeeded();
  // Configurar límites globales de la caché de imágenes con valores más agresivos
  imageCacheService.configureImageCache(
    maxSizeBytes: 20 * 1024 * 1024, // 20 MB - valor más restrictivo
    maxImages: 50,
  );

  // Configure Flutter's image cache directly as well
  PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 50;

  // Initialize services
  final IAuthService authService = AuthService();
  await authService.init();

  // Initialize analytics in non-blocking way
  final analyticsService = MixpanelService.instance;
  Future.microtask(() async {
    await analyticsService.init();

    // Configurar identificación automática de usuarios
    await analyticsService.setupAutoUserIdentification(
      authService.authStateChanges,
    );
  });

  // Initialize repositories and services
  final PaintRepository paintRepository = PaintRepositoryImpl();
  final ApiService apiService = ApiService(baseUrl: ApiEndpoints.baseUrl);
  final PaletteRepository paletteRepository = ApiPaletteRepository(apiService);
  final PaintApiService paintApiService = PaintApiService();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  bool guestLogic = false;
  try {
    final response = await apiService.get(ApiEndpoints.guestLogic);
    guestLogic = response['value'];
  } catch (e) {}

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<IAuthService>.value(value: authService),
        Provider<PaintRepository>.value(value: paintRepository),
        Provider<PaletteRepository>.value(value: paletteRepository),
        Provider<PaintApiService>.value(value: paintApiService),
        Provider<MixpanelService>.value(value: analyticsService),
        ChangeNotifierProvider(
          create: (context) => PaletteController(paletteRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => PaintLibraryController(paintApiService),
        ),
        ChangeNotifierProvider(
          create: (context) => WishlistController(PaintService()),
        ),
        ChangeNotifierProvider(
          create: (_) => GuestLogicProvider()..guestLogic = guestLogic,
        ),
      ],
      child: MyAppWrapper(apiService: apiService),
    ),
  );
}

/// Este widget maneja el ciclo de vida y observa el estado de la app
class MyAppWrapper extends StatefulWidget {
  final ApiService apiService;

  const MyAppWrapper({required this.apiService});

  @override
  _MyAppWrapperState createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Remove the auth state listener navigation logic that's causing issues
  }

  void getGuestFlag() async {
    try {
      final response = await widget.apiService.get(ApiEndpoints.guestLogic);
      final guestLogicProvider = Provider.of<GuestLogicProvider>(
        context,
        listen: false,
      );
      // Si no se puede obtener el flag, asumir que es true por defecto para evitar problemas
      final bool flagValue = response['value'] ?? true;
      guestLogicProvider.guestLogic = flagValue;
    } catch (e) {
      // En caso de error, establecer guestLogic a true para permitir la autenticación
      final guestLogicProvider = Provider.of<GuestLogicProvider>(
        context,
        listen: false,
      );
      guestLogicProvider.guestLogic = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getGuestFlag();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyApp();
  }
}

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Inicializar ScreenUtil con las dimensiones de iPhone 16 Pro Max
    return ScreenUtilInit(
      // Diseño de referencia (iPhone 16 Pro Max)
      designSize: const Size(430, 932),
      // Adaptación mínima de texto para dispositivos pequeños
      minTextAdapt: true,
      // Soporte para modo de pantalla dividida
      splitScreenMode: true,
      // Construir la aplicación
      builder: (_, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Miniature Painter',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/splash',
          // Temporarily disable analytics observer to avoid navigation conflicts
          // navigatorObservers: [analyticsRouteObserver],
          routes: {
            '/splash': (context) => const AuthSplashScreen(),
            '/': (context) => const AuthScreen(),
            '/home': (context) => const HomeScreen(),
            '/palettes': (context) => const PaletteScreen(),
            '/library': (context) => const LibraryScreen(),
            '/debug-analytics': (context) => const DebugAnalyticsScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// A splash screen that handles authentication redirection
class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({Key? key}) : super(key: key);

  @override
  _AuthSplashScreenState createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    // Add a small delay to let the UI render
    await Future.delayed(Duration(milliseconds: 100));

    if (!mounted) return;

    final authService = Provider.of<IAuthService>(context, listen: false);

    // Check if user is already authenticated
    if (authService.currentUser != null) {
      // Navigate to home if already logged in
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Navigate to auth screen if not logged in
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.marineGold),
            ),
            SizedBox(height: 24),
            Text('Loading...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
