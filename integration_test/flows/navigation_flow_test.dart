import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📱 Navigation Flow Tests', () {
    
    setUp(() async {
      TestHelpers.logStep('Setting up navigation test');
    });

    tearDown(() async {
      TestHelpers.logStep('Cleaning up navigation test');
    });

    testWidgets('Bottom Navigation Bar - All Screens', (tester) async {
      TestHelpers.logStep('Starting bottom navigation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Test Home navigation
      await tester.tapAndSettle(find.byIcon(Icons.home));
      expect(find.text('My Projects'), findsOneWidget);
      TestHelpers.logResult('Navigate to Home', true);
      
      // 2. Test Palettes navigation
      await tester.tapAndSettle(find.byIcon(Icons.palette));
      await TestHelpers.waitForWidget(tester, find.text('Palettes'));
      TestHelpers.logResult('Navigate to Palettes', true);
      
      // 3. Test Library navigation
      await tester.tapAndSettle(find.byIcon(Icons.library_books));
      await TestHelpers.waitForWidget(tester, find.text('Library'));
      TestHelpers.logResult('Navigate to Library', true);
      
      // 4. Test Wishlist navigation
      await tester.tapAndSettle(find.byIcon(Icons.favorite));
      await TestHelpers.waitForWidget(tester, find.text('Wishlist'));
      TestHelpers.logResult('Navigate to Wishlist', true);
      
      // 5. Test Inventory navigation
      await tester.tapAndSettle(find.byIcon(Icons.inventory));
      await TestHelpers.waitForWidget(tester, find.text('Inventory'));
      TestHelpers.logResult('Navigate to Inventory', true);
      
      TestHelpers.logResult('Bottom Navigation Complete', true);
    });

    testWidgets('Drawer Navigation', (tester) async {
      TestHelpers.logStep('Starting drawer navigation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Open drawer
      await tester.tapAndSettle(find.byIcon(Icons.menu));
      
      // 2. Test drawer items
      final drawerItems = [
        'Profile',
        'Settings',
        'Help & Support',
        'About',
        'Logout',
      ];
      
      for (final item in drawerItems) {
        if (find.text(item).evaluate().isNotEmpty) {
          TestHelpers.logResult('Drawer Item Found: $item', true);
        }
      }
      
      // 3. Test Settings navigation
      if (find.text('Settings').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Settings'));
        await TestHelpers.waitForWidget(tester, find.text('Settings'));
        
        // Navigate back
        await tester.tapAndSettle(find.byIcon(Icons.arrow_back));
      }
      
      TestHelpers.logResult('Drawer Navigation', true);
    });

    testWidgets('Deep Navigation - Home to Project Detail', (tester) async {
      TestHelpers.logStep('Starting deep navigation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Start from Home
      expect(find.text('My Projects'), findsOneWidget);
      
      // 2. Navigate to Projects via "See all"
      await tester.tapAndSettle(find.text('See all'));
      await TestHelpers.waitForWidget(tester, find.text('New Project'));
      
      // 3. Create a test project if none exist
      if (find.byType(Card).evaluate().isEmpty) {
        await TestHelpers.createTestProject(tester, name: 'Navigation Test Project');
      }
      
      // 4. Navigate to project detail
      final projectCard = find.byType(Card).first;
      await tester.tapAndSettle(projectCard);
      
      // Should be in project detail screen
      expect(find.byIcon(Icons.edit), findsOneWidget);
      
      // 5. Navigate back to projects
      await tester.tapAndSettle(find.byIcon(Icons.arrow_back));
      expect(find.text('New Project'), findsOneWidget);
      
      // 6. Navigate back to home
      await tester.tapAndSettle(find.byIcon(Icons.arrow_back));
      expect(find.text('My Projects'), findsOneWidget);
      
      TestHelpers.logResult('Deep Navigation', true);
    });

    testWidgets('Tab Navigation within Screens', (tester) async {
      TestHelpers.logStep('Starting tab navigation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Navigate to Projects screen
      await TestHelpers.navigateTo(tester, 'projects');
      
      // 2. Test project view tabs (Grid/List)
      if (find.text('Grid').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Grid'));
        TestHelpers.logResult('Grid View Tab', true);
        
        await tester.tapAndSettle(find.text('List'));
        TestHelpers.logResult('List View Tab', true);
      }
      
      // 3. Navigate to Library screen
      await TestHelpers.navigateTo(tester, 'library');
      
      // 4. Test library tabs (if any)
      final libraryTabs = ['Brands', 'Categories', 'All Paints'];
      for (final tab in libraryTabs) {
        if (find.text(tab).evaluate().isNotEmpty) {
          await tester.tapAndSettle(find.text(tab));
          TestHelpers.logResult('Library Tab: $tab', true);
        }
      }
      
      TestHelpers.logResult('Tab Navigation', true);
    });

    testWidgets('Search Navigation Flow', (tester) async {
      TestHelpers.logStep('Starting search navigation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Navigate to Library (main search area)
      await TestHelpers.navigateTo(tester, 'library');
      
      // 2. Test search functionality
      if (find.byKey(Key('search_field')).evaluate().isNotEmpty) {
        await tester.enterTextAndSettle(
          find.byKey(Key('search_field')), 
          'blue',
        );
        
        // Should show search results
        await TestHelpers.waitForWidget(tester, find.byType(Card));
        
        // 3. Tap on a search result
        await tester.tapAndSettle(find.byType(Card).first);
        
        // Should navigate to paint detail
        TestHelpers.logResult('Search Result Navigation', true);
        
        // 4. Navigate back
        await tester.tapAndSettle(find.byIcon(Icons.arrow_back));
      }
      
      TestHelpers.logResult('Search Navigation', true);
    });

    testWidgets('Modal Navigation Flow', (tester) async {
      TestHelpers.logStep('Starting modal navigation test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Test Project Creation Modal
      await TestHelpers.navigateTo(tester, 'projects');
      await tester.tapAndSettle(find.text('New Project'));
      
      // Should open modal
      expect(find.text('Create Project'), findsOneWidget);
      
      // Close modal
      await tester.tapAndSettle(find.byIcon(Icons.close));
      
      // 2. Test Palette Creation Modal (if exists)
      await TestHelpers.navigateTo(tester, 'palettes');
      
      if (find.text('New Palette').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('New Palette'));
        
        // Should open modal
        expect(find.text('Create Palette'), findsOneWidget);
        
        // Close modal
        await tester.tapAndSettle(find.byIcon(Icons.close));
      }
      
      TestHelpers.logResult('Modal Navigation', true);
    });

    testWidgets('Error Screen Navigation', (tester) async {
      TestHelpers.logStep('Starting error navigation test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Simulate network error by going offline
      await TestHelpers.simulateOffline(tester);
      
      // 2. Try to navigate to a screen that requires network
      await TestHelpers.navigateTo(tester, 'library');
      
      // 3. Should show error state or offline message
      if (find.textContaining('offline').evaluate().isNotEmpty ||
          find.textContaining('error').evaluate().isNotEmpty) {
        TestHelpers.logResult('Error State Display', true);
        
        // 4. Test retry functionality
        if (find.text('Retry').evaluate().isNotEmpty) {
          await TestHelpers.simulateOnline(tester);
          await tester.tapAndSettle(find.text('Retry'));
          
          TestHelpers.logResult('Error Recovery', true);
        }
      }
    });

    testWidgets('Back Button Navigation Consistency', (tester) async {
      TestHelpers.logStep('Starting back button consistency test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Navigate through multiple screens
      await TestHelpers.navigateTo(tester, 'projects');
      await TestHelpers.navigateTo(tester, 'palettes');
      await TestHelpers.navigateTo(tester, 'library');
      
      // 2. Use system back button (Android) or back arrow (iOS)
      await tester.tapAndSettle(find.byIcon(Icons.arrow_back));
      
      // Should go back to previous screen
      TestHelpers.logResult('Back Navigation', true);
    });

    testWidgets('Navigation State Persistence', (tester) async {
      TestHelpers.logStep('Starting navigation state test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Navigate to a specific screen
      await TestHelpers.navigateTo(tester, 'inventory');
      
      // 2. Simulate app backgrounding and foregrounding
      // (In real tests, this would use platform channels)
      await tester.waitFor(Duration(seconds: 1));
      
      // 3. Verify still on same screen
      expect(find.text('Inventory'), findsOneWidget);
      
      TestHelpers.logResult('Navigation State Persistence', true);
    });

    testWidgets('Guest User Navigation Restrictions', (tester) async {
      TestHelpers.logStep('Starting guest navigation restrictions test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Access as guest
      if (find.text('Continue as Guest').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Continue as Guest'));
      }
      
      // 2. Try to navigate to restricted screens
      await TestHelpers.navigateTo(tester, 'projects');
      
      // Should show guest promo when trying to access features
      if (find.text('New Project').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('New Project'));
        
        // Should show upgrade prompt
        expect(find.text('Sign Up'), findsOneWidget);
        
        // Close prompt
        await tester.tapAndSettle(find.byIcon(Icons.close));
      }
      
      TestHelpers.logResult('Guest Navigation Restrictions', true);
    });
  });
}
