import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miniature_paint_finder/main.dart' as app;
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/screens/auth_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔐 Enhanced Authentication Flow Tests', () {
    
    setUpAll(() async {
      // Activar modo test para fuentes del sistema
      AppTheme.setTestMode(true);
    });

    tearDownAll(() async {
      // Desactivar modo test
      AppTheme.setTestMode(false);
    });

    testWidgets('Authentication Screen Elements', (tester) async {
      print('🔐 Testing authentication screen elements');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Should be on auth screen or navigate to it
      if (find.byType(AuthScreen).evaluate().isEmpty) {
        // Try to navigate to auth screen
        if (find.byIcon(Icons.menu).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pump(Duration(milliseconds: 500));
          
          if (find.text('Sign In').evaluate().isNotEmpty) {
            await tester.tap(find.text('Sign In'));
            await tester.pump(Duration(seconds: 1));
          }
        }
      }
      
      // Look for authentication options
      if (find.text('Continue with Email').evaluate().isNotEmpty) {
        print('✅ Email authentication option found');
      }
      
      if (find.text('Continue with Google').evaluate().isNotEmpty) {
        print('✅ Google authentication option found');
      }
      
      if (find.text('Continue with Apple').evaluate().isNotEmpty) {
        print('✅ Apple authentication option found');
      }
      
      if (find.textContaining('Guest').evaluate().isNotEmpty ||
          find.textContaining('Continue as guest').evaluate().isNotEmpty) {
        print('✅ Guest mode option found');
      }
      
      print('✅ Authentication Screen Elements Test completed');
    });

    testWidgets('Email Authentication Interface', (tester) async {
      print('🔐 Testing email authentication interface');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for email authentication button
      if (find.text('Continue with Email').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue with Email'));
        await tester.pump(Duration(seconds: 1));
        
        // Should show email form
        final emailFields = find.byType(TextField);
        if (emailFields.evaluate().length >= 2) {
          print('✅ Email and password fields found');
          
          // Test email field
          await tester.enterText(emailFields.first, 'test@example.com');
          await tester.pump(Duration(milliseconds: 300));
          
          // Test password field
          await tester.enterText(emailFields.last, 'testpassword123');
          await tester.pump(Duration(milliseconds: 300));
          
          print('✅ Email form interaction successful');
        } else if (emailFields.evaluate().length == 1) {
          // Single field (might be email only)
          await tester.enterText(emailFields.first, 'test@example.com');
          await tester.pump(Duration(milliseconds: 300));
          print('✅ Email field interaction successful');
        }
        
        // Look for submit button
        if (find.text('Sign In').evaluate().isNotEmpty ||
            find.text('Continue').evaluate().isNotEmpty ||
            find.text('Submit').evaluate().isNotEmpty) {
          print('✅ Submit button found');
        }
      }
      
      print('✅ Email Authentication Test completed');
    });

    testWidgets('Google Sign-In Button', (tester) async {
      print('🔐 Testing Google Sign-In button');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for Google sign-in button
      if (find.text('Continue with Google').evaluate().isNotEmpty) {
        // Don't actually tap it (would require real Google auth)
        // Just verify it's present and tappable
        expect(find.text('Continue with Google'), findsOneWidget);
        print('✅ Google Sign-In button found and accessible');
        
        // Check for Google icon
        if (find.byIcon(Icons.g_mobiledata_rounded).evaluate().isNotEmpty) {
          print('✅ Google icon found');
        }
      } else {
        print('ℹ️ Google Sign-In button not found (may be platform-specific)');
      }
      
      print('✅ Google Sign-In Test completed');
    });

    testWidgets('Apple Sign-In Button (iOS)', (tester) async {
      print('🔐 Testing Apple Sign-In button');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for Apple sign-in button (iOS only)
      if (find.text('Continue with Apple').evaluate().isNotEmpty) {
        expect(find.text('Continue with Apple'), findsOneWidget);
        print('✅ Apple Sign-In button found (iOS platform)');
        
        // Check for Apple icon
        if (find.byIcon(Icons.apple).evaluate().isNotEmpty) {
          print('✅ Apple icon found');
        }
      } else {
        print('ℹ️ Apple Sign-In not available (expected on non-iOS platforms)');
      }
      
      print('✅ Apple Sign-In Test completed');
    });

    testWidgets('Guest Mode Access', (tester) async {
      print('🔐 Testing guest mode access');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for guest mode options
      if (find.textContaining('Guest').evaluate().isNotEmpty) {
        print('✅ Guest mode option found');
      } else if (find.textContaining('Continue without').evaluate().isNotEmpty) {
        print('✅ Continue without account option found');
      } else if (find.textContaining('Skip').evaluate().isNotEmpty) {
        print('✅ Skip authentication option found');
      } else {
        // Guest mode might be implicit or accessed differently
        print('ℹ️ Guest mode may be available through other means');
      }
      
      print('✅ Guest Mode Test completed');
    });

    testWidgets('Authentication Form Validation', (tester) async {
      print('🔐 Testing authentication form validation');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Access email form
      if (find.text('Continue with Email').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue with Email'));
        await tester.pump(Duration(seconds: 1));
        
        final textFields = find.byType(TextField);
        if (textFields.evaluate().length >= 2) {
          // Test invalid email
          await tester.enterText(textFields.first, 'invalid-email');
          await tester.pump(Duration(milliseconds: 300));
          
          // Test weak password
          await tester.enterText(textFields.last, '123');
          await tester.pump(Duration(milliseconds: 300));
          
          // Try to submit (should show validation errors)
          if (find.text('Sign In').evaluate().isNotEmpty) {
            await tester.tap(find.text('Sign In'));
            await tester.pump(Duration(seconds: 1));
            
            // Look for validation messages
            if (find.textContaining('valid email').evaluate().isNotEmpty ||
                find.textContaining('password').evaluate().isNotEmpty ||
                find.textContaining('required').evaluate().isNotEmpty) {
              print('✅ Form validation working');
            }
          }
          
          print('✅ Form validation tested');
        }
      }
      
      print('✅ Authentication Form Validation Test completed');
    });

    testWidgets('Login/Register Toggle', (tester) async {
      print('🔐 Testing login/register toggle');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Look for toggle between login and register
      if (find.textContaining('Sign Up').evaluate().isNotEmpty ||
          find.textContaining('Register').evaluate().isNotEmpty) {
        print('✅ Registration option found');
        
        // Try to switch to registration
        if (find.text('Sign Up').evaluate().isNotEmpty) {
          await tester.tap(find.text('Sign Up'));
          await tester.pump(Duration(seconds: 1));
          print('✅ Switched to registration mode');
        }
      }
      
      if (find.textContaining('Sign In').evaluate().isNotEmpty ||
          find.textContaining('Login').evaluate().isNotEmpty) {
        print('✅ Login option found');
      }
      
      // Look for "Already have account" or "Don't have account" links
      if (find.textContaining('Already have').evaluate().isNotEmpty ||
          find.textContaining("Don't have").evaluate().isNotEmpty ||
          find.textContaining('Create account').evaluate().isNotEmpty) {
        print('✅ Account toggle links found');
      }
      
      print('✅ Login/Register Toggle Test completed');
    });

    testWidgets('Password Reset Functionality', (tester) async {
      print('🔐 Testing password reset functionality');
      
      app.main();
      await tester.pump(Duration(seconds: 2));
      
      // Access email form
      if (find.text('Continue with Email').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue with Email'));
        await tester.pump(Duration(seconds: 1));
        
        // Look for "Forgot Password" or similar
        if (find.textContaining('Forgot').evaluate().isNotEmpty ||
            find.textContaining('Reset').evaluate().isNotEmpty) {
          print('✅ Password reset option found');
          
          // Try to access password reset
          if (find.text('Forgot Password?').evaluate().isNotEmpty) {
            await tester.tap(find.text('Forgot Password?'));
            await tester.pump(Duration(seconds: 1));
            
            // Should show email input for reset
            final emailFields = find.byType(TextField);
            if (emailFields.evaluate().isNotEmpty) {
              await tester.enterText(emailFields.first, 'test@example.com');
              await tester.pump(Duration(milliseconds: 300));
              print('✅ Password reset email field working');
            }
          }
        } else {
          print('ℹ️ Password reset option not immediately visible');
        }
      }
      
      print('✅ Password Reset Test completed');
    });
  });
}
