import 'package:flutter_riverpod/flutter_riverpod.dart';

/// activeTailorProvider - State provider to persist the currently selected tailor
/// Ensures tailor context is preserved during navigation and browser refreshes on Web.
final activeTailorProvider = StateProvider<Map<String, dynamic>>((ref) => {});
