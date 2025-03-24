import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Constantes para tamaños de dispositivos y breakpoints
///
/// Esta clase contiene las constantes necesarias para identificar
/// diferentes tipos de dispositivos y manejar breakpoints para diseños responsivos.
class DeviceConstants {
  // Breakpoints principales (basados en ancho)
  static const double mobileSmallBreakpoint = 320;
  static const double mobileBreakpoint = 375;
  static const double mobileLargeBreakpoint = 428;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  // Tamaños de referencia iPhone para desarrollo
  static const Size iPhoneSE = Size(375, 667);
  static const Size iPhone13Mini = Size(375, 812);
  static const Size iPhone13 = Size(390, 844);
  static const Size iPhone13Pro = Size(390, 844);
  static const Size iPhone13ProMax = Size(428, 926);
  static const Size iPhone16Pro = Size(393, 852);
  static const Size iPhone16ProMax = Size(430, 932);

  // Tamaños de referencia Android para desarrollo
  static const Size galaxyS22 = Size(360, 780);
  static const Size pixel7 = Size(412, 915);
  static const Size galaxyFold = Size(280, 653); // Cerrado
  static const Size galaxyFoldOpen = Size(585, 653); // Abierto

  // Tamaños de referencia tablets
  static const Size iPadMini = Size(768, 1024);
  static const Size iPad = Size(810, 1080);
  static const Size iPadPro = Size(1024, 1366);
  static const Size galaxyTabS8 = Size(800, 1280);

  /// Verificar si el dispositivo actual es un teléfono pequeño
  static bool isSmallMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < mobileBreakpoint;
  }

  /// Verificar si el dispositivo actual es un teléfono
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Verificar si el dispositivo actual es una tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Verificar si el dispositivo actual es un desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= desktopBreakpoint;
  }

  /// Obtener la orientación del dispositivo
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Obtener la orientación del dispositivo
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Ejecutar diferentes widgets según el tamaño de la pantalla
  static Widget responsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Factor de escala para ajustar elementos según el iPhone 16 Pro Max
  static double getScaleFactor(BuildContext context) {
    final Size currentSize = MediaQuery.of(context).size;
    final double widthScaleFactor = currentSize.width / iPhone16ProMax.width;
    final double heightScaleFactor = currentSize.height / iPhone16ProMax.height;

    // Usar el factor más pequeño para asegurar que todo cabe en la pantalla
    return widthScaleFactor < heightScaleFactor
        ? widthScaleFactor
        : heightScaleFactor;
  }
}
