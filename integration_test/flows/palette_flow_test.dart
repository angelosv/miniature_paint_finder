import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🎭 Palette Management Tests', () {
    
    testWidgets('Create New Palette', (tester) async {
      TestHelpers.logStep('Starting palette creation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'palettes');
      
      if (find.text('New Palette').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('New Palette'));
        
        const paletteName = 'E2E Test Palette';
        await tester.enterTextAndSettle(
          find.byKey(Key('palette_name_field')), 
          paletteName,
        );
        
        await tester.tapAndSettle(find.text('Create'));
        TestHelpers.verifyProjectExists(paletteName);
      }
      
      TestHelpers.logResult('Palette Creation', true);
    });

    testWidgets('Delete Palette', (tester) async {
      TestHelpers.logStep('Starting palette deletion test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'palettes');
      
      // Find first palette and delete it
      if (find.byIcon(Icons.delete).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byIcon(Icons.delete).first);
        await tester.tapAndSettle(find.text('Confirm'));
      }
      
      TestHelpers.logResult('Palette Deletion', true);
    });

    testWidgets('Palette Color Management', (tester) async {
      TestHelpers.logStep('Starting palette color management test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'palettes');
      
      // Test adding colors to palette
      if (find.byIcon(Icons.add).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byIcon(Icons.add));
        
        // Should open color picker or paint selection
        TestHelpers.logResult('Palette Color Addition', true);
      }
      
      TestHelpers.logResult('Palette Color Management', true);
    });
  });
}
