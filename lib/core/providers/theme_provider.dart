import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/local_storage.dart';
import '../storage/storage_keys.dart';
import 'user_preferences_provider.dart';

/// Theme Provider - Manages app-wide theme mode (Light/Dark)
/// Persists to both local storage and Supabase user profiles.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      final String? theme = localStorage.get(StorageKeys.themeMode);
      if (theme == 'light') {
        state = ThemeMode.light;
      } else {
        state = ThemeMode.dark;
      }
    } catch (_) {
      state = ThemeMode.dark;
    }

    // Also try loading from Supabase (overrides local if available)
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('preferences')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final prefs = response['preferences'] as Map<String, dynamic>?;
        final theme = prefs?['theme_mode'] as String?;
        if (theme == 'light' || theme == 'dark') {
          final newMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
          if (state != newMode) {
            state = newMode;
            localStorage.save(StorageKeys.themeMode, theme);
          }
        }
      }
    } catch (_) {
      // Supabase load failed — local storage value is already applied
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      _persist('dark');
    } else {
      state = ThemeMode.light;
      _persist('light');
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _persist(mode == ThemeMode.dark ? 'dark' : 'light');
  }

  void _persist(String value) {
    localStorage.save(StorageKeys.themeMode, value);
    _saveToSupabase(value);
  }

  Future<void> _saveToSupabase(String themeMode) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Read-modify-write so other preference keys (style prefs, ...) survive.
      await updateUserPreferences({'theme_mode': themeMode});
    } catch (_) {
      // Supabase save failed silently — local storage is already updated
    }
  }
}
