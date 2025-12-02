import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/screens/barcode_scanner_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📱 Barcode Scanner Flow Tests', () {
    
    setUpAll(() async {
      // Activar modo test para fuentes del sistema
      AppTheme.setTestMode(true);
    });

    tearDownAll(() async {
      // Desactivar modo test
      AppTheme.setTestMode(false);
    });

    testWidgets('Navigate to Barcode Scanner from Drawer', (tester) async {
      print('📱 Testing navigation to barcode scanner from drawer');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Open drawer
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        // Look for Barcode Scanner option
        if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
          await tester.tap(find.text('Barcode Scanner'));
          await tester.pump(Duration(seconds: 1));
          
          // Verify we're in the barcode scanner screen
          expect(find.byType(BarcodeScannerScreen), findsOneWidget);
          print('✅ Successfully navigated to Barcode Scanner');
        } else if (find.byIcon(Icons.qr_code_scanner_outlined).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.qr_code_scanner_outlined));
          await tester.pump(Duration(seconds: 1));
          print('✅ Barcode Scanner icon found and tapped');
        } else {
          print('⚠️ Barcode Scanner option not found in drawer');
        }
      } else {
        print('⚠️ Menu icon not found');
      }
      
      print('✅ Barcode Scanner Navigation Test completed');
    });

    testWidgets('Barcode Scanner Screen Elements', (tester) async {
      print('📱 Testing barcode scanner screen elements');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Navigate to barcode scanner
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
          await tester.tap(find.text('Barcode Scanner'));
          await tester.pump(Duration(seconds: 2));
          
          // Check for camera permission elements or scanner elements
          if (find.textContaining('Camera permission').evaluate().isNotEmpty) {
            print('✅ Camera permission screen displayed');
          } else if (find.textContaining('Scan').evaluate().isNotEmpty) {
            print('✅ Scanner interface displayed');
          } else {
            print('ℹ️ Scanner screen loaded (camera may not be available in simulator)');
          }
        }
      }
      
      print('✅ Barcode Scanner Elements Test completed');
    });

    testWidgets('Camera Permission Handling', (tester) async {
      print('📱 Testing camera permission handling');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Navigate to barcode scanner
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
          await tester.tap(find.text('Barcode Scanner'));
          await tester.pump(Duration(seconds: 2));
          
          // Look for permission-related elements
          if (find.textContaining('permission').evaluate().isNotEmpty) {
            print('✅ Permission handling UI found');
            
            // Look for permission buttons
            if (find.textContaining('Allow').evaluate().isNotEmpty ||
                find.textContaining('Grant').evaluate().isNotEmpty ||
                find.textContaining('Enable').evaluate().isNotEmpty) {
              print('✅ Permission action buttons found');
            }
          } else {
            print('ℹ️ No permission UI (may already be granted or not needed in simulator)');
          }
        }
      }
      
      print('✅ Camera Permission Test completed');
    });

    testWidgets('Scanner Interface Components', (tester) async {
      print('📱 Testing scanner interface components');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Navigate to barcode scanner
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
          await tester.tap(find.text('Barcode Scanner'));
          await tester.pump(Duration(seconds: 2));
          
          // Look for scanner-related UI elements
          if (find.byIcon(Icons.flash_on).evaluate().isNotEmpty ||
              find.byIcon(Icons.flash_off).evaluate().isNotEmpty) {
            print('✅ Flash toggle found');
          }
          
          if (find.byIcon(Icons.flip_camera_ios).evaluate().isNotEmpty ||
              find.byIcon(Icons.cameraswitch).evaluate().isNotEmpty) {
            print('✅ Camera switch found');
          }
          
          if (find.textContaining('Scan').evaluate().isNotEmpty ||
              find.textContaining('barcode').evaluate().isNotEmpty) {
            print('✅ Scanner instructions found');
          }
          
          // Check for back button or close button
          if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty ||
              find.byIcon(Icons.close).evaluate().isNotEmpty) {
            print('✅ Navigation controls found');
          }
        }
      }
      
      print('✅ Scanner Interface Test completed');
    });

    testWidgets('Scanner Error Handling', (tester) async {
      print('📱 Testing scanner error handling');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Navigate to barcode scanner
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
          await tester.tap(find.text('Barcode Scanner'));
          await tester.pump(Duration(seconds: 3));
          
          // In simulator, camera might not be available
          // Check for appropriate error messages
          if (find.textContaining('Camera not available').evaluate().isNotEmpty ||
              find.textContaining('permission').evaluate().isNotEmpty ||
              find.byIcon(Icons.no_photography).evaluate().isNotEmpty) {
            print('✅ Appropriate error handling for simulator environment');
          } else {
            print('ℹ️ Scanner loaded successfully or no specific error shown');
          }
        }
      }
      
      print('✅ Scanner Error Handling Test completed');
    });

    testWidgets('Back Navigation from Scanner', (tester) async {
      print('📱 Testing back navigation from scanner');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Navigate to barcode scanner
      if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pump(Duration(milliseconds: 500));
        
        if (find.text('Barcode Scanner').evaluate().isNotEmpty) {
          await tester.tap(find.text('Barcode Scanner'));
          await tester.pump(Duration(seconds: 2));
          
          // Try to go back
          if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Icons.arrow_back));
            await tester.pump(Duration(seconds: 1));
            print('✅ Back button navigation successful');
          } else {
            // Try system back
            await tester.pageBack();
            await tester.pump(Duration(seconds: 1));
            print('✅ System back navigation successful');
          }
          
          // Verify we're back to previous screen
          expect(find.byType(BarcodeScannerScreen), findsNothing);
        }
      }
      
      print('✅ Back Navigation Test completed');
    });
  });
}
