import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_model.dart';

/// Stores the materials a user has recently opened (locally) to power the
/// "Continue learning" section on Home.
class RecentContentService {
  static const String _key = 'recent_contents';
  static const int _max = 12;

  Future<List<ContentModel>> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    return raw
        .map((s) {
          try {
            return ContentModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ContentModel>()
        .toList();
  }

  Future<void> add(ContentModel content) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    // Drop any existing entry for this content id, then prepend.
    raw.removeWhere((s) {
      try {
        return (jsonDecode(s) as Map<String, dynamic>)['id'] == content.id;
      } catch (_) {
        return false;
      }
    });
    raw.insert(0, jsonEncode(content.toJson()));
    if (raw.length > _max) raw.removeRange(_max, raw.length);
    await prefs.setStringList(_key, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
