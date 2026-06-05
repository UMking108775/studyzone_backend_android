import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';
import '../../widgets/quiz/streak_card.dart';
import 'flashcard_screen.dart';
import 'quiz_play_screen.dart';

/// Intro screen for a quiz: shows details and lets the user start the quiz
/// (MCQ) or review it as flashcards. Loads the full quiz (with questions).
class QuizDetailScreen extends StatefulWidget {
  final QuizModel quiz; // preview (no questions) from the list
  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final QuizService _service = QuizService();
  QuizModel? _full;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await _service.getQuiz(widget.quiz.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        _full = response.data;
      } else {
        _error = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final quiz = _full ?? widget.quiz;
    final hasQuestions = (_full?.questions.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
        children: [
          const ScreenHeader(title: 'Quiz'),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    DifficultyChip(difficulty: quiz.difficulty),
                    if (quiz.categoryTitle != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          quiz.categoryTitle!,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  quiz.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (quiz.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    quiz.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        colors,
                        LucideIcons.list_checks,
                        '${quiz.questionCount}',
                        'Questions',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoTile(
                        colors,
                        LucideIcons.trophy,
                        quiz.bestScore != null ? '${quiz.bestScore}' : '—',
                        'Best score',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null || !hasQuestions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error ?? 'This quiz has no questions yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPlayScreen(quiz: _full!),
                        ),
                      ),
                      icon: const Icon(LucideIcons.circle_play, size: 20),
                      label: const Text('Start Quiz'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlashcardScreen(quiz: _full!),
                        ),
                      ),
                      icon: const Icon(LucideIcons.layers, size: 20),
                      label: const Text('Review as Flashcards'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colors.primary),
                        foregroundColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeColors colors, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
