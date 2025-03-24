import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Guía de diseño responsivo para la aplicación usando flutter_screenutil
///
/// Este archivo contiene constantes y utilidades para aplicar un diseño responsivo
/// consistente a través de toda la aplicación.
class ResponsiveGuidelines {
  // Tamaños de texto responsivos
  static double get displayLarge => 32.sp;
  static double get displayMedium => 28.sp;
  static double get displaySmall => 24.sp;
  static double get headlineLarge => 22.sp;
  static double get headlineMedium => 20.sp;
  static double get headlineSmall => 18.sp;
  static double get titleLarge => 16.sp;
  static double get titleMedium => 14.sp;
  static double get titleSmall => 12.sp;
  static double get bodyLarge => 16.sp;
  static double get bodyMedium => 14.sp;
  static double get bodySmall => 12.sp;
  static double get labelLarge => 14.sp;
  static double get labelMedium => 12.sp;
  static double get labelSmall => 10.sp;

  // Espaciado responsivo
  static double get spacingXXS => 2.w;
  static double get spacingXS => 4.w;
  static double get spacingS => 8.w;
  static double get spacingM => 12.w;
  static double get spacingL => 16.w;
  static double get spacingXL => 24.w;
  static double get spacingXXL => 32.w;
  static double get spacingXXXL => 48.w;

  // Bordes redondeados
  static double get radiusXS => 4.r;
  static double get radiusS => 8.r;
  static double get radiusM => 12.r;
  static double get radiusL => 16.r;
  static double get radiusXL => 24.r;
  static double get radiusXXL => 32.r;

  // Tamaños de iconos
  static double get iconXS => 16.r;
  static double get iconS => 20.r;
  static double get iconM => 24.r;
  static double get iconL => 32.r;
  static double get iconXL => 40.r;

  // Alturas de botones
  static double get buttonHeightS => 32.h;
  static double get buttonHeightM => 40.h;
  static double get buttonHeightL => 48.h;

  // Anchuras de botones
  static double get buttonWidthS => 80.w;
  static double get buttonWidthM => 120.w;
  static double get buttonWidthL => 160.w;

  // Paddings responsivos
  static EdgeInsets get paddingXS => EdgeInsets.all(4.w);
  static EdgeInsets get paddingS => EdgeInsets.all(8.w);
  static EdgeInsets get paddingM => EdgeInsets.all(12.w);
  static EdgeInsets get paddingL => EdgeInsets.all(16.w);
  static EdgeInsets get paddingXL => EdgeInsets.all(24.w);

  // Paddings horizontales y verticales
  static EdgeInsets get paddingHorizontalS =>
      EdgeInsets.symmetric(horizontal: 8.w);
  static EdgeInsets get paddingHorizontalM =>
      EdgeInsets.symmetric(horizontal: 16.w);
  static EdgeInsets get paddingHorizontalL =>
      EdgeInsets.symmetric(horizontal: 24.w);
  static EdgeInsets get paddingVerticalS => EdgeInsets.symmetric(vertical: 8.h);
  static EdgeInsets get paddingVerticalM =>
      EdgeInsets.symmetric(vertical: 16.h);
  static EdgeInsets get paddingVerticalL =>
      EdgeInsets.symmetric(vertical: 24.h);

  // Utility para crear tamaños responsivos
  static double width(double width) => width.w;
  static double height(double height) => height.h;
  static double fontSize(double size) => size.sp;
  static double radius(double radius) => radius.r;

  /// Espaciadores verticales
  static SizedBox get verticalSpaceXS => SizedBox(height: spacingXS);
  static SizedBox get verticalSpaceS => SizedBox(height: spacingS);
  static SizedBox get verticalSpaceM => SizedBox(height: spacingM);
  static SizedBox get verticalSpaceL => SizedBox(height: spacingL);
  static SizedBox get verticalSpaceXL => SizedBox(height: spacingXL);
  static SizedBox verticalSpace(double height) => SizedBox(height: height.h);

  /// Espaciadores horizontales
  static SizedBox get horizontalSpaceXS => SizedBox(width: spacingXS);
  static SizedBox get horizontalSpaceS => SizedBox(width: spacingS);
  static SizedBox get horizontalSpaceM => SizedBox(width: spacingM);
  static SizedBox get horizontalSpaceL => SizedBox(width: spacingL);
  static SizedBox get horizontalSpaceXL => SizedBox(width: spacingXL);
  static SizedBox horizontalSpace(double width) => SizedBox(width: width.w);
}
