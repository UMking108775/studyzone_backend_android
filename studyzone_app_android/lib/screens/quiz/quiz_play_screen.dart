import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';
import 'quiz_result_screen.dart';

/// Plays a quiz as multiple-choice questions, one at a time, with immediate
/// feedback and explanations, then submits the score.
class QuizPlayScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final QuizService _service = QuizService();

  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0;
  bool _submitting = false;

  List<QuizQuestion> get _questions => widget.quiz.questions;
  QuizQuestion get _q => _questions[_index];
  bool get _isLast => _index == _questions.length - 1;

  void _select(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == _q.correctIndex) _score++;
    });
  }

  Future<void> _next() async {
    if (!_isLast) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      return;
    }
    // Finish — submit the attempt.
    setState(() => _submitting = true);
    final response = await _service.submitAttempt(
      widget.quiz.id,
      score: _score,
      total: _questions.length,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    // On failure, keep the user here so they can tap Finish again.
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your result. Check your connection and tap Finish again."),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quiz: widget.quiz,
          score: _score,
          total: _questions.length,
          stats: response.data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'This quiz has no questions yet.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: close + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_index + (_answered ? 1 : 0)) / _questions.length,
                        minHeight: 8,
                        backgroundColor: colors.border,
                        valueColor: AlwaysStoppedAnimation(colors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1}/${_questions.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _q.question,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(_q.options.length, (i) => _option(colors, i)),
                    if (_answered && (_q.explanation?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.lightbulb, size: 18, color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _q.explanation!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Next / Finish
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!_answered || _submitting) ? null : _next,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLast ? 'Finish' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(ThemeColors colors, int i) {
    final isCorrect = i == _q.correctIndex;
    final isSelected = i == _selected;

    Color border = colors.border;
    Color bg = colors.surface;
    Color fg = colors.textPrimary;
    Widget? trailing;

    if (_answered) {
      if (isCorrect) {
        border = const Color(0xFF10B981);
        bg = const Color(0xFF10B981).withValues(alpha: 0.1);
        trailing = const Icon(LucideIcons.circle_check, color: Color(0xFF10B981), size: 20);
      } else if (isSelected) {
        border = const Color(0xFFEF4444);
        bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        trailing = const Icon(LucideIcons.circle_x, color: Color(0xFFEF4444), size: 20);
      }
    }

    final letter = String.fromCharCode(65 + i);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _answered ? null : () => _select(i),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _answered && (isCorrect || isSelected)
                        ? border
                        : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _q.options[i],
                  style: TextStyle(fontSize: 15, color: fg, height: 1.3),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
