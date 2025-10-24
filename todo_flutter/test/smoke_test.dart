import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke: renders a simple widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('smoke ok'))),
      ),
    );

    expect(find.text('smoke ok'), findsOneWidget);
  });
}
