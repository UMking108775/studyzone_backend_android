import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../models/quiz_model.dart';

/// A gradient summary card showing the user's quiz streak and totals.
/// Used on the Quizzes screen header.
class StreakCard extends StatelessWidget {
  final QuizStats stats;
  const StreakCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.flame, color: Colors.white, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'} streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      stats.currentStreak == 0
                          ? 'Take a quiz today to start your streak!'
                          : 'Keep it going — take a quiz today!',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('Best', '${stats.longestStreak}d', LucideIcons.trophy),
              _divider(),
              _stat('Quizzes', '${stats.totalQuizzes}', LucideIcons.list_checks),
              _divider(),
              _stat('Accuracy', '${stats.accuracy}%', LucideIcons.target),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: 0.25),
  );

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Small coloured chip for a quiz's difficulty.
class DifficultyChip extends StatelessWidget {
  final String difficulty;
  const DifficultyChip({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty.toLowerCase()) {
      'easy' => (const Color(0xFF10B981), 'Easy'),
      'hard' => (const Color(0xFFEF4444), 'Hard'),
      _ => (const Color(0xFFF59E0B), 'Medium'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
