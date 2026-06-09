import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../services/access_guard.dart';
import '../../widgets/common/html_content_view.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Renders rich-text / article content (HTML [ContentModel.body]) inside a
/// themed WebView. Handles headings, lists, tables (e.g. the fee structure)
/// and basic formatting.
class RichTextScreen extends StatefulWidget {
  final ContentModel content;
  const RichTextScreen({super.key, required this.content});

  @override
  State<RichTextScreen> createState() => _RichTextScreenState();
}

class _RichTextScreenState extends State<RichTextScreen>
    with ContentAccessGuard {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => guardContentAccess(widget.content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
        children: [
          ScreenHeader(title: widget.content.title),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: HtmlContentView(html: widget.content.body ?? ''),
          ),
        ],
      ),
    );
  }
}
