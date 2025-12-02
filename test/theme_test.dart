import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

void main() {
  group('🎨 AppTheme Tests', () {
    test('Should detect test environment correctly', () {
      // Activar modo de testing
      AppTheme.setTestMode(true);
      expect(AppTheme.isTestEnvironment, isTrue);
      
      // Desactivar modo de testing
      AppTheme.setTestMode(false);
      // Aún debe ser true porque estamos en un entorno de test (FLUTTER_TEST existe)
      expect(AppTheme.isTestEnvironment, isTrue);
    });

    test('Should return appropriate font for platform in test mode', () {
      AppTheme.setTestMode(true);
      final fontFamily = AppTheme.fontFamily;
      
      if (Platform.isIOS) {
        expect(fontFamily, equals('SF Pro Text'));
      } else if (Platform.isAndroid) {
        expect(fontFamily, equals('Roboto'));
      } else {
        // Otras plataformas pueden usar null (fuente por defecto)
        expect(fontFamily, anyOf(isNull, isA<String>()));
      }
      
      // No debe contener Poppins en modo test
      if (fontFamily != null) {
        expect(fontFamily, isNot(contains('Poppins')));
      }
    });

    test('Should create getTextStyle method correctly', () {
      AppTheme.setTestMode(true);
      
      final textStyle = AppTheme.getTextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
        color: const Color(0xFF000000),
      );

      expect(textStyle.fontWeight, equals(FontWeight.bold));
      expect(textStyle.fontSize, equals(16.0));
      expect(textStyle.color, equals(const Color(0xFF000000)));
      expect(textStyle.fontFamily, equals(AppTheme.fontFamily));
    });

    test('Should handle production mode correctly', () {
      AppTheme.setTestMode(false);
      
      // En modo producción, debería intentar usar Google Fonts
      // Pero como estamos en un test, isTestEnvironment seguirá siendo true
      expect(AppTheme.isTestEnvironment, isTrue);
      
      // El fontFamily seguirá siendo del sistema porque estamos en test
      final fontFamily = AppTheme.fontFamily;
      if (Platform.isIOS) {
        expect(fontFamily, equals('SF Pro Text'));
      } else if (Platform.isAndroid) {
        expect(fontFamily, equals('Roboto'));
      }
    });

    test('Should create text styles without ScreenUtil dependency', () {
      AppTheme.setTestMode(true);
      
      // Crear un estilo simple sin usar .sp
      final style = AppTheme.getTextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14.0,
      );
      
      expect(style, isNotNull);
      expect(style.fontWeight, equals(FontWeight.w600));
      expect(style.fontSize, equals(14.0));
      expect(style.fontFamily, equals(AppTheme.fontFamily));
    });
  });
}
