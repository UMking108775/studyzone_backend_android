import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/achievement.dart';
import '../../services/achievement_service.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/study_zone_app_bar.dart';

/// Full achievements screen: program (degree) progress + earned/locked badges.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _service = AchievementService();
  AchievementsData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAchievements();
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
        children: [
          const ScreenHeader(title: 'Achievements'),
          Divider(height: 1, color: colors.border),
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              onRefresh: _load,
              child: _buildBody(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeColors colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final data = _data;
    if (data == null) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: Text('Could not load achievements.')),
      ]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary chips
        Row(
          children: [
            _summaryChip(colors, LucideIcons.flame, '${data.currentStreak}', 'Day streak', const Color(0xFFEA580C)),
            const SizedBox(width: 10),
            _summaryChip(colors, LucideIcons.circle_check, '${data.quizzesPassed}', 'Passed', const Color(0xFF10B981)),
            const SizedBox(width: 10),
            _summaryChip(colors, LucideIcons.target, '${data.perfectScores}', 'Perfect', const Color(0xFF0EA5E9)),
          ],
        ),
        const SizedBox(height: 24),

        // Program progress
        if (data.programs.isNotEmpty) ...[
          _heading(colors, 'Your programs'),
          const SizedBox(height: 10),
          ...data.programs.map((p) => _programTile(colors, p)),
          const SizedBox(height: 22),
        ],

        // Badges
        _heading(colors, 'Badges  ·  ${data.earnedCount}/${data.totalCount}'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: data.achievements.length,
          itemBuilder: (context, i) => _badgeTile(colors, data.achievements[i]),
        ),
      ],
    );
  }

  Widget _heading(ThemeColors colors, String text) => Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
      );

  Widget _summaryChip(ThemeColors colors, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _programTile(ThemeColors colors, ProgramProgress p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.completed ? const Color(0xFF10B981) : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                p.completed ? LucideIcons.circle_check_big : LucideIcons.graduation_cap,
                color: p.completed ? const Color(0xFF10B981) : colors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.title,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${p.passed}/${p.total}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.total == 0 ? 0 : p.passed / p.total,
              minHeight: 8,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(
                p.completed ? const Color(0xFF10B981) : colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.completed ? 'Program mastered! 🎓' : '${p.percent}% complete',
            style: TextStyle(
              fontSize: 11.5,
              color: p.completed ? const Color(0xFF059669) : colors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(ThemeColors colors, Achievement a) {
    final v = achievementVisual(a);
    final earned = a.earned;
    return GestureDetector(
      onTap: () => _showBadgeInfo(colors, a),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: earned
                  ? LinearGradient(colors: [v.color, v.color.withValues(alpha: 0.7)])
                  : null,
              color: earned ? null : colors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              boxShadow: earned
                  ? [BoxShadow(color: v.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Icon(earned ? v.icon : LucideIcons.lock, color: earned ? Colors.white : colors.textHint, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: earned ? colors.textPrimary : colors.textHint,
              height: 1.1,
            ),
          ),
          if (!earned && a.hasProgress)
            Text(
              '${a.progressCurrent}/${a.progressTarget}',
              style: TextStyle(fontSize: 10, color: colors.textHint),
            ),
        ],
      ),
    );
  }

  void _showBadgeInfo(ThemeColors colors, Achievement a) {
    final v = achievementVisual(a);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: a.earned ? LinearGradient(colors: [v.color, v.color.withValues(alpha: 0.7)]) : null,
                  color: a.earned ? null : colors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(a.earned ? v.icon : LucideIcons.lock, color: a.earned ? Colors.white : colors.textHint, size: 30),
              ),
              const SizedBox(height: 14),
              Text(a.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text(a.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: colors.textSecondary)),
              if (!a.earned && a.hasProgress) ...[
                const SizedBox(height: 12),
                Text('Progress: ${a.progressCurrent}/${a.progressTarget}', style: TextStyle(fontSize: 12.5, color: colors.textHint)),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (a.earned ? const Color(0xFF10B981) : colors.textHint).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.earned ? 'Earned ✓' : 'Locked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: a.earned ? const Color(0xFF059669) : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
