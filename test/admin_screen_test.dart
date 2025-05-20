import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:news_app/screens/admin_screen.dart';

void main() {
  testWidgets('AdminScreen has post news button and category dropdown', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));

    expect(find.text('Post News'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
  });
}
