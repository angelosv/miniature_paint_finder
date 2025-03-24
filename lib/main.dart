import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:miniature_paint_finder/providers/theme_provider.dart';
import 'package:miniature_paint_finder/repositories/paint_repository.dart';
import 'package:miniature_paint_finder/repositories/palette_repository.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    return MaterialApp(
      title: 'Miniature Paint Finder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
      // Use builder to apply global responsive settings
      builder: (context, child) {
        // Get the media query data to adapt to various screen sizes
        final MediaQueryData data = MediaQuery.of(context);
        // Calculate the text scale factor to ensure consistent text size across devices
        // iPhone 16 Pro Max has a textScaleFactor of 1.0
        final scaleFactor = data.textScaleFactor.clamp(0.85, 1.2);

        // Apply the textScaleFactor to ensure consistent appearance across devices
        return MediaQuery(
          data: data.copyWith(textScaleFactor: scaleFactor),
          child: child!,
        );
      },
    );
  }
}
