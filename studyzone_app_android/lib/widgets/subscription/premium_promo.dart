import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_theme.dart';
import '../../screens/subscription/subscription_screen.dart';

/// A compact "Go Premium" upsell banner for the home screen, shown to users
/// who are not subscribed. Tapping it opens the subscription plans.
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1376 / 768,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/subscribe_banner.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Headline + button placed over the light empty area on the
                    // right ~37% of the artwork.
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: w * 0.34,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, left: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Unlock\nEverything',
                                style: TextStyle(
                                  color: Color(0xFF20245C),
                                  fontSize: 17,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All premium content',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF20245C).withValues(alpha: 0.7),
                                fontSize: 10,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colors.primary, colors.accent],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.crown, color: Colors.white, size: 13),
                                    SizedBox(width: 5),
                                    Text(
                                      'View Plans',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Time-gated premium upsell prompt. Shows a bottom sheet at most once per
/// [_interval] to users who are not subscribed — a gentle, production-style
/// reminder rather than a nag on every launch.
class PremiumPrompt {
  PremiumPrompt._();

  static const String _kKey = 'premium_prompt_last_shown';
  static const Duration _interval = Duration(hours: 24);

  static Future<void> maybeShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_kKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - last < _interval.inMilliseconds) return;

      // Let the home screen settle before interrupting.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!context.mounted) return;

      // Record only when we actually show, so a skipped prompt doesn't burn
      // the 24h window.
      await prefs.setInt(_kKey, now);
      await _showSheet(context);
    } catch (_) {
      // Never let an upsell break the app.
    }
  }

  static Future<void> _showSheet(BuildContext context) {
    final colors = AppColors.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _PremiumPromptBody(),
    );
  }
}

class _PremiumPromptBody extends StatelessWidget {
  const _PremiumPromptBody();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.crown, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock everything with Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Subscribe once and get full access to all premium study material.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            _benefit(colors, LucideIcons.folder_open, 'All locked categories unlocked'),
            _benefit(colors, LucideIcons.download, 'Download PDFs & audio'),
            _benefit(colors, LucideIcons.graduation_cap, 'Access all quizzes'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                },
                icon: const Icon(LucideIcons.crown, size: 18),
                label: const Text('View subscription plans'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe later', style: TextStyle(color: colors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(ThemeColors colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
            ),
          ),
          Icon(LucideIcons.circle_check, size: 18, color: colors.success),
        ],
      ),
    );
  }
}
