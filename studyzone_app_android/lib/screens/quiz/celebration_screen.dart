import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../models/achievement.dart';

/// Pushes a full-screen, animated achievement-unlock celebration with confetti.
Future<void> showAchievementCelebration(
  BuildContext context,
  List<Achievement> achievements,
) {
  if (achievements.isEmpty) return Future.value();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => CelebrationScreen(achievements: achievements),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class CelebrationScreen extends StatefulWidget {
  final List<Achievement> achievements;
  const CelebrationScreen({super.key, required this.achievements});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _glow;

  static const _palette = [
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.achievements.first;
    final extra = widget.achievements.skip(1).toList();
    final v = achievementVisual(hero);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Confetti cannons.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 22,
              maxBlastForce: 28,
              minBlastForce: 10,
              gravity: 0.25,
              colors: _palette,
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ACHIEVEMENT UNLOCKED',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Hero badge: scale-in + pulsing glow.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: AnimatedBuilder(
                      animation: _glow,
                      builder: (context, child) {
                        final t = _glow.value;
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [v.color, v.color.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: v.color.withValues(alpha: 0.4 + 0.4 * t),
                                blurRadius: 30 + 30 * t,
                                spreadRadius: 4 + 8 * t,
                              ),
                            ],
                          ),
                          child: Icon(v.icon, color: Colors.white, size: 72),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    hero.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hero.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),

                  if (extra.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: extra.map((a) {
                        final ev = achievementVisual(a);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(ev.icon, color: ev.color, size: 15),
                              const SizedBox(width: 6),
                              Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
                  ),
                ),
              ),
            ),
          ),

          // A second confetti burst from the bottom for extra flair.
          Align(
            alignment: Alignment.bottomCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: -math.pi / 2,
              emissionFrequency: 0.04,
              numberOfParticles: 14,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.3,
              colors: _palette,
            ),
          ),
        ],
      ),
    );
  }
}
