import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/skill_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final earnedBadgesProvider = FutureProvider<List<SkillBadge>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final supabase = Supabase.instance.client;

    // Get apprenticeship
    final appResponse = await supabase
        .from('apprenticeships')
        .select()
        .eq('apprentice_id', user.id)
        .maybeSingle();

    if (appResponse == null) return [];

    final completedLessons = await supabase
        .from('lesson_progress')
        .select('lesson_id')
        .eq('apprentice_id', appResponse['id']);

    final completedTasks = await supabase
        .from('apprentice_tasks')
        .select()
        .eq('apprentice_id', appResponse['id'])
        .eq('status', 'completed');

    final modules = await supabase
        .from('curriculum_modules')
        .select('id, lesson_ids');

    final lessonCount = (completedLessons as List).length;
    final taskCount = (completedTasks as List).length;
    final moduleCount = (modules as List).length;

    // Check which modules are fully completed
    int completedModuleCount = 0;
    for (final mod in modules) {
      final lessonIds = List<String>.from(mod['lesson_ids'] ?? []);
      final completedInModule = (completedLessons as List)
          .where((l) => lessonIds.contains(l['lesson_id']))
          .length;
      if (completedInModule == lessonIds.length && lessonIds.isNotEmpty) {
        completedModuleCount++;
      }
    }

    // Check for perfect score
    final hasPerfectScore = (completedTasks as List).any(
      (t) => (t['score'] ?? 0) == 100,
    );

    final badges = <SkillBadge>[];
    final now = DateTime.now();

    // Award badges
    if (lessonCount >= 1) {
      badges.add(
        SkillBadge(
          id: 'first_lesson',
          name: 'First Step',
          description: 'Completed your first lesson',
          icon: '📚',
          tier: 'bronze',
          earnedAt: now,
        ),
      );
    }
    if (lessonCount >= 5) {
      badges.add(
        SkillBadge(
          id: 'five_lessons',
          name: 'Eager Learner',
          description: 'Completed 5 lessons',
          icon: '🎯',
          tier: 'bronze',
          earnedAt: now,
        ),
      );
    }
    if (taskCount >= 1) {
      badges.add(
        SkillBadge(
          id: 'first_task',
          name: 'Action Taker',
          description: 'Submitted your first task',
          icon: '✍️',
          tier: 'bronze',
          earnedAt: now,
        ),
      );
    }
    if (lessonCount >= 10) {
      badges.add(
        SkillBadge(
          id: 'ten_lessons',
          name: 'Dedicated Student',
          description: 'Completed 10 lessons',
          icon: '🏅',
          tier: 'silver',
          earnedAt: now,
        ),
      );
    }
    if (completedModuleCount >= 1) {
      badges.add(
        SkillBadge(
          id: 'first_module',
          name: 'Module Master',
          description: 'Completed an entire module',
          icon: '🎓',
          tier: 'silver',
          earnedAt: now,
        ),
      );
    }
    if (taskCount >= 5) {
      badges.add(
        SkillBadge(
          id: 'five_tasks',
          name: 'Task Champion',
          description: 'Completed 5 tasks',
          icon: '🏆',
          tier: 'silver',
          earnedAt: now,
        ),
      );
    }
    if (completedModuleCount >= moduleCount && moduleCount > 0) {
      badges.add(
        SkillBadge(
          id: 'all_modules',
          name: 'Curriculum Conqueror',
          description: 'Completed all modules',
          icon: '👑',
          tier: 'gold',
          earnedAt: now,
        ),
      );
    }
    if (hasPerfectScore) {
      badges.add(
        SkillBadge(
          id: 'perfect_score',
          name: 'Perfect Score',
          description: 'Scored 100% on a task',
          icon: '💯',
          tier: 'gold',
          earnedAt: now,
        ),
      );
    }

    return badges;
  } catch (e) {
    return [];
  }
});
