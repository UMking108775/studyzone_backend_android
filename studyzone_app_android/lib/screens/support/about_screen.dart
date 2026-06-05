import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Polished "About" screen: brand, version, what the app does, quick links and
/// credits. Reached from Profile → About App.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = AppConfig.appVersion;

  static const String _website = 'https://studyzone.ssatechs.com';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // keep fallback
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openWhatsApp() {
    final number = AppConfig.adminWhatsApp.replaceAll('+', '');
    _open('https://wa.me/$number');
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Study Zone — access your study materials, tools and education news anytime.\n$_website',
        subject: 'Study Zone',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: ListView(
        children: [
          const ScreenHeader(title: 'About'),

          // Brand header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/studyzonelogo-square.png',
                    height: 72,
                    width: 72,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Study Zone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $_version',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your study materials, tools and education news — anytime, anywhere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // What you can do
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Text(
              'What you can do',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          _card(colors, [
            _Feature(
              icon: LucideIcons.book_open,
              color: colors.primary,
              title: 'Study materials',
              subtitle: 'Browse PDFs, audio and videos by category.',
            ),
            _Feature(
              icon: LucideIcons.search,
              color: const Color(0xFF0EA5E9),
              title: 'Search',
              subtitle: 'Find any material across the whole library.',
            ),
            _Feature(
              icon: LucideIcons.compass,
              color: const Color(0xFF8B5CF6),
              title: 'Discover',
              subtitle: 'Education & tech news from around the world.',
            ),
            _Feature(
              icon: LucideIcons.wrench,
              color: const Color(0xFFF59E0B),
              title: 'Student tools',
              subtitle: 'Scan to PDF, GPA calculator, PDF utilities & more.',
            ),
            _Feature(
              icon: LucideIcons.download,
              color: const Color(0xFF10B981),
              title: 'Offline access',
              subtitle: 'Download materials and use them without internet.',
            ),
          ]),

          // Links
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              'Connect',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          _card(colors, [
            _LinkTile(
              icon: LucideIcons.globe,
              label: 'Visit website',
              onTap: () => _open(_website),
            ),
            _LinkTile(
              icon: LucideIcons.message_circle,
              label: 'Contact on WhatsApp',
              onTap: _openWhatsApp,
            ),
            _LinkTile(
              icon: LucideIcons.share_2,
              label: 'Share app',
              onTap: _shareApp,
            ),
          ]),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${2026} Study Zone · SSA Techs',
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _card(ThemeColors colors, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19, color: colors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
              ),
            ),
            Icon(LucideIcons.chevron_right, size: 18, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
