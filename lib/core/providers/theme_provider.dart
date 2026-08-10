import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage.dart';
import '../storage/storage_keys.dart';

/// Theme Provider - Manages app-wide theme mode (Light/Dark)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() {
    final String? theme = localStorage.get(StorageKeys.themeMode);
    if (theme == 'dark') {
      state = ThemeMode.dark;
    } else if (theme == 'light') {
      state = ThemeMode.light;
    } else {
      // Default to light for new users
      state = ThemeMode.light;
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      localStorage.save(StorageKeys.themeMode, 'dark');
    } else {
      state = ThemeMode.light;
      localStorage.save(StorageKeys.themeMode, 'light');
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    localStorage.save(StorageKeys.themeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
