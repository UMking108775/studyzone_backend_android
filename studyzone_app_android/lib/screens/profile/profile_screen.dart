import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../widgets/common/study_zone_app_bar.dart';
import 'profile_view.dart';

/// Routed profile screen (reached from the drawer). Uses the shared Study Zone
/// app bar and the reusable [ProfileView] body. The profile bottom-nav tab in
/// `MainShell` renders the same [ProfileView] without this scaffold.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: const ProfileView(),
    );
  }
}
