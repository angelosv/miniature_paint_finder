import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🧪 Simple E2E Test', () {
    testWidgets('App launches successfully', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));

      // Verify app launched
      expect(find.byType(MaterialApp), findsOneWidget);
      
      print('✅ App launched successfully');
    });

    testWidgets('Home screen loads', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 10));

      // Look for home screen elements
      final homeElements = [
        'My Projects',
        'Recent Palettes',
        'Paints',
      ];

      bool foundHomeElement = false;
      for (final element in homeElements) {
        if (find.text(element).evaluate().isNotEmpty) {
          foundHomeElement = true;
          print('✅ Found home element: $element');
          break;
        }
      }

      expect(foundHomeElement, true, reason: 'No home screen elements found');
    });
  });
}
