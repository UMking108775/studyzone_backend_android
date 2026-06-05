import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/content_model.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Renders rich-text / article content (HTML [ContentModel.body]) inside a
/// WebView with a clean, theme-aware stylesheet. Handles headings, lists,
/// tables (e.g. the fee structure) and basic formatting.
class RichTextScreen extends StatefulWidget {
  final ContentModel content;
  const RichTextScreen({super.key, required this.content});

  @override
  State<RichTextScreen> createState() => _RichTextScreenState();
}

class _RichTextScreenState extends State<RichTextScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // (Re)render with the current theme colours — runs on mount and whenever
    // the theme changes, not on every build.
    _controller.loadHtmlString(_document(AppColors.of(context)));
  }

  String _document(ThemeColors colors) {
    final isDark = colors.background.computeLuminance() < 0.5;
    final text = _hex(colors.textPrimary);
    final secondary = _hex(colors.textSecondary);
    final bg = _hex(colors.background);
    final surface = _hex(colors.surface);
    final primary = _hex(colors.primary);
    final border = _hex(colors.border);
    final body = widget.content.body ?? '';

    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  :root { color-scheme: ${isDark ? 'dark' : 'light'}; }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 16px 18px 40px;
    font-family: -apple-system, Roboto, 'Segoe UI', sans-serif;
    font-size: 16px; line-height: 1.6;
    color: $text; background: $bg;
    -webkit-text-size-adjust: 100%;
  }
  h1,h2,h3,h4 { color: $text; line-height: 1.3; margin: 18px 0 10px; }
  h1 { font-size: 22px; } h2 { font-size: 20px; } h3 { font-size: 17px; }
  p { margin: 0 0 12px; }
  a { color: $primary; text-decoration: none; }
  ul,ol { margin: 0 0 12px; padding-left: 22px; }
  li { margin: 4px 0; }
  small { color: $secondary; }
  code {
    background: $surface; padding: 2px 6px; border-radius: 5px;
    font-size: 14px; border: 1px solid $border;
  }
  blockquote {
    margin: 12px 0; padding: 8px 14px; color: $secondary;
    border-left: 3px solid $primary; background: $surface; border-radius: 6px;
  }
  img { max-width: 100%; height: auto; border-radius: 8px; }
  table {
    width: 100%; border-collapse: collapse; margin: 12px 0;
    font-size: 14px; overflow: hidden; border-radius: 8px;
  }
  th, td { border: 1px solid $border; padding: 10px; text-align: left; }
  th { background: $primary; color: #fff; }
  tr:nth-child(even) td { background: $surface; }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

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
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
