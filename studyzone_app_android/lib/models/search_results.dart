import 'category_model.dart';
import 'content_model.dart';

/// Combined search results: matching categories (topics/folders) and materials.
class SearchResults {
  final List<CategoryModel> categories;
  final List<ContentModel> contents;

  const SearchResults({
    this.categories = const [],
    this.contents = const [],
  });

  bool get isEmpty => categories.isEmpty && contents.isEmpty;
}
