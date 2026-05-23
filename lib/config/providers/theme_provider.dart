import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme Mode Provider - FORCED TO DARK for Desby OS Branding
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;

  ThemeModeNotifier(this.ref) : super(ThemeMode.dark);

  // Ignore requests to change theme - Lock to Dark Navy/Amber
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    state = ThemeMode.dark;
  }
}

final isDarkModeProvider = Provider<bool>((ref) => true);
