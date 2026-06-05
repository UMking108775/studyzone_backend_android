import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';
import '../../widgets/quiz/streak_card.dart';
import 'achievements_screen.dart';
import 'quiz_detail_screen.dart';

/// Lists available quizzes with the user's streak/stats header.
class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final QuizService _service = QuizService();
  List<QuizModel> _quizzes = [];
  QuizStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = _quizzes.isEmpty);
    final results = await Future.wait([
      _service.getQuizzes(),
      _service.getStats(),
    ]);
    if (!mounted) return;
    final quizResp = results[0] as dynamic;
    final stats = results[1] as QuizStats?;
    setState(() {
      _loading = false;
      if (quizResp.success) {
        _quizzes = quizResp.data ?? <QuizModel>[];
        _error = null;
      } else {
        _error = quizResp.message;
      }
      _stats = stats ?? _stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
        children: [
          const ScreenHeader(title: 'Quizzes & Flashcards'),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              onRefresh: _load,
              child: _buildBody(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        if (_stats != null) ...[
          StreakCard(stats: _stats!),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(LucideIcons.medal, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Achievements & Progress',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                        Text('Badges and your program completion',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevron_right, size: 18, color: colors.textHint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'Practice quizzes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null && _quizzes.isEmpty)
          _empty(colors, LucideIcons.triangle_alert, _error!)
        else if (_quizzes.isEmpty)
          _empty(colors, LucideIcons.brain, 'No quizzes available yet.')
        else
          ..._quizzes.map((q) => _quizCard(colors, q)),
      ],
    );
  }

  Widget _quizCard(ThemeColors colors, QuizModel quiz) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: quiz)),
        ).then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.brain, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quiz.categoryTitle != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(LucideIcons.folder, size: 12, color: colors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              quiz.categoryTitle!,
                              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        DifficultyChip(difficulty: quiz.difficulty),
                        const SizedBox(width: 8),
                        Icon(LucideIcons.list_checks, size: 13, color: colors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          '${quiz.questionCount} Qs',
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                        if (quiz.bestScore != null) ...[
                          const SizedBox(width: 10),
                          Icon(LucideIcons.trophy, size: 13, color: colors.textHint),
                          const SizedBox(width: 3),
                          Text(
                            'Best ${quiz.bestScore! > quiz.questionCount ? quiz.questionCount : quiz.bestScore}/${quiz.questionCount}',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevron_right, size: 18, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(ThemeColors colors, IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: colors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
