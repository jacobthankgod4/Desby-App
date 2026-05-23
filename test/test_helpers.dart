import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test Helper Utilities
class TestHelpers {
  TestHelpers._();

  static ProviderContainer createTestContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(overrides: overrides);
  }
}

/// Test Extension for WidgetTester
extension WidgetTesterExtension on WidgetTester {
  Future<void> tapText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  Future<void> enterTextIntoKey(String key, String text) async {
    final finder = find.byKey(Key(key));
    await tap(finder);
    await pumpAndSettle();
    await enterText(finder, text);
    await pumpAndSettle();
  }
}

/// Test Data Generator
class TestDataGenerator {
  TestDataGenerator._();

  static String randomString({int length = 10}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[index % chars.length]).join();
  }

  static String randomEmail() => '${randomString()}@test.com';
}
