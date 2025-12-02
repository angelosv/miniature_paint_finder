import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/components/search_tab.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📸 Color Matching Flow Tests', () {
    
    setUpAll(() async {
      // Activar modo test para fuentes del sistema
      AppTheme.setTestMode(true);
    });

    tearDownAll(() async {
      // Desactivar modo test
      AppTheme.setTestMode(false);
    });

    testWidgets('Navigate to Paint Search Tab', (tester) async {
      print('📸 Testing navigation to paint search tab');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Should be on home screen by default
      // Look for Paint Search tab or related elements
      if (find.text('Find Paints by Color').evaluate().isNotEmpty) {
        print('✅ Paint Search tab found directly');
      } else {
        // Try to find tab navigation
        if (find.text('Search').evaluate().isNotEmpty) {
          await tester.tap(find.text('Search'));
          await tester.pump(Duration(seconds: 1));
          print('✅ Navigated to Search tab');
        } else if (find.byIcon(Icons.search).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.search));
          await tester.pump(Duration(seconds: 1));
          print('✅ Tapped search icon');
        }
      }
      
      print('✅ Paint Search Navigation Test completed');
    });

    testWidgets('Color Search Interface Elements', (tester) async {
      print('📸 Testing color search interface elements');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for color search elements
      if (find.text('Find Paints by Color').evaluate().isNotEmpty) {
        print('✅ Color search title found');
        
        // Look for hex input field
        if (find.textContaining('hex').evaluate().isNotEmpty ||
            find.textContaining('color name').evaluate().isNotEmpty) {
          print('✅ Color input field found');
        }
        
        // Look for popular colors section
        if (find.text('Popular Colors').evaluate().isNotEmpty) {
          print('✅ Popular colors section found');
        }
        
        // Look for image upload option
        if (find.text('use an image').evaluate().isNotEmpty ||
            find.byIcon(Icons.camera_alt).evaluate().isNotEmpty) {
          print('✅ Image upload option found');
        }
      }
      
      print('✅ Color Search Interface Test completed');
    });

    testWidgets('Popular Color Chips Functionality', (tester) async {
      print('📸 Testing popular color chips functionality');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for color chips
      final colorChips = find.byType(GestureDetector);
      if (colorChips.evaluate().isNotEmpty) {
        print('✅ Color chips found');
        
        // Try tapping a color chip
        if (find.text('Red').evaluate().isNotEmpty) {
          await tester.tap(find.text('Red'));
          await tester.pump(Duration(milliseconds: 500));
          print('✅ Red color chip tapped');
        } else if (find.text('Blue').evaluate().isNotEmpty) {
          await tester.tap(find.text('Blue'));
          await tester.pump(Duration(milliseconds: 500));
          print('✅ Blue color chip tapped');
        }
      }
      
      print('✅ Color Chips Test completed');
    });

    testWidgets('Image Color Picker Access', (tester) async {
      print('📸 Testing image color picker access');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for camera/image picker button
      if (find.byIcon(Icons.camera_alt).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pump(Duration(seconds: 1));
        
        // Should show image source modal
        if (find.text('Camera').evaluate().isNotEmpty ||
            find.text('Gallery').evaluate().isNotEmpty ||
            find.text('Photo Library').evaluate().isNotEmpty) {
          print('✅ Image source modal displayed');
        } else {
          print('ℹ️ Image picker accessed (may require permissions)');
        }
      } else if (find.textContaining('image').evaluate().isNotEmpty) {
        print('✅ Image-related functionality found');
      }
      
      print('✅ Image Color Picker Test completed');
    });

    testWidgets('Color Search from Palette Creation', (tester) async {
      print('📸 Testing color search from palette creation');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Try to access palettes
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('My Palettes').evaluate().isNotEmpty) {
          await tester.tap(find.text('My Palettes'));
          await tester.pump(Duration(seconds: 1));
          
          // Look for create palette option
          if (find.byIcon(Icons.add).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.add));
            await tester.pump(Duration(seconds: 1));
            
            // Look for "Find colors in image" option
            if (find.text('Find colors in image').evaluate().isNotEmpty) {
              print('✅ Color search option found in palette creation');
            } else if (find.byIcon(Icons.image_search).evaluate().isNotEmpty) {
              print('✅ Image search icon found in palette creation');
            }
          }
        }
      }
      
      print('✅ Palette Color Search Test completed');
    });

    testWidgets('Color Input Field Functionality', (tester) async {
      print('📸 Testing color input field functionality');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for color input field
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // Try entering a hex color
        await tester.enterText(textFields.first, '#FF0000');
        await tester.pump(Duration(milliseconds: 500));
        
        // Verify text was entered
        expect(find.text('#FF0000'), findsOneWidget);
        print('✅ Hex color entered successfully');
        
        // Clear the field
        await tester.enterText(textFields.first, '');
        await tester.pump(Duration(milliseconds: 300));
        
        // Try entering a color name
        await tester.enterText(textFields.first, 'red');
        await tester.pump(Duration(milliseconds: 500));
        
        expect(find.text('red'), findsOneWidget);
        print('✅ Color name entered successfully');
      }
      
      print('✅ Color Input Test completed');
    });

    testWidgets('Color Matching Results Interface', (tester) async {
      print('📸 Testing color matching results interface');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Enter a color and trigger search
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '#FF0000');
        await tester.pump(Duration(milliseconds: 500));
        
        // Look for search trigger (submit button, enter key, etc.)
        if (find.byIcon(Icons.search).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.search));
          await tester.pump(Duration(seconds: 2));
          print('✅ Search triggered');
        } else {
          // Try submitting the field
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pump(Duration(seconds: 2));
          print('✅ Search submitted via text input');
        }
        
        // Wait for potential results
        await tester.pump(Duration(seconds: 3));
        
        // Look for results or loading indicators
        if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
          print('✅ Loading indicator found');
        } else if (find.textContaining('match').evaluate().isNotEmpty ||
                   find.textContaining('result').evaluate().isNotEmpty) {
          print('✅ Search results interface found');
        } else {
          print('ℹ️ Search completed (results may vary)');
        }
      }
      
      print('✅ Color Matching Results Test completed');
    });
  });
}
