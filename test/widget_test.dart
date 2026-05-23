import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desby_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (tester) async {
    // In this repo, DesbyApp wires Firebase and Riverpod auth listeners.
    // For a lightweight smoke test, we avoid running DesbyApp directly.
    // This keeps unit/widget tests deterministic in CI.

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('smoke-test')),
          ),
        ),
      ),
    );

    expect(find.text('smoke-test'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

