import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Clase de configuración para implementar diseño responsivo en toda la aplicación
/// utilizando flutter_screenutil
class ScreenUtilConfig {
  // Dimensiones del diseño de referencia (iPhone 16 Pro Max como referencia)
  static const double designWidth = 430;
  static const double designHeight = 932;

  /// Inicializa screenutil con la aplicación
  static Widget init(Widget app) {
    return ScreenUtilInit(
      // Usar las dimensiones del iPhone 16 Pro Max como referencia
      designSize: const Size(designWidth, designHeight),
      // Permitir que se adapte al texto mínimo para dispositivos pequeños
      minTextAdapt: true,
      // Soporte para pantallas divididas
      splitScreenMode: true,
      // Asegurar que los elementos de la interfaz estén correctamente proporcionados
      ensureInitialized: true,
      // Constructor de la aplicación
      builder: (context, child) => app,
    );
  }

  /// Convertir un número a escala responsive basado en el ancho
  /// Útil para: anchuras, márgenes horizontales, paddings horizontales
  static double w(double width) => width.w;

  /// Convertir un número a escala responsive basado en la altura
  /// Útil para: alturas, márgenes verticales, paddings verticales
  static double h(double height) => height.h;

  /// Convertir un número a escala responsive basado en la menor dimensión (ancho o alto)
  /// Útil para: dimensiones cuadradas, radio de bordes
  static double r(double radius) => radius.r;

  /// Convertir un número a escala responsive para tamaños de fuente
  /// Se adapta mejor en diferentes dispositivos
  static double sp(double fontSize) => fontSize.sp;

  /// Obtener dimensiones de la pantalla
  static double screenWidth(BuildContext context) => ScreenUtil().screenWidth;
  static double screenHeight(BuildContext context) => ScreenUtil().screenHeight;

  /// Obtener StatusBar height
  static double statusBarHeight(BuildContext context) =>
      ScreenUtil().statusBarHeight;

  /// Crear padding responsivo
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: (left ?? horizontal ?? all ?? 0).w,
      top: (top ?? vertical ?? all ?? 0).h,
      right: (right ?? horizontal ?? all ?? 0).w,
      bottom: (bottom ?? vertical ?? all ?? 0).h,
    );
  }

  /// Crear SizedBox con dimensiones responsivas
  static SizedBox verticalSpace(double height) => SizedBox(height: height.h);
  static SizedBox horizontalSpace(double width) => SizedBox(width: width.w);
}
