import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/achievement.dart';
import '../../services/achievement_service.dart';
import '../../screens/quiz/achievements_screen.dart';

/// Compact "Achievements" card for the Profile: shows badge count + top program
/// progress, tap to open the full Achievements screen. Renders nothing until
/// loaded.
class AchievementsSection extends StatefulWidget {
  const AchievementsSection({super.key});

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  AchievementsData? _data;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AchievementService().getAchievements();
    if (mounted) {
      setState(() {
        _data = data;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (!_loaded || _data == null) return const SizedBox.shrink();
    final data = _data!;
    final topProgram = data.programs.isNotEmpty ? data.programs.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
          ).then((_) => _load()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(LucideIcons.medal, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.earnedCount} of ${data.totalCount} badges earned',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                      if (topProgram != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: topProgram.total == 0 ? 0 : topProgram.passed / topProgram.total,
                            minHeight: 6,
                            backgroundColor: colors.border,
                            valueColor: AlwaysStoppedAnimation(colors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${topProgram.title} · ${topProgram.passed}/${topProgram.total}',
                          style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(LucideIcons.chevron_right, size: 18, color: colors.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
