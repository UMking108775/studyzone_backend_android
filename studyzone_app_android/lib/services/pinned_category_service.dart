import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';

/// Stores the categories a user has pinned to the home screen. Pinned
/// categories surface first (and prominently) in the "Recently Visited" strip.
class PinnedCategoryService {
  static const String _key = 'pinned_categories_v1';
  static const int _max = 12;

  /// Pinned categories, in pin order (most recently pinned first).
  Future<List<CategoryModel>> getPinned() async {
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

  Future<bool> isPinned(int id) async {
    final list = await getPinned();
    return list.any((c) => c.id == id);
  }

  /// Toggle pin state. Returns the NEW state (true = now pinned).
  Future<bool> toggle(CategoryModel category) async {
    final list = await getPinned();
    final already = list.any((c) => c.id == category.id);
    if (already) {
      list.removeWhere((c) => c.id == category.id);
    } else {
      list.insert(0, category);
    }
    await _save(list.take(_max).toList());
    return !already;
  }

  Future<void> unpin(int id) async {
    final list = await getPinned();
    list.removeWhere((c) => c.id == id);
    await _save(list);
  }

  Future<void> _save(List<CategoryModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(
      list
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
}
