import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/certificate.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final certificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('certificates')
        .select()
        .eq('apprentice_id', user.id)
        .order('completed_at', ascending: false);

    return (response as List).map((data) => Certificate.fromMap(data)).toList();
  } catch (e) {
    return [];
  }
});

/// Award certificate when apprentice completes a level
Future<void> awardCertificateIfNeeded(String apprenticeId, String level) async {
  try {
    final supabase = Supabase.instance.client;

    // Check if certificate already exists for this level
    final existing = await supabase
        .from('certificates')
        .select()
        .eq('apprentice_id', apprenticeId)
        .eq('level', level)
        .maybeSingle();

    if (existing != null) return;

    // Get apprentice and tailor names
    final apprenticeProfile = await supabase
        .from('users')
        .select('name')
        .eq('id', apprenticeId)
        .maybeSingle();

    final apprenticeship = await supabase
        .from('apprenticeships')
        .select('tailor_id')
        .eq('apprentice_id', apprenticeId)
        .maybeSingle();

    if (apprenticeship == null) return;

    final tailorProfile = await supabase
        .from('users')
        .select('name')
        .eq('id', apprenticeship['tailor_id'])
        .maybeSingle();

    final certNumber =
        'CERT-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    await supabase.from('certificates').insert({
      'id': '${apprenticeId}_${level}_${DateTime.now().millisecondsSinceEpoch}',
      'apprentice_id': apprenticeId,
      'level': level,
      'tailor_name': tailorProfile?['name'] ?? 'Master Tailor',
      'apprentice_name': apprenticeProfile?['name'] ?? 'Apprentice',
      'completed_at': DateTime.now().toIso8601String(),
      'certificate_number': certNumber,
    });
  } catch (e) {
    // Silent fail — not critical
  }
}
