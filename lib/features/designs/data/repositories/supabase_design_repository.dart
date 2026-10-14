import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/design.dart';
import '../../domain/repositories/design_repository.dart';
import '../models/design_model.dart';

class SupabaseDesignRepository implements DesignRepository {
  final SupabaseClient _supabase = Supabase.instance.client;


  @override
  Future<Result<void>> uploadDesign(Design design) async {
    try {
      final model = DesignModel.fromEntity(design);
      await _supabase.from('designs').upsert(model.toJson(), onConflict: 'id');
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateDesign(Design design) async {
    try {
      final model = DesignModel.fromEntity(design);
      await _supabase.from('designs').upsert(model.toJson(), onConflict: 'id');
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteDesign(String id) async {
    try {
      await _supabase.from('designs').delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Design>> getDesignById(String id) async {
    try {
      final response = await _supabase
          .from('designs')
          .select()
          .eq('id', id)
          .eq('is_visible', true)
          .single();
      return Success(DesignModel.fromJson(response).toEntity());
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Design>> streamDesigns({
    String? category,
    String? tailorId,
    String? gender,
  }) {
    var query = _supabase
        .from('designs')
        .stream(primaryKey: ['id'])
        .eq('is_visible', true)
        .order('created_at', ascending: false);

    if (category != null && category.isNotEmpty && category != 'ALL') {
      query = _supabase
          .from('designs')
          .stream(primaryKey: ['id'])
          .eq('is_visible', true)
          .eq('category', category)
          .order('created_at', ascending: false);
    }

    return query.map(parseDesignRows);
  }

  @override
  Future<Result<List<Design>>> getDesigns({String? category}) async {
    try {
      var query = _supabase.from('designs').select().eq('is_visible', true);

      if (category != null && category.isNotEmpty && category != 'ALL') {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);

      final designs = parseDesignRows(response as List);

      return Success(designs);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Design>>> getFeaturedDesigns() async {
    try {
      final response = await _supabase
          .from('designs')
          .select()
          .eq('is_featured', true)
          .eq('is_visible', true)
          .order('created_at', ascending: false)
          .limit(20);

      final designs = parseDesignRows(response as List);

      return Success(designs);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleLike(String designId, String userId) async {
    try {
      final existing = await _supabase
          .from('design_likes')
          .select()
          .eq('design_id', designId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('design_likes')
            .delete()
            .eq('design_id', designId)
            .eq('user_id', userId);

        await _supabase.rpc('decrement_likes', params: {'design_id': designId});
      } else {
        await _supabase.from('design_likes').insert({
          'design_id': designId,
          'user_id': userId,
        });

        await _supabase.rpc('increment_likes', params: {'design_id': designId});
      }

      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getLikeCount(String designId) async {
    try {
      final response = await _supabase
          .from('designs')
          .select('likes_count')
          .eq('id', designId)
          .single();
      return Success(response['likes_count'] as int? ?? 0);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getLikedDesignIds(String userId) async {
    try {
      final response = await _supabase
          .from('design_likes')
          .select('design_id')
          .eq('user_id', userId);
      return Success(
        (response as List).map((row) => row['design_id'] as String).toList(),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}
