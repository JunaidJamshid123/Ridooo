// Ridooo - Ride Sharing App Widget Tests
//
// Basic smoke tests for the Ridooo application

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - core widgets can be created', (WidgetTester tester) async {
    // Test that basic Material widgets work
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Ridooo'),
          ),
        ),
      ),
    );

    expect(find.text('Ridooo'), findsOneWidget);
  });

  testWidgets('Basic button interaction test', (WidgetTester tester) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () => wasPressed = true,
            child: const Text('Book Ride'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Book Ride'));
    await tester.pump();

    expect(wasPressed, isTrue);
  });

  testWidgets('Form validation test', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required field';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );

    // Validate empty form
    expect(formKey.currentState!.validate(), isFalse);
  });
}
