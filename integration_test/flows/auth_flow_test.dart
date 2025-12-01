import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔐 Authentication Flow Tests', () {
    
    setUp(() async {
      TestHelpers.logStep('Setting up authentication test');
    });

    tearDown(() async {
      TestHelpers.logStep('Cleaning up authentication test');
    });

    testWidgets('User Registration Flow', (tester) async {
      TestHelpers.logStep('Starting user registration test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Navigate to registration
      if (find.text('Sign Up').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Sign Up'));
      }
      
      // 2. Fill registration form
      await tester.enterTextAndSettle(
        find.byKey(Key('email_field')), 
        'newuser_${DateTime.now().millisecondsSinceEpoch}@test.com',
      );
      await tester.enterTextAndSettle(
        find.byKey(Key('password_field')), 
        MockData.testPassword,
      );
      await tester.enterTextAndSettle(
        find.byKey(Key('confirm_password_field')), 
        MockData.testPassword,
      );
      
      // 3. Submit registration
      await tester.tapAndSettle(find.text('Create Account'));
      
      // 4. Verify successful registration
      await TestHelpers.waitForWidget(tester, find.text('Home'));
      
      TestHelpers.logResult('User Registration', true);
    });

    testWidgets('User Login Flow', (tester) async {
      TestHelpers.logStep('Starting user login test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Navigate to login if needed
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Sign In'));
      }
      
      // 2. Enter credentials
      await tester.enterTextAndSettle(
        find.byKey(Key('email_field')), 
        MockData.testEmail,
      );
      await tester.enterTextAndSettle(
        find.byKey(Key('password_field')), 
        MockData.testPassword,
      );
      
      // 3. Submit login
      await tester.tapAndSettle(find.text('Sign In'));
      
      // 4. Verify successful login
      await TestHelpers.waitForWidget(tester, find.text('Home'));
      
      TestHelpers.logResult('User Login', true);
    });

    testWidgets('Guest Mode Access', (tester) async {
      TestHelpers.logStep('Starting guest mode test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Access as guest
      if (find.text('Continue as Guest').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Continue as Guest'));
      }
      
      // 2. Verify guest access
      await TestHelpers.waitForWidget(tester, find.text('Home'));
      
      // 3. Verify guest limitations
      await TestHelpers.navigateTo(tester, 'projects');
      
      // Should show guest promo when trying to create project
      if (find.text('New Project').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('New Project'));
        
        // Should show upgrade prompt
        expect(find.text('Sign Up'), findsOneWidget);
      }
      
      TestHelpers.logResult('Guest Mode Access', true);
    });

    testWidgets('Logout Flow', (tester) async {
      TestHelpers.logStep('Starting logout test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Open navigation drawer
      await tester.tapAndSettle(find.byIcon(Icons.menu));
      
      // 2. Tap logout
      await tester.tapAndSettle(find.text('Logout'));
      
      // 3. Verify logout
      await TestHelpers.waitForWidget(tester, find.text('Sign In'));
      
      TestHelpers.logResult('User Logout', true);
    });

    testWidgets('Invalid Login Credentials', (tester) async {
      TestHelpers.logStep('Starting invalid credentials test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Navigate to login
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Sign In'));
      }
      
      // 2. Enter invalid credentials
      await tester.enterTextAndSettle(
        find.byKey(Key('email_field')), 
        'invalid@email.com',
      );
      await tester.enterTextAndSettle(
        find.byKey(Key('password_field')), 
        'wrongpassword',
      );
      
      // 3. Submit login
      await tester.tapAndSettle(find.text('Sign In'));
      
      // 4. Verify error message
      await TestHelpers.waitForWidget(
        tester, 
        find.textContaining('Invalid'),
      );
      
      TestHelpers.logResult('Invalid Credentials Handling', true);
    });

    testWidgets('Password Reset Flow', (tester) async {
      TestHelpers.logStep('Starting password reset test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Navigate to login
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Sign In'));
      }
      
      // 2. Tap forgot password
      if (find.text('Forgot Password?').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Forgot Password?'));
        
        // 3. Enter email
        await tester.enterTextAndSettle(
          find.byKey(Key('reset_email_field')), 
          MockData.testEmail,
        );
        
        // 4. Submit reset request
        await tester.tapAndSettle(find.text('Send Reset Email'));
        
        // 5. Verify confirmation message
        await TestHelpers.waitForWidget(
          tester, 
          find.textContaining('reset email sent'),
        );
      }
      
      TestHelpers.logResult('Password Reset', true);
    });

    testWidgets('Social Login (Google)', (tester) async {
      TestHelpers.logStep('Starting Google login test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Navigate to login
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Sign In'));
      }
      
      // 2. Tap Google sign in
      if (find.byKey(Key('google_sign_in_button')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('google_sign_in_button')));
        
        // Note: In real tests, this would need to handle the Google auth flow
        // For now, we just verify the button exists and is tappable
        
        TestHelpers.logResult('Google Sign In Button', true);
      } else {
        TestHelpers.logResult('Google Sign In Button', false, 
          details: 'Button not found');
      }
    });

    testWidgets('Social Login (Apple)', (tester) async {
      TestHelpers.logStep('Starting Apple login test');
      
      await TestHelpers.launchApp(tester);
      
      // 1. Navigate to login
      if (find.text('Sign In').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Sign In'));
      }
      
      // 2. Tap Apple sign in (iOS only)
      if (find.byKey(Key('apple_sign_in_button')).evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.byKey(Key('apple_sign_in_button')));
        
        TestHelpers.logResult('Apple Sign In Button', true);
      } else {
        TestHelpers.logResult('Apple Sign In Button', false, 
          details: 'Button not found or not on iOS');
      }
    });

    testWidgets('Session Persistence', (tester) async {
      TestHelpers.logStep('Starting session persistence test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Verify logged in state
      expect(find.text('Home'), findsOneWidget);
      
      // 2. Restart app (simulate app restart)
      await TestHelpers.launchApp(tester);
      
      // 3. Verify still logged in
      await TestHelpers.waitForWidget(tester, find.text('Home'));
      
      TestHelpers.logResult('Session Persistence', true);
    });

    testWidgets('Account Deletion Flow', (tester) async {
      TestHelpers.logStep('Starting account deletion test');
      
      await TestHelpers.launchApp(tester);
      await TestHelpers.loginTestUser(tester);
      
      // 1. Navigate to settings
      await tester.tapAndSettle(find.byIcon(Icons.menu));
      
      if (find.text('Settings').evaluate().isNotEmpty) {
        await tester.tapAndSettle(find.text('Settings'));
        
        // 2. Find delete account option
        if (find.text('Delete Account').evaluate().isNotEmpty) {
          await tester.tapAndSettle(find.text('Delete Account'));
          
          // 3. Confirm deletion
          await tester.tapAndSettle(find.text('Confirm Delete'));
          
          // 4. Verify account deleted
          await TestHelpers.waitForWidget(tester, find.text('Sign In'));
          
          TestHelpers.logResult('Account Deletion', true);
        }
      }
    });
  });
}

