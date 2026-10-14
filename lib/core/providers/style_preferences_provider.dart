import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_preferences_provider.dart';

/// Style Preferences data model
class StylePreferences {
  final String occasion;
  final String fabric;
  final String color;
  final double? height;
  final String unit;
  final String gender;
  final double budgetMin;
  final double budgetMax;

  const StylePreferences({
    required this.occasion,
    required this.fabric,
    required this.color,
    this.height,
    required this.unit,
    required this.gender,
    required this.budgetMin,
    required this.budgetMax,
  });

  Map<String, dynamic> toJson() => {
    'occasion': occasion,
    'fabric': fabric,
    'color': color,
    'height': height,
    'unit': unit,
    'gender': gender,
    'budgetMin': budgetMin,
    'budgetMax': budgetMax,
  };

  factory StylePreferences.fromJson(Map<String, dynamic> json) =>
      StylePreferences(
        occasion: (json['occasion'] ?? 'Casual') as String,
        fabric: (json['fabric'] ?? 'Cotton') as String,
        color: (json['color'] ?? '#000000') as String,
        height: (json['height'] as num?)?.toDouble(),
        unit: (json['unit'] ?? 'Inches') as String,
        gender: (json['gender'] ?? 'MALE') as String,
        budgetMin: (json['budgetMin'] as num?)?.toDouble() ?? 50000,
        budgetMax: (json['budgetMax'] as num?)?.toDouble() ?? 150000,
      );
}

/// In-memory provider for quick access during order flow
final stylePreferencesProvider = StateProvider<StylePreferences?>(
  (ref) => null,
);

/// Provider to load style preferences from Supabase on init
final savedStylePreferencesProvider = FutureProvider<StylePreferences?>((
  ref,
) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await Supabase.instance.client
        .from('users')
        .select('preferences')
        .eq('id', userId)
        .maybeSingle();

    final prefs = response?['preferences'];
    if (prefs is Map<String, dynamic> &&
        prefs.containsKey('stylePreferences')) {
      return StylePreferences.fromJson(
        prefs['stylePreferences'] as Map<String, dynamic>,
      );
    }
    return null;
  } catch (e) {
    debugPrint('[STYLE_PREFERENCES] failed to load from Supabase: $e');
    return null;
  }
});

/// Save style preferences to Supabase users.preferences JSONB.
///
/// Merges into the existing JSONB value so theme mode and other preference
/// keys are never wiped by a style-prefs save.
Future<void> saveStylePreferencesToSupabase(StylePreferences prefs) async {
  await updateUserPreferences({'stylePreferences': prefs.toJson()});
}
