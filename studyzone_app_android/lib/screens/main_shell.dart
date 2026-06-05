import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../widgets/common/connectivity_banner.dart';
import '../widgets/common/study_zone_app_bar.dart';
import '../widgets/common/study_zone_bottom_nav.dart';
import '../widgets/common/zoom_drawer.dart';
import '../widgets/audio/mini_player.dart';
import '../widgets/home/app_drawer.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'discover/discover_screen.dart';
import 'profile/profile_view.dart';

/// The main app shell: a single Scaffold that owns the shared [StudyZoneAppBar]
/// (horizontal logo + bell), the slide-out [AppDrawer], the global mini player,
/// and the [StudyZoneBottomNav]. The four destinations (Home / Search /
/// Discover / Profile) are kept alive in an [IndexedStack] so each tab retains
/// its state when switching.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ZoomDrawerController _zoomDrawerController = ZoomDrawerController();
  StudyZoneTab _current = StudyZoneTab.home;

  static const _tabs = <Widget>[
    HomeView(),
    SearchScreen(),
    DiscoverScreen(),
    ProfileView(),
  ];

  @override
  void dispose() {
    _zoomDrawerController.dispose();
    super.dispose();
  }

  void _onSelect(StudyZoneTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _zoomDrawerController,
      child: ZoomDrawer(
        controller: _zoomDrawerController,
        menuScreen: const AppDrawer(),
        mainScreen: Builder(
          builder: (context) {
            final colors = AppColors.of(context);
            return Scaffold(
              backgroundColor: colors.background,
              appBar: StudyZoneAppBar(
                onMenu: () => _zoomDrawerController.toggle(),
              ),
              body: Column(
                children: [
                  const ConnectivityBanner(),
                  Expanded(
                    child: IndexedStack(
                      index: _current.index,
                      children: _tabs,
                    ),
                  ),
                  const MiniPlayer(),
                ],
              ),
              bottomNavigationBar: StudyZoneBottomNav(
                current: _current,
                onSelect: _onSelect,
              ),
            );
          },
        ),
      ),
    );
  }
}
