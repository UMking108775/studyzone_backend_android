import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Fetches the user's achievements/program progress from the backend and tracks
/// which earned achievements have already been celebrated.
class AchievementService {
  static const String _seenKey = 'seen_achievements';

  final ApiService _apiService;
  final StorageService _storageService;

  AchievementService({ApiService? apiService, StorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? StorageService();

  Future<AchievementsData?> getAchievements() async {
    final token = await _storageService.getToken();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/achievements',
      token: token,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );
    if (response.success && response.data != null) {
      return AchievementsData.fromJson(response.data!);
    }
    return null;
  }

  /// On first ever use, silently record already-earned badges as "seen" so we
  /// don't flood an existing user with a celebration for every retroactive
  /// badge. Only badges earned AFTER this will be celebrated. No-op once primed.
  Future<void> prime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_seenKey)) return;
    final data = await getAchievements();
    if (data == null) return;
    final earned = data.achievements.where((a) => a.earned).map((a) => a.id).toList();
    await prefs.setStringList(_seenKey, earned);
  }

  /// Earned achievements that haven't been celebrated yet. READ-ONLY — does not
  /// persist anything, so a missed celebration (e.g. screen unmounted) isn't
  /// lost. Call [markSeen] only once the celebration has actually been shown.
  Future<List<Achievement>> computeNewlyEarned(AchievementsData data) async {
    final earnedIds =
        data.achievements.where((a) => a.earned).map((a) => a.id).toSet();
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey) ?? const <String>[]).toSet();
    final fresh = earnedIds.difference(seen);
    return data.achievements.where((a) => fresh.contains(a.id)).toList();
  }

  /// Records the given achievements as seen. The seen set only ever GROWS, so a
  /// badge that temporarily drops out of "earned" (e.g. access revoked) won't
  /// re-fire its celebration if it comes back.
  Future<void> markSeen(Iterable<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey) ?? const <String>[]).toSet();
    seen.addAll(achievements.map((a) => a.id));
    await prefs.setStringList(_seenKey, seen.toList());
  }
}
