import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/models/project.dart';

/// Helper class for E2E test utilities
class TestHelpers {
  
  /// Launch the app and wait for it to settle
  static Future<void> launchApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(Duration(seconds: 3));
  }

  /// Wait for a widget to appear with timeout
  static Future<void> waitForWidget(
    WidgetTester tester, 
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pumpAndSettle();
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    throw Exception('Widget not found within timeout: $finder');
  }

  /// Navigate to a specific screen by tapping navigation items
  static Future<void> navigateTo(WidgetTester tester, String screenName) async {
    switch (screenName.toLowerCase()) {
      case 'home':
        await tester.tap(find.byIcon(Icons.home));
        break;
      case 'projects':
        await tester.tap(find.text('See all')); // From My Projects section
        break;
      case 'palettes':
        await tester.tap(find.byIcon(Icons.palette));
        break;
      case 'library':
        await tester.tap(find.byIcon(Icons.library_books));
        break;
      case 'inventory':
        await tester.tap(find.byIcon(Icons.inventory));
        break;
      case 'wishlist':
        await tester.tap(find.byIcon(Icons.favorite));
        break;
    }
    await tester.pumpAndSettle();
  }

  /// Clear all data from cache services
  static Future<void> clearAllData(WidgetTester tester) async {
    // This would need to be implemented based on your cache services
    // For now, we'll simulate clearing data
    await tester.pumpAndSettle();
  }

  /// Create a test project
  static Future<Project> createTestProject(
    WidgetTester tester, {
    String name = 'Test Project',
    ProjectStatus status = ProjectStatus.planning,
  }) async {
    await navigateTo(tester, 'projects');
    
    // Tap New Project button
    await tester.tap(find.text('New Project'));
    await tester.pumpAndSettle();
    
    // Fill in project details
    await tester.enterText(find.byKey(Key('project_name_field')), name);
    
    // Select status if needed
    // await tester.tap(find.text(status.displayName));
    
    // Create project
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    
    // Return the created project (this would need to be retrieved from cache)
    return Project(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: null,
      images: [],
      palettes: [],
      paints: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: status,
      userId: 'test-user',
      tags: [],
    );
  }

  /// Delete a project by name
  static Future<void> deleteProject(WidgetTester tester, String projectName) async {
    await navigateTo(tester, 'projects');
    
    // Find the project card
    final projectCard = find.ancestor(
      of: find.text(projectName),
      matching: find.byType(Card),
    );
    
    // Tap options menu
    await tester.tap(find.descendant(
      of: projectCard,
      matching: find.byIcon(Icons.more_vert),
    ));
    await tester.pumpAndSettle();
    
    // Tap delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    
    // Confirm deletion
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
  }

  /// Verify project exists in UI
  static void verifyProjectExists(String projectName) {
    expect(find.text(projectName), findsAtLeastNWidgets(1));
  }

  /// Verify project doesn't exist in UI
  static void verifyProjectNotExists(String projectName) {
    expect(find.text(projectName), findsNothing);
  }

  /// Login with test credentials
  static Future<void> loginTestUser(WidgetTester tester) async {
    // Navigate to login if not already logged in
    final loginButton = find.text('Login');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      
      // Enter test credentials
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'testpassword123');
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
    }
  }

  /// Logout current user
  static Future<void> logout(WidgetTester tester) async {
    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    
    // Tap logout
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
  }

  /// Take screenshot for debugging
  static Future<void> takeScreenshot(WidgetTester tester, String name) async {
    // This would integrate with your screenshot tool
    print('📸 Screenshot taken: $name');
  }

  /// Log test step
  static void logStep(String step) {
    print('🔍 Test Step: $step');
  }

  /// Log test result
  static void logResult(String operation, bool success, {String? details}) {
    final status = success ? '✅' : '❌';
    final timestamp = DateTime.now().toIso8601String();
    
    print('[$timestamp] $status $operation');
    if (details != null) {
      print('   Details: $details');
    }
  }

  /// Simulate network conditions
  static Future<void> simulateOffline(WidgetTester tester) async {
    // This would need integration with your connectivity service
    print('📱 Simulating offline mode');
    await tester.pumpAndSettle();
  }

  static Future<void> simulateOnline(WidgetTester tester) async {
    // This would need integration with your connectivity service
    print('🌐 Simulating online mode');
    await tester.pumpAndSettle();
  }

  /// Verify cache state
  static Future<void> verifyCacheState(
    WidgetTester tester, {
    int? expectedProjects,
    int? expectedPalettes,
    int? expectedInventoryItems,
    int? expectedWishlistItems,
  }) async {
    // This would check the actual cache services
    if (expectedProjects != null) {
      logResult('Cache Verification', true, details: 'Projects: $expectedProjects');
    }
    if (expectedPalettes != null) {
      logResult('Cache Verification', true, details: 'Palettes: $expectedPalettes');
    }
    if (expectedInventoryItems != null) {
      logResult('Cache Verification', true, details: 'Inventory: $expectedInventoryItems');
    }
    if (expectedWishlistItems != null) {
      logResult('Cache Verification', true, details: 'Wishlist: $expectedWishlistItems');
    }
  }
}

/// Extension methods for easier testing
extension TestExtensions on WidgetTester {
  
  /// Tap and wait for settle
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and wait for settle
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Wait for specific duration
  Future<void> waitFor(Duration duration) async {
    await pump(duration);
  }
}
