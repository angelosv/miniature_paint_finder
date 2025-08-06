import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_paint_finder/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen initial UI shows title, fields and buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Miniature Paint Finder'), findsOneWidget);

    expect(find.byType(TextFormField), findsNWidgets(2));

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    expect(
      find.widgetWithText(TextButton, "Don't have an account? Sign up"),
      findsOneWidget,
    );
  });
}
