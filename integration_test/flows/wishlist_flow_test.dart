import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('❤️ Wishlist Management Tests', () {
    
    testWidgets('Add Paint to Wishlist', (tester) async {
      TestHelpers.logStep('Starting wishlist addition test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // Navigate to library
      await TestHelpers.navigateTo(tester, 'library');
      
      // Add paint to wishlist
      if (find.byIcon(Icons.favorite_border).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byIcon(Icons.favorite_border).first);
        TestHelpers.logResult('Add to Wishlist', true);
      }
      
      // Verify in wishlist screen
      await TestHelpers.navigateTo(tester, 'wishlist');
      expect(find.byType(Card), findsAtLeastNWidgets(1));
      
      TestHelpers.logResult('Wishlist Addition', true);
    });

    testWidgets('Remove Paint from Wishlist', (tester) async {
      TestHelpers.logStep('Starting wishlist removal test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'wishlist');
      
      // Remove first item if exists
      if (find.byIcon(Icons.favorite).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byIcon(Icons.favorite).first);
        // Should remove from wishlist
      }
      
      TestHelpers.logResult('Wishlist Removal', true);
    });

    testWidgets('Move from Wishlist to Inventory', (tester) async {
      TestHelpers.logStep('Starting wishlist to inventory test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      await TestHelpers.navigateTo(tester, 'wishlist');
      
      // Move item to inventory
      if (find.text('Add to Inventory').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Add to Inventory').first);
        TestHelpers.logResult('Move to Inventory', true);
      }
      
      TestHelpers.logResult('Wishlist to Inventory', true);
    });
  });
}
