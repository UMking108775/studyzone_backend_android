import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/quiz_model.dart';

/// Reviews a quiz's questions as flip cards: front shows the question, tap to
/// flip and reveal the answer + explanation. Swipe or use arrows to move on.
class FlashcardScreen extends StatefulWidget {
  final QuizModel quiz;
  const FlashcardScreen({super.key, required this.quiz});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  List<QuizQuestion> get _questions => widget.quiz.questions;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _questions.length) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.quiz.title, style: const TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Card ${_index + 1} of ${_questions.length}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    'Tap card to flip',
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _questions.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final q = _questions[i];
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: _FlipCard(
                      key: ValueKey('card_$i'),
                      isActive: i == _index,
                      front: _Face(
                        colors: colors,
                        label: 'QUESTION',
                        labelColor: colors.primary,
                        text: q.question,
                        background: colors.surface,
                        textColor: colors.textPrimary,
                      ),
                      back: _Face(
                        colors: colors,
                        label: 'ANSWER',
                        labelColor: Colors.white,
                        text: q.options.isNotEmpty &&
                                q.correctIndex < q.options.length
                            ? q.options[q.correctIndex]
                            : '',
                        explanation: q.explanation,
                        background: colors.primary,
                        textColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index == 0 ? null : () => _go(-1),
                      icon: const Icon(LucideIcons.chevron_left, size: 18),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: colors.border),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _index == _questions.length - 1
                          ? () => Navigator.pop(context)
                          : () => _go(1),
                      icon: Icon(
                        _index == _questions.length - 1
                            ? LucideIcons.check
                            : LucideIcons.chevron_right,
                        size: 18,
                      ),
                      label: Text(
                        _index == _questions.length - 1 ? 'Done' : 'Next',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable 3D flip card.
class _FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isActive;
  const _FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.isActive = true,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant _FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to the question side once this card scrolls off-screen.
    if (!widget.isActive && _showBack) {
      _showBack = false;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    _showBack = !_showBack;
    _showBack ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final showFront = angle <= math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  final ThemeColors colors;
  final String label;
  final Color labelColor;
  final String text;
  final String? explanation;
  final Color background;
  final Color textColor;

  const _Face({
    required this.colors,
    required this.label,
    required this.labelColor,
    required this.text,
    required this.background,
    required this.textColor,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (explanation != null && explanation!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      explanation!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
