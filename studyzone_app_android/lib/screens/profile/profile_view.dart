import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/user_avatar.dart';
import 'profile_edit_sheet.dart';

/// Profile tab content (scaffold-less). The app bar / drawer / bottom nav are
/// owned by the surrounding shell or host screen.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => ProfileEditSheet.show(context),
                  child: UserAvatar(
                    name: user?.name ?? 'S',
                    imageUrl: user?.avatarUrl,
                    size: 84,
                    fontSize: 34,
                    background: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  user?.name ?? 'Student',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Email Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.email ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info Section
          _buildSectionTitle('Account Information'),
          const SizedBox(height: 8),
          _buildInfoCard([
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: user?.name ?? 'N/A',
            ),
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? 'N/A',
            ),
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user?.phone ?? 'N/A',
            ),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: user?.createdAt != null
                  ? DateFormat('MMM d, yyyy').format(user!.createdAt)
                  : 'N/A',
            ),
          ]),
          const SizedBox(height: 20),

          // Quick Actions
          _buildSectionTitle('Quick Actions'),
          const SizedBox(height: 8),
          _buildInfoCard([
            _ActionTile(
              icon: LucideIcons.user_pen,
              label: 'Edit Profile',
              onTap: () => ProfileEditSheet.show(context),
            ),
            _ActionTile(
              icon: LucideIcons.circle_question_mark,
              label: 'Help & Support',
              onTap: () => Navigator.pushNamed(context, AppRoutes.help),
            ),
            _ActionTile(
              icon: LucideIcons.info,
              label: 'About App',
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
            ),
          ]),
          const SizedBox(height: 20),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.of(context).textSecondary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Logout', style: TextStyle(color: colors.textPrimary)),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
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
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

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
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colors.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
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

  const _ActionTile({
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
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
