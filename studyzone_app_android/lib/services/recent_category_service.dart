import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';

/// Stores the most recently visited "last level" categories (the ones that
/// actually contain material) for quick access on the home screen.
class RecentCategoryService {
  static const String _key = 'recent_categories_v1';
  static const int _max = 10;

  /// Record a visited category (most recent first, de-duplicated by id).
  Future<void> record(CategoryModel category) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getRecent();
    list.removeWhere((c) => c.id == category.id);
    list.insert(0, category);
    final trimmed = list.take(_max).toList();
    final jsonStr = jsonEncode(
      trimmed
          .map(
            (c) => {
              'id': c.id,
              'title': c.title,
              'image': c.image,
              'parent_id': c.parentId,
              'level': c.level,
              'is_active': c.isActive,
              'is_free': c.isFree,
              'is_locked': c.isLocked,
              'requires_subscription': c.requiresSubscription,
              'contents_count': c.contentsCount,
              'created_at': c.createdAt.toIso8601String(),
              'updated_at': c.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    );
    await prefs.setString(_key, jsonStr);
  }

  /// Get recently visited categories (most recent first).
  Future<List<CategoryModel>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> arr = jsonDecode(jsonStr);
      return arr
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
