import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/achievement_service.dart';
import '../../services/quiz_service.dart';
import '../../screens/quiz/quizzes_screen.dart';

/// Horizontal, Instagram-style "stories" strip of circular feature shortcuts.
/// Currently surfaces "Test your knowledge" (brain); more circular features can
/// be appended to the row over time.
class FeatureStories extends StatefulWidget {
  const FeatureStories({super.key});

  @override
  State<FeatureStories> createState() => _FeatureStoriesState();
}

class _FeatureStoriesState extends State<FeatureStories> {
  QuizStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
    // Silently baseline already-earned badges so only NEW unlocks celebrate.
    AchievementService().prime();
  }

  Future<void> _loadQuiz() async {
    final s = await QuizService().getStats();
    if (mounted) setState(() => _stats = s);
  }

  void _openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizzesScreen()),
    ).then((_) => _loadQuiz());
  }

  @override
  Widget build(BuildContext context) {
    final streak = _stats?.currentStreak ?? 0;
    return SizedBox(
      height: 102,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        children: [
          _StoryCircle(
            label: 'Test your\nknowledge',
            icon: LucideIcons.brain,
            gradient: const [Color(0xFF6D28D9), Color(0xFF4F46E5)],
            badge: streak > 0 ? '$streak' : null,
            badgeIcon: LucideIcons.flame,
            onTap: _openQuiz,
          ),
          // ── Future circular features go here ──
        ],
      ),
    );
  }
}

/// A single circular "story" shortcut: a gradient ring around an icon with a
/// label beneath and an optional small badge (e.g. quiz streak).
class _StoryCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String? badge;
  final IconData? badgeIcon;
  final VoidCallback onTap;

  const _StoryCircle({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badge,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient story ring.
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surface,
                    ),
                    child: Icon(icon, color: gradient.last, size: 26),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.warning,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (badgeIcon != null) ...[
                            Icon(badgeIcon, size: 10, color: Colors.white),
                            const SizedBox(width: 2),
                          ],
                          Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
