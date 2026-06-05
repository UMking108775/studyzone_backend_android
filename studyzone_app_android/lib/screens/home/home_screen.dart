import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_routes.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../screens/category/category_screen.dart';
import '../../services/guest_service.dart';
import '../../widgets/home/category_card.dart';
import '../../widgets/home/recent_categories_section.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/home_banner_carousel.dart';
import '../../widgets/home/continue_learning_section.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/category/request_access_sheet.dart';
import '../../models/category_model.dart';

/// Home tab content (scaffold-less). The surrounding shell (app bar, drawer,
/// bottom navigation, mini player, connectivity banner) is provided by
/// `MainShell`, so this widget only renders the scrollable home content.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey<RecentCategoriesSectionState> _recentKey = GlobalKey();
  final GlobalKey<ContinueLearningSectionState> _continueKey = GlobalKey();

  /// Open a category and refresh the "Recently Visited" / "Continue learning"
  /// strips on return. Locked (paid) categories show a request-access sheet.
  void _openCategory(CategoryModel category) {
    if (category.isLocked) {
      RequestAccessSheet.show(context, category);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryScreen(category: category)),
    ).then((_) {
      _recentKey.currentState?.reload();
      _continueKey.currentState?.reload();
    });
  }

  @override
  void initState() {
    super.initState();
    // Load categories when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<CategoryProvider>().refreshCategories();
  }

  Future<void> _openWhatsApp() async {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.user?.email ?? '';
    // Urdu message requesting access to study materials, including the user's email.
    final message =
        'السلام علیکم، مجھے Study Zone کی اسٹڈی میٹیریل تک رسائی چاہیے۔ میرا ای میل ہے: $email';
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl =
        'https://wa.me/${AppConfig.adminWhatsApp}?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp نہیں کھل سکا: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Student';

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: colors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Featured / announcement banner carousel
          const SliverToBoxAdapter(child: HomeBannerCarousel()),

          // Compact welcome strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: userName,
                    imageUrl: authProvider.user?.avatarUrl,
                    size: 38,
                    fontSize: 17,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Continue learning (recently opened materials)
          SliverToBoxAdapter(
            child: ContinueLearningSection(key: _continueKey),
          ),

          // Offline Mode Banner
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, _) {
              if (categoryProvider.isOfflineMode) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are offline. Showing cached data.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Recently Visited (last-level categories)
          SliverToBoxAdapter(
            child: RecentCategoriesSection(
              key: _recentKey,
              onOpen: _openCategory,
            ),
          ),

          // Section Title
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Categories'),
          ),

          // Guest Mode Banner
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (!authProvider.isGuestMode) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.1),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guest Preview Mode',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can preview 1 audio & 1 PDF. Register for full access!',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            authProvider.exitGuestMode();
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          child: const Text('Login / Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Categories Grid
          Consumer2<CategoryProvider, AuthProvider>(
            builder: (context, categoryProvider, authProvider, _) {
              if (categoryProvider.isLoading &&
                  !categoryProvider.hasCategories) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (categoryProvider.errorMessage != null &&
                  !categoryProvider.hasCategories) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            categoryProvider.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                categoryProvider.loadCategories(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // No categories - show access denied message
              if (!categoryProvider.hasCategories) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: colors.error,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Access to Materials',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You don\'t have access to study materials. Please contact the administrator to get access.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _openWhatsApp,
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('Contact on WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppConfig.adminWhatsAppDisplay,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Filter categories for guest mode
              var categories = categoryProvider.categories;
              if (authProvider.isGuestMode) {
                categories = GuestService().filterCategoriesForGuest(
                  categories,
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      category: category,
                      onTap: () => _openCategory(category),
                    );
                  }, childCount: categories.length),
                ),
              );
            },
          ),

          // Bottom padding for mini player / bottom nav
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
