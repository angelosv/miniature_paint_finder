import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/screens/permission_repair_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// Punto de entrada alternativo para depuración de pantalla de reparación de permisos
void main() {
  runApp(const PermissionRepairDebugApp());
}

/// Aplicación para depurar la pantalla de reparación de permisos
class PermissionRepairDebugApp extends StatelessWidget {
  const PermissionRepairDebugApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Permission Repair Debug',
      // Usar temas simples sin constantes complejas que puedan causar errores
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppTheme.primaryBlue,
          secondary: AppTheme.marineOrange,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primaryBlue,
          secondary: AppTheme.marineOrange,
        ),
      ),
      home: const PermissionRepairScreen(),
    );
  }
}
