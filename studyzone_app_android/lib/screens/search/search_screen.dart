import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/content_service.dart';
import '../../widgets/home/material_card.dart';
import '../material/material_detail_screen.dart';

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
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  String? _error;
  List<ContentModel> _results = [];
  bool _hasSearched = false;

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

  Future<void> _runSearch(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
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

    // The query may have changed while awaiting; ignore stale responses.
    if (!mounted || trimmed != _controller.text.trim()) return;

    setState(() {
      _isLoading = false;
      if (response.success) {
        _results = response.data ?? [];
        _error = null;
      } else {
        _results = [];
        _error = response.message;
      }
    });
  }

  void _openContent(ContentModel content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialDetailScreen(content: content),
      ),
    );
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
            onSubmitted: _runSearch,
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
      return _Message(
        icon: LucideIcons.search,
        title: 'Find study materials',
        subtitle: 'Type to search across all PDFs, audio and videos.',
        color: colors.textHint,
      );
    }

    if (_results.isEmpty) {
      return _Message(
        icon: LucideIcons.file_question_mark,
        title: 'No results',
        subtitle: 'Nothing matched “${_controller.text.trim()}”.',
        color: colors.textHint,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final content = _results[index];
        return MaterialCard(
          content: content,
          onTap: () => _openContent(content),
        );
      },
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
