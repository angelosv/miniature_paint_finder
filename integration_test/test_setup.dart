import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Configuración inicial para tests de integración
class TestSetup {
  /// Configura el entorno de testing
  static Future<void> setupTestEnvironment() async {
    // Activar modo de testing en AppTheme
    AppTheme.setTestMode(true);
    
    // Configurar orientación de pantalla para tests
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Configurar timeout para operaciones de red en tests
    HttpOverrides.global = TestHttpOverrides();
  }
  
  /// Limpia el entorno después de los tests
  static Future<void> tearDownTestEnvironment() async {
    // Desactivar modo de testing
    AppTheme.setTestMode(false);
    
    // Restaurar configuración original
    await SystemChrome.setPreferredOrientations([]);
    HttpOverrides.global = null;
  }
}

/// HttpOverrides personalizado para tests con timeouts más cortos
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // Timeout más corto para tests
    client.connectionTimeout = const Duration(seconds: 10);
    return client;
  }
}
