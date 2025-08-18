import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miniature_paint_finder/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen displays only icon, title and loader', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.byIcon(Icons.format_paint), findsOneWidget);
    expect(find.text('Miniature Painter'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(Container());

    await tester.pump(const Duration(seconds: 2));
  });
}
