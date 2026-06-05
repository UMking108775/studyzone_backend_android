import '../models/api_response.dart';
import '../models/quiz_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Talks to the quiz API: list quizzes, fetch a quiz with questions, submit an
/// attempt and read the user's stats/streak.
class QuizService {
  final ApiService _apiService;
  final StorageService _storageService;

  QuizService({ApiService? apiService, StorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? StorageService();

  Future<ApiResponse<List<QuizModel>>> getQuizzes() async {
    final token = await _storageService.getToken();
    final response = await _apiService.get<List<dynamic>>(
      '/quizzes',
      token: token,
      fromJsonT: (data) => data as List<dynamic>,
    );
    if (response.success && response.data != null) {
      final quizzes = response.data!
          .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse(success: true, message: response.message, data: quizzes);
    }
    return ApiResponse(success: false, message: response.message);
  }

  Future<ApiResponse<QuizModel>> getQuiz(int id) async {
    final token = await _storageService.getToken();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/quizzes/$id',
      token: token,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
        success: true,
        message: response.message,
        data: QuizModel.fromJson(response.data!),
      );
    }
    return ApiResponse(success: false, message: response.message);
  }

  Future<ApiResponse<QuizStats>> submitAttempt(
    int quizId, {
    required int score,
    required int total,
  }) async {
    final token = await _storageService.getToken();
    final response = await _apiService.post<Map<String, dynamic>>(
      '/quizzes/$quizId/attempts',
      token: token,
      body: {'score': score, 'total': total},
      fromJsonT: (data) => data as Map<String, dynamic>,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
        success: true,
        message: response.message,
        data: QuizStats.fromJson(response.data!),
      );
    }
    return ApiResponse(success: false, message: response.message);
  }

  Future<QuizStats?> getStats() async {
    final token = await _storageService.getToken();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/quiz-stats',
      token: token,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );
    if (response.success && response.data != null) {
      return QuizStats.fromJson(response.data!);
    }
    return null;
  }
}
