import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/achievement_service.dart';
import 'celebration_screen.dart';
import 'quiz_play_screen.dart';

/// Shown after finishing a quiz: animated score ring, a message, the updated
/// streak and retry / done actions. Celebrates any newly-earned badges.
class QuizResultScreen extends StatefulWidget {
  final QuizModel quiz;
  final int score;
  final int total;
  final QuizStats? stats;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.score,
    required this.total,
    this.stats,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // The attempt was saved (stats non-null) — check for newly earned badges.
      if (widget.stats == null) return;
      final service = AchievementService();
      final data = await service.getAchievements();
      if (data == null) return;
      final fresh = await service.computeNewlyEarned(data);
      if (!mounted || fresh.isEmpty) return;
      // Commit "seen" only now that we're actually celebrating, so a missed
      // celebration is never silently swallowed.
      await service.markSeen(fresh);
      if (mounted) showAchievementCelebration(context, fresh);
    });
  }

  double get _pct => widget.total == 0 ? 0 : widget.score / widget.total;

  ({String title, String sub, Color color, IconData icon}) get _verdict {
    if (_pct >= 0.8) {
      return (title: 'Excellent!', sub: 'You really know your stuff.', color: const Color(0xFF10B981), icon: LucideIcons.party_popper);
    }
    if (_pct >= 0.5) {
      return (title: 'Good job!', sub: 'A little more practice and you\'ll ace it.', color: const Color(0xFFF59E0B), icon: LucideIcons.thumbs_up);
    }
    return (title: 'Keep practising', sub: 'Review and try again — you\'ve got this.', color: const Color(0xFFEF4444), icon: LucideIcons.dumbbell);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final v = _verdict;
    final score = widget.score;
    final total = widget.total;
    final stats = widget.stats;
    final quiz = widget.quiz;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: v.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(v.icon, color: v.color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                v.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                v.sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Animated score ring
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _pct),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: _RingPainter(value, v.color, colors.border),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(value * 100).round()}%',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '$score / $total correct',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (stats != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.flame, color: Color(0xFFEA580C), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.currentStreak} day streak · ${stats.quizzesPassed} quizzes passed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPlayScreen(quiz: quiz),
                        ),
                      ),
                      icon: const Icon(LucideIcons.rotate_cw, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.check, size: 18),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter(this.progress, this.color, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
