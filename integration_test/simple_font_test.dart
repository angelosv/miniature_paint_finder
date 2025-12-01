import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/theme/app_theme.dart';

import 'test_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔤 Font System Tests', () {
    setUpAll(() async {
      await TestSetup.setupTestEnvironment();
    });

    tearDownAll(() async {
      await TestSetup.tearDownTestEnvironment();
    });

    testWidgets('Should use system fonts in test environment', (tester) async {
      // Verificar que estamos en entorno de testing
      expect(AppTheme.isTestEnvironment, isTrue);
      
      // Verificar que se usa fuente del sistema
      final fontFamily = AppTheme.fontFamily;
      expect(fontFamily, isNotNull);
      
      // La fuente debe ser del sistema (no Google Fonts)
      expect(fontFamily, isNot(contains('Poppins')));
      
      print('✅ Using system font: $fontFamily');
    });

    testWidgets('Should load app with system fonts', (tester) async {
      // Inicializar la aplicación
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verificar que la app se carga correctamente
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Buscar cualquier texto en la pantalla
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsAtLeastNWidgets(1));
      
      print('✅ App loaded successfully with system fonts');
    });

    testWidgets('Should render text styles correctly', (tester) async {
      // Crear un widget de prueba con diferentes estilos
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                Text('Heading', style: AppTheme.headingStyle),
                Text('Subheading', style: AppTheme.subheadingStyle),
                Text('Body', style: AppTheme.bodyStyle),
                Text('Button', style: AppTheme.buttonStyle),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que todos los textos se renderizan
      expect(find.text('Heading'), findsOneWidget);
      expect(find.text('Subheading'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);

      print('✅ All text styles render correctly');
    });
  });
}

