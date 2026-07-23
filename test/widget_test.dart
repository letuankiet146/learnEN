import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LearnEN smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('LearnEN')),
        ),
      ),
    );

    expect(find.text('LearnEN'), findsOneWidget);
  });
}
