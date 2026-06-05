import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/content_model.dart';
import '../../models/search_results.dart';
import '../../providers/category_provider.dart';
import '../../services/content_service.dart';
import '../../services/recent_content_service.dart';
import '../../services/search_history_service.dart';
import '../../widgets/category/request_access_sheet.dart';
import '../../widgets/home/category_card.dart';
import '../../widgets/home/material_card.dart';
import '../category/category_screen.dart';
import '../material/material_detail_screen.dart';
import '../material/rich_text_screen.dart';
import '../video/video_player_screen.dart';

/// Search tab: search study materials/content across the whole library by
/// title (backed by the `/contents/search` API). Results open in the standard
/// [MaterialDetailScreen] so download/open behaviour is identical to browsing.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ContentService _contentService = ContentService();
  final SearchHistoryService _history = SearchHistoryService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  String? _error;
  SearchResults _results = const SearchResults();
  bool _hasSearched = false;
  List<String> _recent = [];

  /// Fallback suggestions if no categories are loaded yet.
  static const List<String> _fallbackSuggestions = [
    'Past Paper',
    'Admission',
    'Lecture',
    'Notes',
  ];

  /// Real, tappable suggestions taken from the app's own top-level categories.
  List<String> get _suggestions {
    final cats = context.read<CategoryProvider>().categories;
    if (cats.isEmpty) return _fallbackSuggestions;
    return cats.take(10).map((c) => c.title).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await _history.get();
    if (mounted) setState(() => _recent = recent);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String value, {bool save = false}) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const SearchResults();
        _error = null;
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    final response = await _contentService.searchContents(trimmed);

    if (save) {
      await _history.add(trimmed);
      _loadRecent();
    }

    // The query may have changed while awaiting; ignore stale responses.
    if (!mounted || trimmed != _controller.text.trim()) return;

    setState(() {
      _isLoading = false;
      if (response.success) {
        _results = response.data ?? const SearchResults();
        _error = null;
      } else {
        _results = const SearchResults();
        _error = response.message;
      }
    });
  }

  void _openCategory(CategoryModel category) {
    if (category.isLocked) {
      RequestAccessSheet.show(context, category);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryScreen(category: category)),
    );
  }

  /// Run a search from a tapped chip (recent or suggestion).
  void _runFromTerm(String term) {
    _controller.text = term;
    setState(() => _query = term);
    _focusNode.unfocus();
    _runSearch(term, save: true);
  }

  Future<void> _removeRecent(String term) async {
    await _history.remove(term);
    _loadRecent();
  }

  Future<void> _clearRecent() async {
    await _history.clear();
    _loadRecent();
  }

  void _openContent(ContentModel content) {
    RecentContentService().add(content);
    Widget screen;
    if (content.isRichText) {
      screen = RichTextScreen(content: content);
    } else if (content.isVideo) {
      screen = VideoPlayerScreen(content: content);
    } else {
      screen = MaterialDetailScreen(content: content);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => _runSearch(v, save: true),
            decoration: InputDecoration(
              hintText: 'Search PDFs, audio, videos…',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody(colors)),
      ],
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _Message(
        icon: LucideIcons.triangle_alert,
        title: 'Search failed',
        subtitle: _error!,
        color: colors.error,
      );
    }

    if (!_hasSearched) {
      return _buildIdle(colors);
    }

    if (_results.isEmpty) {
      return _Message(
        icon: LucideIcons.file_question_mark,
        title: 'No results',
        subtitle: 'Nothing matched “${_controller.text.trim()}”.',
        color: colors.textHint,
      );
    }

    final categories = _results.categories;
    final contents = _results.contents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        // Matching categories / topics
        if (categories.isNotEmpty) ...[
          _sectionLabel(colors, 'Categories'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) => CategoryCard(
              category: categories[i],
              onTap: () => _openCategory(categories[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Matching materials
        if (contents.isNotEmpty) ...[
          _sectionLabel(colors, 'Materials'),
          const SizedBox(height: 10),
          ...contents.map(
            (content) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MaterialCard(
                content: content,
                onTap: () => _openContent(content),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Idle (pre-typing) view: recent searches + suggested topics.
  Widget _buildIdle(ThemeColors colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel(colors, 'Recent'),
              TextButton(
                onPressed: _clearRecent,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear all',
                  style: TextStyle(fontSize: 12, color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent
                .map(
                  (term) => _Chip(
                    label: term,
                    icon: LucideIcons.clock,
                    onTap: () => _runFromTerm(term),
                    onRemove: () => _removeRecent(term),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        _sectionLabel(colors, 'Suggested topics'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map(
                (term) => _Chip(
                  label: term,
                  icon: LucideIcons.search,
                  onTap: () => _runFromTerm(term),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeColors colors, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }
}

/// A tappable search chip (recent or suggestion), optionally removable.
class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _Chip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 8, onRemove != null ? 6 : 12, 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onRemove,
                child: Icon(LucideIcons.x, size: 14, color: colors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
