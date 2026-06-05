/// A quiz question with multiple choice options.
class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options =
        (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    var correctIndex = (json['correct_index'] as num?)?.toInt() ?? 0;
    // Guard against bad data so an option is always selectable as correct.
    if (options.isEmpty || correctIndex < 0 || correctIndex >= options.length) {
      correctIndex = 0;
    }
    return QuizQuestion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: json['question']?.toString() ?? '',
      options: options,
      correctIndex: correctIndex,
      explanation: json['explanation']?.toString(),
    );
  }
}

/// A quiz (set of questions) the user can practice.
class QuizModel {
  final int id;
  final String title;
  final String? description;
  final String difficulty; // easy | medium | hard
  final String? categoryTitle;
  final int questionCount;
  final int? bestScore;
  final List<QuizQuestion> questions;

  const QuizModel({
    required this.id,
    required this.title,
    this.description,
    this.difficulty = 'medium',
    this.categoryTitle,
    this.questionCount = 0,
    this.bestScore,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final questionsJson = json['questions'] as List?;
    return QuizModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      categoryTitle: category is Map ? category['title']?.toString() : null,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      bestScore: (json['best_score'] as num?)?.toInt(),
      questions: questionsJson != null
          ? questionsJson
                .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }
}

/// The user's quiz progress / streak summary.
class QuizStats {
  final int currentStreak;
  final int longestStreak;
  final int totalQuizzes;
  final int totalCorrect;
  final int totalQuestions;

  const QuizStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalQuizzes = 0,
    this.totalCorrect = 0,
    this.totalQuestions = 0,
  });

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      totalQuizzes: (json['total_quizzes'] as num?)?.toInt() ?? 0,
      totalCorrect: (json['total_correct'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
    );
  }

  int get accuracy =>
      totalQuestions == 0 ? 0 : ((totalCorrect / totalQuestions) * 100).round();
}
