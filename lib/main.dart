import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/services/notification_service.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:miniature_paint_finder/models/user.dart';
import 'package:miniature_paint_finder/services/api_service.dart';
import 'package:miniature_paint_finder/data/api_constants.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:miniature_paint_finder/services/image_cache_service.dart';

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await NotificationService.init(); // <-- AQUÍ
    NotificationService.listenForTokenRefresh();
  } catch (e) {
    print('Firebase initialization error: $e');
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
  debugPrint('🔧 Flutter image cache configured with restrictive limits');

  // Initialize services
  final IAuthService authService = AuthService();
  await authService.init();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<IAuthService>.value(value: authService),
        Provider<PaintRepository>.value(value: paintRepository),
        Provider<PaletteRepository>.value(value: paletteRepository),
        Provider<PaintApiService>.value(value: paintApiService),
        ChangeNotifierProvider(
          create: (context) => PaletteController(paletteRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => PaintLibraryController(paintApiService),
        ),
        ChangeNotifierProvider(
          create: (context) => WishlistController(PaintService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
          title: 'Miniature Painter',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthScreen(),
            '/home': (context) => const HomeScreen(),
            '/palettes': (context) => const PaletteScreen(),
            '/library': (context) => const LibraryScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
