import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_design_repository.dart';
import '../../domain/entities/design.dart';
import '../../domain/repositories/design_repository.dart';

final designRepositoryProvider = Provider<DesignRepository>((ref) {
  return SupabaseDesignRepository();
});

final designListProvider = FutureProvider.autoDispose
    .family<List<Design>, String?>((ref, category) async {
      final repo = ref.watch(designRepositoryProvider);
      final result = await repo.getDesigns(category: category);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (designs) => designs,
      );
    });

final featuredDesignsProvider = FutureProvider<List<Design>>((ref) async {
  final repo = ref.watch(designRepositoryProvider);
  final result = await repo.getFeaturedDesigns();
  return result.fold(
    (failure) => throw Exception('Unable to load featured designs.'),
    (designs) => designs,
  );
});

final designByIdProvider = FutureProvider.family<Design, String>((
  ref,
  designId,
) async {
  final repo = ref.watch(designRepositoryProvider);
  final result = await repo.getDesignById(designId);
  return result.fold(
    (failure) => throw Exception('Design not found.'),
    (design) => design,
  );
});

/// IDs of designs the current user has liked/saved
final likedDesignIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <String>{};
  final repo = ref.watch(designRepositoryProvider);
  final result = await repo.getLikedDesignIds(user.id);
  return result.fold((failure) => <String>{}, (ids) => ids.toSet());
});

/// Full Design objects for all liked designs
final savedDesignsProvider = FutureProvider.autoDispose<List<Design>>((
  ref,
) async {
  final ids = await ref.watch(likedDesignIdsProvider.future);
  if (ids.isEmpty) return [];
  final repo = ref.watch(designRepositoryProvider);
  final designs = <Design>[];
  for (final id in ids) {
    final result = await repo.getDesignById(id);
    result.fold(
      (failure) => debugPrint(
        '[DESIGN_PROVIDER] Failed to load saved design $id: ${failure.message}',
      ),
      designs.add,
    );
  }
  return designs;
});

/// All VISIBLE designs published by a specific tailor (for public profile page)
final tailorDesignsProvider = FutureProvider.autoDispose
    .family<List<Design>, String>((ref, tailorId) async {
      try {
        final response = await Supabase.instance.client
            .from('designs')
            .select()
            .eq('tailor_id', tailorId)
            .eq('is_visible', true)
            .order('created_at', ascending: false);
        return (response as List).map((data) {
          return Design(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            category: data['category'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            tailorId: data['tailor_id'] ?? '',
            tailorName: data['tailor_name'] ?? '',
            tailorAvatarUrl: data['tailor_avatar_url'],
            imageUrls: List<String>.from(data['image_urls'] ?? []),
            description: data['description'],
            gender: data['gender'] ?? 'unisex',
            likesCount: data['likes_count'] ?? 0,
            isFeatured: data['is_featured'] ?? false,
            isVisible: data['is_visible'] ?? true,
            createdAt: data['created_at'] != null
                ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
                : DateTime.now(),
            updatedAt: data['updated_at'] != null
                ? DateTime.tryParse(data['updated_at']) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
      } catch (e) {
        debugPrint('[DESIGN_PROVIDER] Failed to load tailor designs: $e');
        return [];
      }
    });

/// ALL designs (including hidden) for a tailor — for the tailor's own management page
final tailorAllDesignsProvider = FutureProvider.autoDispose
    .family<List<Design>, String>((ref, tailorId) async {
      try {
        final response = await Supabase.instance.client
            .from('designs')
            .select()
            .eq('tailor_id', tailorId)
            .order('created_at', ascending: false);
        return (response as List).map((data) {
          return Design(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            category: data['category'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            tailorId: data['tailor_id'] ?? '',
            tailorName: data['tailor_name'] ?? '',
            tailorAvatarUrl: data['tailor_avatar_url'],
            imageUrls: List<String>.from(data['image_urls'] ?? []),
            description: data['description'],
            gender: data['gender'] ?? 'unisex',
            likesCount: data['likes_count'] ?? 0,
            isFeatured: data['is_featured'] ?? false,
            isVisible: data['is_visible'] ?? true,
            createdAt: data['created_at'] != null
                ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
                : DateTime.now(),
            updatedAt: data['updated_at'] != null
                ? DateTime.tryParse(data['updated_at']) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
      } catch (e) {
        debugPrint('[DESIGN_PROVIDER] Failed to load tailor designs: $e');
        return [];
      }
    });
