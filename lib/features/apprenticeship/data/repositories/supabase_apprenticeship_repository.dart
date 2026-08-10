import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/apprenticeship.dart';
import '../../domain/entities/apprentice_task.dart';
import '../../domain/entities/apprentice_module.dart';
import '../../domain/repositories/apprenticeship_repository.dart';
import '../models/apprentice_task_model.dart';

class SupabaseApprenticeshipRepository implements ApprenticeshipRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Result<List<ApprenticeModule>>> getCurriculum() async {
    try {
      final response = await _supabase
          .from('curriculum_modules')
          .select()
          .order('order_index');
      
      final List<dynamic> data = response;
      return Success(data.map((d) => ApprenticeModule(
        id: d['id'] as String,
        title: d['title'] as String,
        description: d['description'] as String? ?? '',
        orderIndex: d['order_index'] as int,
        masterclassThumbnail: d['masterclass_thumbnail'] as String?,
        lessonIds: [], // Will be populated if needed, or handled via modules query
      )).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ApprenticeLesson>>> getLessons(String moduleId) async {
    try {
      final response = await _supabase
          .from('curriculum_lessons')
          .select()
          .eq('module_id', moduleId)
          .order('order_index');
      
      final List<dynamic> data = response;
      return Success(data.map((d) => ApprenticeLesson(
        id: d['id'] as String,
        moduleId: d['module_id'] as String,
        title: d['title'] as String,
        content: d['content'] as String? ?? '',
        videoUrl: d['video_url'] as String?,
        orderIndex: d['order_index'] as int,
      )).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ApprenticeLesson>> getLessonById(String lessonId) async {
    try {
      final response = await _supabase
          .from('curriculum_lessons')
          .select()
          .eq('id', lessonId)
          .single();
      
      return Success(ApprenticeLesson(
        id: response['id'] as String,
        moduleId: response['module_id'] as String,
        title: response['title'] as String,
        content: response['content'] as String? ?? '',
        videoUrl: response['video_url'] as String?,
        orderIndex: response['order_index'] as int,
      ));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ApprenticeTask>>> getApprenticeTasks(String apprenticeshipId) async {
    try {
      final response = await _supabase.from('apprentice_tasks').select().eq('apprenticeship_id', apprenticeshipId);
      final List<dynamic> data = response;
      return Success(data.map((d) => ApprenticeTaskModel.fromJson(d).toEntity()).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Apprenticeship>>> getApprenticeships(String tailorId) async {
    try {
      // Fetch with profile join
      final response = await _supabase
          .from('apprenticeships')
          .select('*, apprenticeProfile:apprentice_id(*)')
          .eq('tailor_id', tailorId);
      
      return Success((response as List).map((data) {
        final apprentice = data['apprenticeProfile'] != null 
            ? UserModel.fromJson(data['apprenticeProfile'] as Map<String, dynamic>).toEntity()
            : null;
        return _mapToApprenticeship(data['id'], data).copyWith(apprenticeProfile: apprentice);
      }).toList());
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Apprenticeship?>> getApprenticeship(String apprenticeId) async {
    try {
      final response = await _supabase
          .from('apprenticeships')
          .select('*, tailorProfile:tailor_id(*)')
          .eq('apprentice_id', apprenticeId)
          .maybeSingle();
      
      if (response == null) return const Success(null);
      
      final tailor = response['tailorProfile'] != null 
          ? UserModel.fromJson(response['tailorProfile'] as Map<String, dynamic>).toEntity()
          : null;
          
      return Success(_mapToApprenticeship(response['id'], response).copyWith(tailorProfile: tailor));
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Apprenticeship>> createApprenticeship(Apprenticeship apprenticeship) async {
    try {
      await _supabase.from('apprenticeships').upsert(_mapFromApprenticeship(apprenticeship), onConflict: 'id');
      return Success(apprenticeship);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Apprenticeship>> updateApprenticeship(Apprenticeship apprenticeship) async {
    try {
      await _supabase.from('apprenticeships').upsert(_mapFromApprenticeship(apprenticeship), onConflict: 'id');
      return Success(apprenticeship);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ApprenticeTask>> createTask(ApprenticeTask task) async {
    try {
      final model = ApprenticeTaskModel.fromEntity(task);
      await _supabase.from('apprentice_tasks').upsert(model.toJson(), onConflict: 'id');
      return Success(task);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ApprenticeTask>> updateTask(ApprenticeTask task) async {
    try {
      final model = ApprenticeTaskModel.fromEntity(task);
      await _supabase.from('apprentice_tasks').upsert(model.toJson(), onConflict: 'id');
      return Success(task);
    } catch (e) {
      return Failure(AuthFailure(message: e.toString()));
    }
  }

  Apprenticeship _mapToApprenticeship(String id, Map<String, dynamic> data) {
    return Apprenticeship(
      id: id,
      tailorId: (data['tailor_id'] ?? data['tailorId']) as String,
      apprenticeId: (data['apprentice_id'] ?? data['apprenticeId']) as String,
      status: _parseApprenticeshipStatus(data['status'] as String),
      progress: (data['progress'] as num).toDouble(),
      startDate: DateTime.parse((data['start_date'] ?? data['startDate']) as String),
      skillIds: List<String>.from((data['skill_ids'] ?? data['skillIds']) as List),
    );
  }

  Map<String, dynamic> _mapFromApprenticeship(Apprenticeship app) {
    return {
      'id': app.id,
      'tailor_id': app.tailorId,
      'apprentice_id': app.apprenticeId,
      'status': app.status.name,
      'progress': app.progress,
      'start_date': app.startDate.toIso8601String(),
      'skill_ids': app.skillIds,
    };
  }

  ApprenticeshipStatus _parseApprenticeshipStatus(String status) {
    return ApprenticeshipStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ApprenticeshipStatus.awaitingMasterApproval,
    );
  }
}
