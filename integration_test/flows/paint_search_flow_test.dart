import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔍 Paint Search Flow Tests', () {
    
    setUpAll(() async {
      // Activar modo test para fuentes del sistema
      AppTheme.setTestMode(true);
    });

    tearDownAll(() async {
      // Desactivar modo test
      AppTheme.setTestMode(false);
    });

    testWidgets('Navigate to Library Screen', (tester) async {
      print('🔍 Testing navigation to library screen');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for library navigation - could be in drawer or bottom nav
      if (find.byIcon(Icons.library_books).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.library_books));
        await tester.pump(Duration(seconds: 1));
      } else if (find.text('Library').evaluate().isNotEmpty) {
        await tester.tap(find.text('Library'));
        await tester.pump(Duration(seconds: 1));
      } else {
        // Try opening drawer first
        if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump(Duration(milliseconds: 500));
          
          if (find.text('Library').evaluate().isNotEmpty) {
            await tester.tap(find.text('Library'));
            await tester.pump(Duration(seconds: 1));
          }
        }
      }
      
      // Verify we're in the library screen
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      
      print('✅ Library Navigation successful');
    });

    testWidgets('Search Field Functionality', (tester) async {
      print('🔍 Testing search field functionality');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Navigate to library (simplified)
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('Library').evaluate().isNotEmpty) {
          await tester.tap(find.text('Library'));
          await tester.pump(Duration(seconds: 1));
        }
      }
      
      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsAtLeastNWidgets(1));
      
      // Test typing in search field
      await tester.enterText(searchField.first, 'red');
      await tester.pump(Duration(milliseconds: 500));
      
      // Verify text was entered
      expect(find.text('red'), findsOneWidget);
      
      print('✅ Search Field Functionality successful');
    });

    testWidgets('Basic Library Screen Test', (tester) async {
      print('🔍 Testing basic library screen functionality');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Simple test - just verify app launches and has basic elements
      expect(find.byType(MaterialApp), findsOneWidget);
      
      print('✅ Basic Library Screen Test successful');
    });
  });
}
