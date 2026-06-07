import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/zoom_drawer.dart';
import '../../screens/downloads/my_downloaded_audio_screen.dart';
import '../../screens/downloads/my_downloaded_pdf_screen.dart';

/// Modern light-themed app drawer
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = ''; // Dynamic version

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    }
  }

  void _closeDrawer(BuildContext context) {
    try {
      context.read<ZoomDrawerController>().close();
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    _closeDrawer(context);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final colors = AppColors.of(context);

    return Container(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand hero section - full-width square logo (auto height)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.border, width: 1),
                ),
              ),
              child: Image.asset(
                'assets/images/studyzonelogo-square-drawer.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),

            // User Profile Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.08),
                    colors.primary.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  UserAvatar(
                    name: authProvider.isGuestMode
                        ? 'G'
                        : (user?.name ?? 'S'),
                    imageUrl: authProvider.isGuestMode ? null : user?.avatarUrl,
                    size: 44,
                    fontSize: 18,
                    background: authProvider.isGuestMode
                        ? Colors.grey
                        : colors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.isGuestMode
                              ? 'Guest User'
                              : (user?.name ?? 'Student'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.isGuestMode
                              ? 'Limited Access'
                              : (user?.email ?? 'Student'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: authProvider.isGuestMode
                                ? Colors.orange
                                : colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Compact Theme Toggle
                  const _CompactThemeToggle(),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _MenuItem(
                    icon: LucideIcons.house,
                    label: 'Home',
                    onTap: () {
                      _closeDrawer(context);
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),

                  // Subscription (hidden for guests — requires an account)
                  if (!authProvider.isGuestMode)
                    _MenuItem(
                      icon: LucideIcons.crown,
                      label: 'Subscription',
                      subtitle: 'Unlock all premium content',
                      onTap: () {
                        _closeDrawer(context);
                        Navigator.pushNamed(context, AppRoutes.subscription);
                      },
                    ),

                  const _SectionDivider(title: 'Utilities'),
                  _MenuItem(
                    icon: LucideIcons.wrench,
                    label: 'Student Tools',
                    subtitle: 'PDF tools, GPA calculator & more',
                    onTap: () {
                      _closeDrawer(context);
                      Navigator.pushNamed(context, AppRoutes.tools);
                    },
                  ),

                  // Only show downloads section for logged-in users (not guests)
                  if (!authProvider.isGuestMode) ...[
                    const _SectionDivider(title: 'My Downloads'),
                    _MenuItem(
                      icon: LucideIcons.music,
                      label: 'Audio Files',
                      onTap: () =>
                          _navigateTo(context, const MyDownloadedAudioScreen()),
                    ),
                    _MenuItem(
                      icon: LucideIcons.file_text,
                      label: 'PDF Documents',
                      onTap: () =>
                          _navigateTo(context, const MyDownloadedPDFScreen()),
                    ),
                  ],
                  const _SectionDivider(title: 'More'),
                  _MenuItem(
                    icon: LucideIcons.link,
                    label: 'Important Links',
                    onTap: () {
                      _closeDrawer(context);
                      Navigator.pushNamed(context, '/important-links');
                    },
                  ),
                  // Profile, Help & Support and Logout intentionally removed —
                  // they live in the Profile tab to avoid duplication.
                ],
              ),
            ),

            // Bottom Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Text(
                'Study Zone ${_appVersion.isNotEmpty ? _appVersion : "v1.0.0"}',
                style: TextStyle(fontSize: 11, color: colors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;
  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.of(context).textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textHint,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact theme toggle for drawer header
class _CompactThemeToggle extends StatelessWidget {
  const _CompactThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = AppColors.of(context);
    final mode = themeProvider.themeMode;

    IconData icon;
    Color color;

    // Cycle: Light -> Dark -> System -> Light
    switch (mode) {
      case AppThemeMode.light:
        icon = Icons.light_mode_rounded;
        color = Colors.orange;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode_rounded;
        color = Colors.purpleAccent;
        break;
      case AppThemeMode.system:
        icon = Icons.settings_suggest_rounded;
        color = colors.textSecondary;
        break;
    }

    return Tooltip(
      message: 'Theme: ${mode.name.toUpperCase()}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Cycle logic
            if (mode == AppThemeMode.light) {
              themeProvider.setThemeMode(AppThemeMode.dark);
            } else if (mode == AppThemeMode.dark) {
              themeProvider.setThemeMode(AppThemeMode.system);
            } else {
              themeProvider.setThemeMode(AppThemeMode.light);
            }
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              color: colors.surface,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
