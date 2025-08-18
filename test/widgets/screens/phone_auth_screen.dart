import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_paint_finder/screens/phone_auth_screen.dart';

void main() {
  testWidgets(
    'PhoneAuthScreen initial view shows phone field and send button',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PhoneAuthScreen()));

      expect(
        find.widgetWithText(TextFormField, 'Phone Number'),
        findsOneWidget,
      );

      expect(
        find.widgetWithText(ElevatedButton, 'Send Verification Code'),
        findsOneWidget,
      );

      expect(
        find.widgetWithText(TextFormField, 'Verification Code'),
        findsNothing,
      );
    },
  );
}
