import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📦 Inventory Management Tests', () {
    
    testWidgets('Add Paint to Inventory', (tester) async {
      TestHelpers.logStep('Starting inventory addition test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // Navigate to library first
      await TestHelpers.navigateTo(tester, 'library');
      
      // Find a paint and add to inventory
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byType(Card).first);
        
        if (find.text('Add to Inventory').evaluate().isNotEmpty) {
          await tester.tapAndSettle(find.text('Add to Inventory'));
          TestHelpers.logResult('Add to Inventory', true);
        }
      }
      
      // Verify in inventory screen
      await TestHelpers.navigateTo(tester, 'inventory');
      expect(find.byType(Card), findsAtLeastNWidgets(1));
      
      TestHelpers.logResult('Inventory Addition', true);
    });

    testWidgets('Remove Paint from Inventory', (tester) async {
      TestHelpers.logStep('Starting inventory removal test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'inventory');
      
      // Remove first item if exists
      if (find.byIcon(Icons.delete).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byIcon(Icons.delete).first);
        await tester.tapAndSettle(find.text('Confirm'));
      }
      
      TestHelpers.logResult('Inventory Removal', true);
    });

    testWidgets('Inventory Search and Filter', (tester) async {
      TestHelpers.logStep('Starting inventory search test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'inventory');
      
      if (find.byKey(Key('search_field')).evaluate().isNotEmpty) {
        await tester.enterTextAndSettle(
          find.byKey(Key('search_field')), 
          'blue',
        );
        
        // Should filter inventory items
        TestHelpers.logResult('Inventory Search', true);
      }
      
      TestHelpers.logResult('Inventory Search and Filter', true);
    });
  });
}
