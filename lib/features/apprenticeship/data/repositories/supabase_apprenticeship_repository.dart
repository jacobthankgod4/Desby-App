import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../clients/domain/entities/client.dart' show InviteStatus;
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

      final lessonsResponse = await _supabase
          .from('curriculum_lessons')
          .select('id, module_id')
          .order('order_index');

      final Map<String, List<String>> lessonsByModule = {};
      for (final lesson in lessonsResponse) {
        final moduleId = lesson['module_id'] as String;
        final lessonId = lesson['id'] as String;
        lessonsByModule.putIfAbsent(moduleId, () => []).add(lessonId);
      }

      final List<dynamic> data = response;
      return Success(
        data.map((d) {
          final moduleId = d['id'] as String;
          return ApprenticeModule(
            id: moduleId,
            title: d['title'] as String,
            description: d['description'] as String? ?? '',
            orderIndex: d['order_index'] as int,
            masterclassThumbnail: d['masterclass_thumbnail'] as String?,
            tailorId: d['tailor_id'] as String?,
            lessonIds: lessonsByModule[moduleId] ?? [],
          );
        }).toList(),
      );
    } catch (e) {
      return Failure(_mapError(e));
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
      return Success(data.map((d) => _mapLesson(d)).toList());
    } catch (e) {
      return Failure(_mapError(e));
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

      return Success(_mapLesson(response));
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  ApprenticeLesson _mapLesson(Map<String, dynamic> d) {
    return ApprenticeLesson(
      id: d['id'] as String,
      moduleId: d['module_id'] as String,
      title: d['title'] as String,
      content: d['content'] as String? ?? '',
      shortDescription: d['short_description'] as String?,
      videoUrl: d['video_url'] as String?,
      thumbnailUrl: d['thumbnail_url'] as String?,
      durationMinutes: d['duration_minutes'] as int?,
      lessonType: d['lesson_type'] as String? ?? 'video',
      isPublished: d['is_published'] as bool? ?? true,
      isFreePreview: d['is_free_preview'] as bool? ?? false,
      attachments: (d['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
      orderIndex: d['order_index'] as int,
    );
  }

  @override
  Future<Result<ApprenticeModule>> createModule(
    String title,
    String description,
    int orderIndex, {
    String? tailorId,
  }) async {
    try {
      const uuid = Uuid();
      final id = 'module_${uuid.v4().substring(0, 8)}';
      final data = <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'order_index': orderIndex,
      };
      if (tailorId != null) data['tailor_id'] = tailorId;
      await _supabase.from('curriculum_modules').insert(data);
      return Success(
        ApprenticeModule(
          id: id,
          title: title,
          description: description,
          orderIndex: orderIndex,
          tailorId: tailorId,
          lessonIds: [],
        ),
      );
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<ApprenticeModule>> updateModule(
    String moduleId, {
    String? title,
    String? description,
    int? orderIndex,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (orderIndex != null) updates['order_index'] = orderIndex;
      if (updates.isEmpty)
        return Failure(ValidationFailure(message: 'No updates provided'));
      await _supabase
          .from('curriculum_modules')
          .update(updates)
          .eq('id', moduleId);
      final row = await _supabase
          .from('curriculum_modules')
          .select()
          .eq('id', moduleId)
          .single();
      final lessons = await _supabase
          .from('curriculum_lessons')
          .select('id')
          .eq('module_id', moduleId)
          .order('order_index');
      return Success(
        ApprenticeModule(
          id: row['id'] as String,
          title: row['title'] as String,
          description: (row['description'] ?? '') as String,
          orderIndex: row['order_index'] as int,
          masterclassThumbnail: row['masterclass_thumbnail'] as String?,
          lessonIds: (lessons as List).map((l) => l['id'] as String).toList(),
        ),
      );
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> deleteModule(String moduleId) async {
    try {
      await _supabase.from('curriculum_modules').delete().eq('id', moduleId);
      return const Success(null);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> reorderModules(List<String> moduleIds) async {
    try {
      for (int i = 0; i < moduleIds.length; i++) {
        await _supabase
            .from('curriculum_modules')
            .update({'order_index': i})
            .eq('id', moduleIds[i]);
      }
      return const Success(null);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<ApprenticeLesson>> createLesson(
    String moduleId,
    String title,
    String content,
    int orderIndex, {
    String? videoUrl,
    String? shortDescription,
    String? thumbnailUrl,
    int? durationMinutes,
    String? lessonType,
    bool? isPublished,
    bool? isFreePreview,
    List<String>? attachments,
  }) async {
    try {
      const uuid = Uuid();
      final id = 'lesson_${uuid.v4().substring(0, 8)}';
      final data = <String, dynamic>{
        'id': id,
        'module_id': moduleId,
        'title': title,
        'content': content,
        'order_index': orderIndex,
        'short_description': shortDescription,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'duration_minutes': durationMinutes,
        'lesson_type': lessonType ?? 'video',
        'is_published': isPublished ?? true,
        'is_free_preview': isFreePreview ?? false,
        'attachments': attachments ?? [],
      };
      await _supabase.from('curriculum_lessons').insert(data);
      return Success(
        ApprenticeLesson(
          id: id,
          moduleId: moduleId,
          title: title,
          content: content,
          shortDescription: shortDescription,
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          durationMinutes: durationMinutes,
          lessonType: lessonType ?? 'video',
          isPublished: isPublished ?? true,
          isFreePreview: isFreePreview ?? false,
          attachments: attachments ?? [],
          orderIndex: orderIndex,
        ),
      );
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<ApprenticeLesson>> updateLesson(
    String lessonId, {
    String? title,
    String? content,
    String? videoUrl,
    int? orderIndex,
    String? shortDescription,
    String? thumbnailUrl,
    int? durationMinutes,
    String? lessonType,
    bool? isPublished,
    bool? isFreePreview,
    List<String>? attachments,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      updates['video_url'] = videoUrl;
      if (orderIndex != null) updates['order_index'] = orderIndex;
      if (shortDescription != null)
        updates['short_description'] = shortDescription;
      if (thumbnailUrl != null) updates['thumbnail_url'] = thumbnailUrl;
      if (durationMinutes != null)
        updates['duration_minutes'] = durationMinutes;
      if (lessonType != null) updates['lesson_type'] = lessonType;
      if (isPublished != null) updates['is_published'] = isPublished;
      if (isFreePreview != null) updates['is_free_preview'] = isFreePreview;
      if (attachments != null) updates['attachments'] = attachments;
      if (updates.isEmpty)
        return Failure(ValidationFailure(message: 'No updates provided'));
      await _supabase
          .from('curriculum_lessons')
          .update(updates)
          .eq('id', lessonId);
      final row = await _supabase
          .from('curriculum_lessons')
          .select()
          .eq('id', lessonId)
          .single();
      return Success(_mapLesson(row));
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> deleteLesson(String lessonId) async {
    try {
      await _supabase.from('curriculum_lessons').delete().eq('id', lessonId);
      return const Success(null);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> reorderLessons(
    String moduleId,
    List<String> lessonIds,
  ) async {
    try {
      for (int i = 0; i < lessonIds.length; i++) {
        await _supabase
            .from('curriculum_lessons')
            .update({'order_index': i})
            .eq('id', lessonIds[i]);
      }
      return const Success(null);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<void>> markLessonComplete(
    String apprenticeshipId,
    String lessonId,
  ) async {
    try {
      final existing = await _supabase
          .from('lesson_progress')
          .select('id')
          .eq('apprenticeship_id', apprenticeshipId)
          .eq('lesson_id', lessonId)
          .maybeSingle();
      if (existing != null) return const Success(null);
      const uuid = Uuid();
      await _supabase.from('lesson_progress').insert({
        'id': uuid.v4(),
        'apprenticeship_id': apprenticeshipId,
        'lesson_id': lessonId,
        'completed_at': DateTime.now().toIso8601String(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<Set<String>>> getCompletedLessons(
    String apprenticeshipId,
  ) async {
    try {
      final response = await _supabase
          .from('lesson_progress')
          .select('lesson_id')
          .eq('apprenticeship_id', apprenticeshipId);
      return Success(
        (response as List).map((r) => r['lesson_id'] as String).toSet(),
      );
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<double>> calculateProgress(String apprenticeshipId) async {
    try {
      final completedResult = await getCompletedLessons(apprenticeshipId);
      return completedResult.fold((f) => Failure(f), (completed) async {
        final lessonsResponse = await _supabase
            .from('curriculum_lessons')
            .select('id');
        final totalLessons = (lessonsResponse as List).length;
        if (totalLessons == 0) return const Success(0.0);
        return Success((completed.length / totalLessons).clamp(0.0, 1.0));
      });
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  FailureType _mapError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('42501') ||
        msg.contains('permission') ||
        msg.contains('RLS')) {
      return AuthorizationFailure(
        message: 'Permission denied. Please check your access.',
      );
    }
    if (msg.contains('23505') ||
        msg.contains('unique') ||
        msg.contains('duplicate')) {
      return ValidationFailure(message: 'This item already exists.');
    }
    if (msg.contains('23503') || msg.contains('foreign key')) {
      return ValidationFailure(message: 'Referenced item not found.');
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return NetworkFailure(message: 'Network error. Check your connection.');
    }
    return ServerFailure(message: msg);
  }

  @override
  Future<Result<List<ApprenticeTask>>> getApprenticeTasks(
    String apprenticeshipId,
  ) async {
    try {
      final response = await _supabase
          .from('apprentice_tasks')
          .select()
          .eq('apprenticeship_id', apprenticeshipId);
      final List<dynamic> data = response;
      return Success(
        data.map((d) => ApprenticeTaskModel.fromJson(d).toEntity()).toList(),
      );
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<List<Apprenticeship>>> getApprenticeships(
    String tailorId,
  ) async {
    try {
      final response = await _supabase
          .from('apprenticeships')
          .select()
          .eq('tailor_id', tailorId);

      final List<Apprenticeship> results = [];
      for (final data in (response as List)) {
        UserModel? apprentice;
        final apprenticeId = data['apprentice_id'] as String?;
        if (apprenticeId != null && apprenticeId.isNotEmpty) {
          try {
            final apprenticeData = await _supabase
                .from('users')
                .select()
                .eq('id', apprenticeId)
                .maybeSingle();
            if (apprenticeData != null) {
              apprentice = UserModel.fromJson(apprenticeData);
            }
          } catch (_) {}
        }
        results.add(
          _mapToApprenticeship(
            data,
          ).copyWith(apprenticeProfile: apprentice?.toEntity()),
        );
      }
      return Success(results);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<Apprenticeship?>> getApprenticeship(String apprenticeId) async {
    try {
      final response = await _supabase
          .from('apprenticeships')
          .select()
          .eq('apprentice_id', apprenticeId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return const Success(null);

      // Fetch tailor profile separately to avoid embed join failures
      UserModel? tailor;
      final tailorId = response['tailor_id'] as String?;
      if (tailorId != null && tailorId.isNotEmpty) {
        try {
          final tailorData = await _supabase
              .from('users')
              .select()
              .eq('id', tailorId)
              .maybeSingle();
          if (tailorData != null) {
            tailor = UserModel.fromJson(tailorData);
          }
        } catch (_) {
          // Tailor profile fetch failed — continue without it
        }
      }

      return Success(
        _mapToApprenticeship(
          response,
        ).copyWith(tailorProfile: tailor?.toEntity()),
      );
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<Apprenticeship>> createApprenticeship(
    Apprenticeship apprenticeship,
  ) async {
    try {
      final data = _mapFromApprenticeship(apprenticeship);
      // Only upsert if the ID already exists, otherwise insert
      final existing = await _supabase
          .from('apprenticeships')
          .select('id')
          .eq('id', apprenticeship.id)
          .maybeSingle();
      if (existing != null) {
        await _supabase.from('apprenticeships').upsert(data, onConflict: 'id');
      } else {
        await _supabase.from('apprenticeships').insert(data);
      }
      return Success(apprenticeship);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<Apprenticeship>> updateApprenticeship(
    Apprenticeship apprenticeship,
  ) async {
    try {
      await _supabase
          .from('apprenticeships')
          .upsert(_mapFromApprenticeship(apprenticeship), onConflict: 'id');
      return Success(apprenticeship);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<Apprenticeship?>> getApprenticeshipByInviteToken(
    String token,
  ) async {
    try {
      final response = await _supabase
          .from('apprenticeships')
          .select()
          .eq('invite_token', token)
          .maybeSingle();

      if (response == null) return const Success(null);
      return Success(_mapToApprenticeship(response));
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<String>> generateInviteToken(String apprenticeshipId) async {
    try {
      const uuid = Uuid();
      final token = uuid.v4();
      await _supabase
          .from('apprenticeships')
          .update({'invite_token': token, 'invite_status': 'pending'})
          .eq('id', apprenticeshipId);
      return Success(token);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<ApprenticeTask>> createTask(ApprenticeTask task) async {
    try {
      final model = ApprenticeTaskModel.fromEntity(task);
      await _supabase
          .from('apprentice_tasks')
          .upsert(model.toJson(), onConflict: 'id');
      return Success(task);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  @override
  Future<Result<ApprenticeTask>> updateTask(ApprenticeTask task) async {
    try {
      final model = ApprenticeTaskModel.fromEntity(task);
      await _supabase
          .from('apprentice_tasks')
          .upsert(model.toJson(), onConflict: 'id');
      return Success(task);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  Apprenticeship _mapToApprenticeship(Map<String, dynamic> data) {
    return Apprenticeship(
      id: data['id'] as String,
      tailorId: (data['tailor_id'] ?? data['tailorId'] ?? '') as String,
      apprenticeId:
          (data['apprentice_id'] ?? data['apprenticeId'] ?? '') as String,
      status: _parseApprenticeshipStatus(data['status'] as String?),
      progress: (data['progress'] as num? ?? 0).toDouble(),
      startDate: data['start_date'] != null
          ? DateTime.parse(data['start_date'] as String)
          : DateTime.now(),
      skillIds: List<String>.from((data['skill_ids'] ?? []) as List),
      inviteToken: data['invite_token'] as String?,
      inviteStatus: _parseInviteStatus(data['invite_status'] as String?),
      apprenticeName: data['apprentice_name'] as String?,
      apprenticePhone: data['apprentice_phone'] as String?,
      level: data['level'] as String?,
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
      'invite_token': app.inviteToken,
      'invite_status': app.inviteStatus == InviteStatus.none
          ? null
          : app.inviteStatus.name,
      'apprentice_name': app.apprenticeName,
      'apprentice_phone': app.apprenticePhone,
      'level': app.level,
    }..removeWhere((key, value) => value == null);
  }

  ApprenticeshipStatus _parseApprenticeshipStatus(String? status) {
    if (status == null) return ApprenticeshipStatus.awaitingMasterApproval;
    return ApprenticeshipStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ApprenticeshipStatus.awaitingMasterApproval,
    );
  }

  InviteStatus _parseInviteStatus(String? status) {
    if (status == null) return InviteStatus.none;
    return InviteStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => InviteStatus.none,
    );
  }
}
