import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:news_app/screens/user_screen.dart';

void main() {
  testWidgets('UserScreen shows categories and news feed', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: UserScreen()));

    expect(find.text('Subscribe to Categories:'), findsOneWidget);
    expect(find.text('Your News Feed:'), findsOneWidget);
  });
}
