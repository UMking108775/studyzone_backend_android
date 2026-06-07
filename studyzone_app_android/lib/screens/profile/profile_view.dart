import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../models/achievement.dart';
import '../../providers/auth_provider.dart';
import '../../services/achievement_service.dart';
import '../../services/download_service.dart';
import '../../screens/quiz/achievements_screen.dart';
import '../../screens/quiz/quizzes_screen.dart';
import '../../screens/subscription/subscription_screen.dart';
import '../../widgets/common/user_avatar.dart';
import 'profile_edit_sheet.dart';

/// Profile tab content (scaffold-less). A warm, gamified profile: a level ring
/// around the avatar with XP progress, earned stats, a "next badge" nudge and a
/// badge shelf — all from the user's real achievement data.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const int _xpPerLevel = 200;

  AchievementsData? _data;
  int _downloads = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Read the user synchronously (before any await) to avoid using context
    // across an async gap.
    final user = context.read<AuthProvider>().user;
    final data = await AchievementService().getAchievements();
    int downloads = 0;
    if (user != null) {
      try {
        downloads = (await DownloadService().getDownloadsForUser(user.storageKey)).length;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _data = data;
        _downloads = downloads;
        _loading = false;
      });
    }
  }

  // ── Gamification maths (client-side, from real achievement data) ──────────
  int get _xp {
    final d = _data;
    if (d == null) return 0;
    return d.quizzesPassed * 20 +
        d.perfectScores * 15 +
        d.earnedCount * 25 +
        d.longestStreak * 5;
  }

  int get _level => (_xp ~/ _xpPerLevel) + 1;
  int get _xpIntoLevel => _xp % _xpPerLevel;
  double get _levelProgress => _xpIntoLevel / _xpPerLevel;

  /// The visual tier for the current level (drives the card's premium look).
  _Tier get _tier => _tierFor(
        _level,
        AppColors.of(context),
        Theme.of(context).brightness == Brightness.dark,
      );

  /// The closest un-earned badge with measurable progress (for the nudge).
  Achievement? get _nextBadge {
    final d = _data;
    if (d == null) return null;
    final candidates =
        d.achievements.where((a) => !a.earned && a.hasProgress).toList();
    candidates.sort((a, b) {
      final ar = a.progressTarget! - (a.progressCurrent ?? 0);
      final br = b.progressTarget! - (b.progressCurrent ?? 0);
      return ar.compareTo(br);
    });
    return candidates.isNotEmpty ? candidates.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final colors = AppColors.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      color: colors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _header(colors, user),
          const SizedBox(height: 16),
          _statsRow(colors),
          const SizedBox(height: 16),
          if (_nextBadge != null) ...[
            _nextBadgeCard(colors, _nextBadge!),
            const SizedBox(height: 16),
          ] else if (!_loading && (_data?.quizzesPassed ?? 0) == 0) ...[
            _startEarningCard(colors),
            const SizedBox(height: 16),
          ],
          _badgesCard(colors),
          const SizedBox(height: 20),

          _sectionTitle('Account'),
          const SizedBox(height: 8),
          _card([
            _InfoTile(icon: Icons.person_outline, label: 'Full Name', value: user?.name ?? 'N/A'),
            _divider(colors),
            _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? 'N/A'),
            _divider(colors),
            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? 'N/A'),
            _divider(colors),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: user?.createdAt != null
                  ? DateFormat('MMM d, yyyy').format(user!.createdAt)
                  : 'N/A',
            ),
          ]),
          const SizedBox(height: 20),

          _sectionTitle('Quick Actions'),
          const SizedBox(height: 8),
          _card([
            _ActionTile(
              icon: LucideIcons.crown,
              label: 'Subscription',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ).then((_) => _load()),
            ),
            _divider(colors),
            _ActionTile(
              icon: LucideIcons.trophy,
              label: 'Quizzes & Achievements',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizzesScreen()),
              ).then((_) => _load()),
            ),
            _divider(colors),
            _ActionTile(
              icon: LucideIcons.user_pen,
              label: 'Edit Profile',
              onTap: () => ProfileEditSheet.show(context),
            ),
            _divider(colors),
            _ActionTile(
              icon: LucideIcons.circle_question_mark,
              label: 'Help & Support',
              onTap: () => Navigator.pushNamed(context, AppRoutes.help),
            ),
            _divider(colors),
            _ActionTile(
              icon: LucideIcons.info,
              label: 'About App',
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
            ),
          ]),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: premium tiered card that levels up visually ───────────────────
  Widget _header(ThemeColors colors, user) {
    final tier = _tier;
    final ringMain = tier.ring.first;
    // Text colours adapt: rich/dark tiers (Gold+) use light text.
    final onCard = tier.dark ? Colors.white : colors.textPrimary;
    final onCardSub = tier.dark ? Colors.white70 : colors.textSecondary;
    final onCardHint =
        tier.dark ? Colors.white.withValues(alpha: 0.6) : colors.textHint;
    final trackColor =
        tier.dark ? Colors.white.withValues(alpha: 0.25) : colors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tier.bg,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tier.dark ? ringMain.withValues(alpha: 0.55) : colors.border,
          width: tier.dark ? 1.2 : 1,
        ),
        boxShadow: tier.dark
            ? [
                BoxShadow(
                  color: ringMain.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar: outer XP-progress ring + a premium gradient border ring.
              GestureDetector(
                onTap: () => ProfileEditSheet.show(context),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: CircularProgressIndicator(
                          value: _loading ? null : _levelProgress,
                          strokeWidth: 3.5,
                          backgroundColor: ringMain.withValues(alpha: 0.22),
                          valueColor: AlwaysStoppedAnimation(ringMain),
                        ),
                      ),
                      // Premium gradient circle border around the avatar.
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: tier.ring,
                          ),
                          boxShadow: tier.dark
                              ? [
                                  BoxShadow(
                                    color: ringMain.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: UserAvatar(
                          name: user?.name ?? 'S',
                          imageUrl: user?.avatarUrl,
                          size: 54,
                          fontSize: 22,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: tier.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tier.dark ? Colors.black26 : colors.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(LucideIcons.pencil,
                              size: 11,
                              color: tier.dark ? Colors.black87 : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Student',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: onCard,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Tier chip.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: tier.dark
                            ? Colors.white.withValues(alpha: 0.18)
                            : tier.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: tier.dark
                            ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tier.icon,
                              size: 13,
                              color: tier.dark ? Colors.white : tier.accent),
                          const SizedBox(width: 5),
                          Text(
                            '${tier.name} · Level $_level',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tier.dark ? Colors.white : tier.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 12, color: onCardSub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Level $_level',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: onCardSub)),
              const Spacer(),
              Text('$_xpIntoLevel / $_xpPerLevel XP',
                  style: TextStyle(fontSize: 11.5, color: onCardHint)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _loading ? null : _levelProgress,
              minHeight: 8,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(tier.dark ? tier.accent : colors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _level == 1 && _xp == 0
                  ? 'Take quizzes to earn XP'
                  : '${_xpPerLevel - _xpIntoLevel} XP to Level ${_level + 1}',
              style: TextStyle(fontSize: 10.5, color: onCardHint),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat chips ────────────────────────────────────────────────────────────
  Widget _statsRow(ThemeColors colors) {
    final d = _data;
    return Row(
      children: [
        _StatChip(
          icon: LucideIcons.flame,
          color: const Color(0xFFF59E0B),
          value: '${d?.currentStreak ?? 0}',
          label: 'Day streak',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: LucideIcons.circle_check_big,
          color: const Color(0xFF10B981),
          value: '${d?.quizzesPassed ?? 0}',
          label: 'Passed',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: LucideIcons.target,
          color: const Color(0xFF0EA5E9),
          value: '${d?.perfectScores ?? 0}',
          label: 'Perfect',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: LucideIcons.download,
          color: const Color(0xFF7C3AED),
          value: '$_downloads',
          label: 'Saved',
        ),
      ],
    );
  }

  // ── "Next badge" nudge ──────────────────────────────────────────────────
  Widget _nextBadgeCard(ThemeColors colors, Achievement a) {
    final v = achievementVisual(a);
    final current = a.progressCurrent ?? 0;
    final target = a.progressTarget ?? 1;
    final pct = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _openAchievements,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: v.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: v.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(v.icon, color: v.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next badge: ${a.title}',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(v.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$current / $target — keep going!',
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _startEarningCard(ThemeColors colors) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizzesScreen()),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.rocket, color: colors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Take your first quiz to start earning XP and badges!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            Icon(LucideIcons.chevron_right, size: 18, color: colors.primary),
          ],
        ),
      ),
    );
  }

  // ── Badge shelf ────────────────────────────────────────────────────────
  Widget _badgesCard(ThemeColors colors) {
    final d = _data;
    final badges = d?.achievements ?? const <Achievement>[];
    // Earned first, then locked.
    final sorted = [...badges]..sort((a, b) {
        if (a.earned == b.earned) return 0;
        return a.earned ? -1 : 1;
      });

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _openAchievements,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.medal, size: 16, color: const Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text('Your Badges',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const Spacer(),
                Text(
                  badges.isEmpty ? '' : '${d?.earnedCount ?? 0}/${d?.totalCount ?? 0}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                ),
                Icon(LucideIcons.chevron_right, size: 18, color: colors.textHint),
              ],
            ),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 2),
                child: Text(
                  'No badges yet — pass quizzes and build streaks to unlock them.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
              )
            else
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 4),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _BadgeDot(achievement: sorted[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    ).then((_) => _load());
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.of(context).textSecondary,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ThemeColors colors) =>
      Divider(height: 1, thickness: 0.5, color: colors.border, indent: 14, endIndent: 14);

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Logout', style: TextStyle(color: colors.textPrimary)),
          content: Text('Are you sure you want to logout?',
              style: TextStyle(color: colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: colors.error),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }
}

/// Visual tier for the profile card — it "levels up" from a soft theme tint to
/// Bronze, Silver, and then premium dark Gold / Platinum / Diamond gradients.
class _Tier {
  final String name;
  final IconData icon;
  final List<Color> bg; // header background gradient
  final List<Color> ring; // avatar gradient ring
  final Color accent; // chip + edit badge + progress on dark tiers
  final bool dark; // rich gradient → use light text

  const _Tier({
    required this.name,
    required this.icon,
    required this.bg,
    required this.ring,
    required this.accent,
    required this.dark,
  });
}

_Tier _tierFor(int level, ThemeColors colors, bool isDark) {
  if (level >= 20) {
    return const _Tier(
      name: 'Diamond',
      icon: LucideIcons.gem,
      bg: [Color(0xFF0B3D52), Color(0xFF1F8CB0), Color(0xFF5FE0E6)],
      ring: [Color(0xFF7DF9FF), Color(0xFFE0FFFF)],
      accent: Color(0xFFCFFAFE),
      dark: true,
    );
  }
  if (level >= 12) {
    return const _Tier(
      name: 'Platinum',
      icon: LucideIcons.crown,
      bg: [Color(0xFF334155), Color(0xFF64748B), Color(0xFF94A3B8)],
      ring: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
      accent: Color(0xFFF1F5F9),
      dark: true,
    );
  }
  if (level >= 8) {
    return const _Tier(
      name: 'Gold',
      icon: LucideIcons.crown,
      bg: [Color(0xFF6B5210), Color(0xFFA9821B), Color(0xFFD4A82A)],
      ring: [Color(0xFFFFD700), Color(0xFFFFF1A8)],
      accent: Color(0xFFFFE9A8),
      dark: true,
    );
  }
  if (level >= 5) {
    return _Tier(
      name: 'Silver',
      icon: LucideIcons.award,
      bg: [const Color(0xFF94A3B8).withValues(alpha: 0.20), colors.surface],
      ring: const [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
      accent: const Color(0xFF475569),
      dark: false,
    );
  }
  if (level >= 3) {
    return _Tier(
      name: 'Bronze',
      icon: LucideIcons.medal,
      bg: [const Color(0xFFB87333).withValues(alpha: 0.18), colors.surface],
      ring: const [Color(0xFFB87333), Color(0xFFE8B58A)],
      accent: const Color(0xFFB45309),
      dark: false,
    );
  }
  return _Tier(
    name: 'Starter',
    icon: LucideIcons.sprout,
    bg: [colors.primary.withValues(alpha: isDark ? 0.22 : 0.12), colors.surface],
    ring: [colors.primary, colors.primary],
    accent: colors.primary,
    dark: false,
  );
}

/// A compact earned-stat chip (streak, passed, …).
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 1),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single badge — coloured when earned, dimmed + lock when not.
class _BadgeDot extends StatelessWidget {
  final Achievement achievement;
  const _BadgeDot({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final v = achievementVisual(achievement);
    final earned = achievement.earned;
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: earned ? v.color.withValues(alpha: 0.16) : colors.border.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(
                color: earned ? v.color.withValues(alpha: 0.5) : colors.border,
              ),
            ),
            child: Icon(
              earned ? v.icon : LucideIcons.lock,
              color: earned ? v.color : colors.textHint,
              size: 20,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              color: earned ? colors.textSecondary : colors.textHint,
              fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: colors.textHint)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
