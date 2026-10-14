import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SkillBadge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String tier; // 'bronze', 'silver', 'gold'
  final DateTime earnedAt;

  const SkillBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.earnedAt,
  });

  static IconData getIcon(String id) {
    switch (id) {
      case 'first_lesson':
        return Icons.auto_stories_rounded;
      case 'five_lessons':
        return Icons.track_changes_rounded;
      case 'first_task':
        return Icons.draw_rounded;
      case 'ten_lessons':
        return Icons.military_tech_rounded;
      case 'first_module':
        return Icons.school_rounded;
      case 'five_tasks':
        return Icons.emoji_events_rounded;
      case 'all_modules':
        return Icons.workspace_premium_rounded;
      case 'perfect_score':
        return Icons.bolt_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  /// Gradient colors for each tier
  static List<Color> tierGradient(String tier) {
    switch (tier) {
      case 'gold':
        return const [Color(0xFFFFD700), Color(0xFFFFA000), Color(0xFFFF6F00)];
      case 'silver':
        return const [Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E)];
      case 'bronze':
        return const [Color(0xFFCD7F32), Color(0xFFA0522D), Color(0xFF8B4513)];
      default:
        return const [Color(0xFF76FF03), Color(0xFF00E676), Color(0xFF00C853)];
    }
  }

  /// Glow color for each tier
  static Color tierGlow(String tier) {
    switch (tier) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFBDBDBD);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF76FF03);
    }
  }

  @override
  List<Object?> get props => [id, name, description, icon, tier, earnedAt];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'tier': tier,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  factory SkillBadge.fromMap(Map<String, dynamic> map) {
    return SkillBadge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'star',
      tier: map['tier'] ?? 'bronze',
      earnedAt: DateTime.tryParse(map['earned_at'] ?? '') ?? DateTime.now(),
    );
  }

  static List<SkillBadge> get predefined => [
    SkillBadge(
      id: 'first_lesson',
      name: 'First Step',
      description: 'Completed your first lesson',
      icon: 'auto_stories',
      tier: 'bronze',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'five_lessons',
      name: 'Eager Learner',
      description: 'Completed 5 lessons',
      icon: 'track_changes',
      tier: 'bronze',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'first_task',
      name: 'Action Taker',
      description: 'Submitted your first task',
      icon: 'draw',
      tier: 'bronze',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'ten_lessons',
      name: 'Dedicated Student',
      description: 'Completed 10 lessons',
      icon: 'military_tech',
      tier: 'silver',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'first_module',
      name: 'Module Master',
      description: 'Completed an entire module',
      icon: 'school',
      tier: 'silver',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'five_tasks',
      name: 'Task Champion',
      description: 'Completed 5 tasks',
      icon: 'emoji_events',
      tier: 'silver',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'all_modules',
      name: 'Curriculum Conqueror',
      description: 'Completed all modules',
      icon: 'workspace_premium',
      tier: 'gold',
      earnedAt: DateTime(2024),
    ),
    SkillBadge(
      id: 'perfect_score',
      name: 'Perfect Score',
      description: 'Scored 100% on a task',
      icon: 'bolt',
      tier: 'gold',
      earnedAt: DateTime(2024),
    ),
  ];
}
