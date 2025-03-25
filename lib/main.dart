import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/repositories/paint_repository.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  final IAuthService authService = AuthService();
  await authService.init();

  // Initialize repositories
  final PaintRepository paintRepository = PaintRepositoryImpl();
  final PaletteRepository paletteRepository = PaletteRepositoryImpl();

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
          title: 'Miniature Paint Finder',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
