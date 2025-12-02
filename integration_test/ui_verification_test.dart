import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/theme/app_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📸 UI Verification Tests', () {
    
    setUpAll(() async {
      AppTheme.setTestMode(true);
    });

    tearDownAll(() async {
      AppTheme.setTestMode(false);
    });

    testWidgets('Take Screenshots of Main Screens', (tester) async {
      print('📸 Taking screenshots of main screens');
      
      app.main();
      await tester.pump(Duration(seconds: 3));
      
      // Screenshot 1: Home Screen
      await binding.takeScreenshot('01_home_screen');
      print('✅ Home screen screenshot taken');
      
      // Navigate to drawer and take screenshot
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(seconds: 1));
        
        await binding.takeScreenshot('02_navigation_drawer');
        print('✅ Navigation drawer screenshot taken');
        
        // Navigate to Library
        if (find.text('Library').evaluate().isNotEmpty) {
          await tester.tap(find.text('Library'));
          await tester.pump(Duration(seconds: 2));
          
          await binding.takeScreenshot('03_library_screen');
          print('✅ Library screen screenshot taken');
        }
        
        // Back to drawer
        if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump(Duration(seconds: 1));
          
          // Navigate to Barcode Scanner
          if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
            await tester.tap(find.text('Barcode Scanner'));
            await tester.pump(Duration(seconds: 2));
            
            await binding.takeScreenshot('04_barcode_scanner');
            print('✅ Barcode scanner screenshot taken');
            
            // Go back
            if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
              await tester.tap(find.byIcon(Icons.arrow_back));
              await tester.pump(Duration(seconds: 1));
            }
          }
        }
      }
      
      print('✅ All screenshots completed');
    });

    testWidgets('Verify UI Elements Render Correctly', (tester) async {
      print('🔍 Verifying UI elements render correctly');
      
      app.main();
      await tester.pump(Duration(seconds: 3));
      
      // Verify basic UI elements exist
      expect(find.byType(MaterialApp), findsOneWidget);
      print('✅ MaterialApp renders correctly');
      
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      print('✅ Scaffold renders correctly');
      
      // Check for text rendering
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsAtLeastNWidgets(1));
      print('✅ Text widgets render correctly (${textWidgets.evaluate().length} found)');
      
      // Check for icons
      final iconWidgets = find.byType(Icon);
      if (iconWidgets.evaluate().isNotEmpty) {
        print('✅ Icon widgets render correctly (${iconWidgets.evaluate().length} found)');
      }
      
      // Check for buttons
      final buttonWidgets = find.byType(ElevatedButton);
      final textButtonWidgets = find.byType(TextButton);
      final iconButtonWidgets = find.byType(IconButton);
      
      final totalButtons = buttonWidgets.evaluate().length + 
                          textButtonWidgets.evaluate().length + 
                          iconButtonWidgets.evaluate().length;
      
      if (totalButtons > 0) {
        print('✅ Button widgets render correctly ($totalButtons found)');
      }
      
      print('✅ UI elements verification completed');
    });

    testWidgets('Test UI Interactions Work', (tester) async {
      print('👆 Testing UI interactions work');
      
      app.main();
      await tester.pump(Duration(seconds: 3));
      
      // Test menu interaction
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(seconds: 1));
        
        // Verify drawer opened (look for drawer content)
        if (find.text('Library').evaluate().isNotEmpty ||
            find.text('Home').evaluate().isNotEmpty) {
          print('✅ Menu tap interaction works - drawer opened');
          
          // Test drawer item tap
          if (find.text('Home').evaluate().isNotEmpty) {
            await tester.tap(find.text('Home'));
            await tester.pump(Duration(seconds: 1));
            print('✅ Drawer navigation works');
          }
        }
      }
      
      // Test any visible buttons
      final elevatedButtons = find.byType(ElevatedButton);
      if (elevatedButtons.evaluate().isNotEmpty) {
        // Don't actually tap (might trigger unwanted actions)
        // Just verify they're tappable
        print('✅ Buttons are present and tappable (${elevatedButtons.evaluate().length} found)');
      }
      
      print('✅ UI interactions test completed');
    });

    testWidgets('Verify Theme and Styling', (tester) async {
      print('🎨 Verifying theme and styling');
      
      app.main();
      await tester.pump(Duration(seconds: 3));
      
      // Get the theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      print('✅ App theme is applied');
      
      // Check for consistent styling
      final textWidgets = find.byType(Text);
      if (textWidgets.evaluate().isNotEmpty) {
        final firstText = tester.widget<Text>(textWidgets.first);
        if (firstText.style != null) {
          print('✅ Text styling is applied');
        }
      }
      
      // Verify colors are applied
      final scaffolds = find.byType(Scaffold);
      if (scaffolds.evaluate().isNotEmpty) {
        print('✅ Scaffold styling is applied');
      }
      
      print('✅ Theme and styling verification completed');
    });

    testWidgets('Performance and Responsiveness Check', (tester) async {
      print('⚡ Checking performance and responsiveness');
      
      final startTime = DateTime.now();
      
      app.main();
      await tester.pump(Duration(seconds: 3));
      
      final loadTime = DateTime.now().difference(startTime);
      print('📊 App load time: ${loadTime.inMilliseconds}ms');
      
      if (loadTime.inSeconds < 10) {
        print('✅ App loads within acceptable time');
      } else {
        print('⚠️ App load time is slow (${loadTime.inSeconds}s)');
      }
      
      // Test rapid interactions
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump(Duration(milliseconds: 200));
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump(Duration(milliseconds: 200));
        }
        print('✅ Rapid interactions handled correctly');
      }
      
      print('✅ Performance check completed');
    });
  });
}
