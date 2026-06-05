import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A single achievement/badge as computed by the backend.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String kind; // skill | streak | program
  final bool earned;
  final int? progressCurrent;
  final int? progressTarget;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.earned,
    this.progressCurrent,
    this.progressTarget,
  });

  bool get hasProgress => progressTarget != null && progressTarget! > 0;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    return Achievement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'skill',
      earned: json['earned'] == true,
      progressCurrent: progress is Map ? (progress['current'] as num?)?.toInt() : null,
      progressTarget: progress is Map ? (progress['target'] as num?)?.toInt() : null,
    );
  }
}

/// Progress through a program's (degree's) quizzes.
class ProgramProgress {
  final int id;
  final String title;
  final int total;
  final int passed;
  final int percent;
  final bool completed;

  const ProgramProgress({
    required this.id,
    required this.title,
    required this.total,
    required this.passed,
    required this.percent,
    required this.completed,
  });

  factory ProgramProgress.fromJson(Map<String, dynamic> json) {
    return ProgramProgress(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      passed: (json['passed'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      completed: json['completed'] == true,
    );
  }
}

/// The full achievements payload.
class AchievementsData {
  final int currentStreak;
  final int longestStreak;
  final int quizzesPassed;
  final int perfectScores;
  final List<ProgramProgress> programs;
  final List<Achievement> achievements;

  const AchievementsData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.quizzesPassed = 0,
    this.perfectScores = 0,
    this.programs = const [],
    this.achievements = const [],
  });

  int get earnedCount => achievements.where((a) => a.earned).length;
  int get totalCount => achievements.length;

  factory AchievementsData.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map<String, dynamic>?) ?? const {};
    final programs = (json['programs'] as List?) ?? const [];
    final achievements = (json['achievements'] as List?) ?? const [];
    return AchievementsData(
      currentStreak: (summary['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (summary['longest_streak'] as num?)?.toInt() ?? 0,
      quizzesPassed: (summary['quizzes_passed'] as num?)?.toInt() ?? 0,
      perfectScores: (summary['perfect_scores'] as num?)?.toInt() ?? 0,
      programs: programs
          .map((e) => ProgramProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: achievements
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Visual (icon + colour) for an achievement, derived from its id/kind.
({IconData icon, Color color}) achievementVisual(Achievement a) {
  if (a.id.startsWith('program_master')) {
    return (icon: LucideIcons.graduation_cap, color: const Color(0xFF7C3AED));
  }
  switch (a.id) {
    case 'first_pass':
      return (icon: LucideIcons.sprout, color: const Color(0xFF10B981));
    case 'passed_5':
      return (icon: LucideIcons.brain, color: const Color(0xFF6366F1));
    case 'passed_15':
      return (icon: LucideIcons.award, color: const Color(0xFFDB2777));
    case 'perfect':
      return (icon: LucideIcons.target, color: const Color(0xFF0EA5E9));
    case 'streak_3':
      return (icon: LucideIcons.flame, color: const Color(0xFFF59E0B));
    case 'streak_7':
      return (icon: LucideIcons.zap, color: const Color(0xFFEA580C));
    case 'streak_30':
      return (icon: LucideIcons.trophy, color: const Color(0xFFD97706));
    default:
      return (icon: LucideIcons.medal, color: const Color(0xFFCA8A04));
  }
}
