import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/content_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../screens/audio/audio_player_screen.dart';
import '../../screens/material/material_detail_screen.dart';
import '../../screens/material/rich_text_screen.dart';
import '../../screens/pdf/pdf_viewer_screen.dart';
import '../../screens/quiz/quiz_detail_screen.dart';
import '../../screens/video/video_player_screen.dart';
import '../../models/quiz_model.dart';
import '../../services/audio_service.dart';
import '../../services/category_service.dart';
import '../../services/content_service.dart';
import '../../services/download_service.dart';
import '../../services/app_settings_service.dart';
import '../../services/guest_service.dart';
import '../../services/recent_category_service.dart';
import '../../services/recent_content_service.dart';
import '../../services/access_guard.dart';
import 'dart:async'; // Added
import 'package:connectivity_plus/connectivity_plus.dart'; // For connectivity check
import '../../services/background_sync_service.dart'; // Added
import '../../widgets/audio/mini_player.dart';
import '../../widgets/common/breadcrumbs.dart';
import '../../widgets/common/connectivity_banner.dart';
import '../../widgets/category/category_accordion.dart';
import '../../widgets/category/content_list.dart';
import '../../widgets/category/request_access_sheet.dart';
import '../../widgets/common/study_zone_app_bar.dart';
import '../../widgets/home/category_card.dart';

/// Screen for displaying subcategories and materials
class CategoryScreen extends StatefulWidget {
  final CategoryModel category;
  final List<BreadcrumbItem> parentBreadcrumbs;

  const CategoryScreen({
    super.key,
    required this.category,
    this.parentBreadcrumbs = const [],
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  final ContentService _contentService = ContentService();

  // The category being shown. Starts from the value passed in (from the parent
  // list) and is refreshed from the synced tree so a rename/free-toggle of THIS
  // category reflects in the header without leaving the screen.
  late CategoryModel _category;

  List<CategoryModel> _subcategories = [];
  List<ContentModel> _contents = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _syncSubscription;

  // Bumped on pull-to-refresh to force expanded accordion nodes to re-fetch.
  int _accordionRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _refreshSelfFromSync(); // pick up a fresher copy if sync already has one
    _loadData();
    _initSyncListener();
    // Refresh admin download permissions for the stream/download dialogs.
    AppSettingsService().load();
    // Re-validate access on entry: a lapsed plan locks paid categories even
    // when we arrived from a cached "Recently visited" tile.
    WidgetsBinding.instance.addPostFrameCallback((_) => _enforceCategoryAccess());
  }

  /// If the user can no longer access this category (plan lapsed / revoked),
  /// offer the subscribe sheet and leave the screen.
  Future<void> _enforceCategoryAccess() async {
    final active = context.read<SubscriptionProvider>().isCurrentlyActive;
    final ok = await AccessGuard.canOpenCategory(
      _category,
      providerActive: active,
    );
    if (!ok && mounted) {
      await RequestAccessSheet.show(context, _category);
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  void _initSyncListener() {
    // Listen for background sync events
    try {
      final syncService = BackgroundSyncService();
      if (syncService.isInitialized) {
        _syncSubscription = syncService.syncEvents.listen((event) {
          if (event.type == SyncEventType.categoriesUpdated ||
              event.type == SyncEventType.contentUpdated) {
            // Refresh data from cache (sync service already updated the cache)
            if (mounted) {
              _refreshSelfFromSync();
              _loadData(forceRefresh: false);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing sync listener: $e');
    }
  }

  /// Update this screen's own category (title, free/locked flags) from the
  /// latest synced tree, so an admin rename here shows live. Best-effort: only
  /// applies for categories present in the synced tree (it covers the common
  /// levels); deeper ones keep the title passed in and refresh on revisit.
  void _refreshSelfFromSync() {
    final fresh = _findInTree(
      BackgroundSyncService().currentCategories,
      widget.category.id,
    );
    if (fresh != null &&
        mounted &&
        (fresh.title != _category.title ||
            fresh.isFree != _category.isFree ||
            fresh.isLocked != _category.isLocked)) {
      setState(() => _category = fresh);
    }
  }

  CategoryModel? _findInTree(List<CategoryModel> tree, int id) {
    for (final c in tree) {
      if (c.id == id) return c;
      final found = _findInTree(c.children, id);
      if (found != null) return found;
    }
    return null;
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  /// Load data - uses cache first for instant display
  /// If cache exists, displays instantly without loading spinner
  Future<void> _loadData({bool forceRefresh = false}) async {
    // Only show loading if we have no data yet
    if (_subcategories.isEmpty && _contents.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Fetch subcategories (uses cache-first)
      final subcategoriesResponse = await _categoryService.getSubcategories(
        widget.category.id,
        forceRefresh: forceRefresh,
      );

      if (subcategoriesResponse.success && subcategoriesResponse.data != null) {
        _subcategories = subcategoriesResponse.data!;
      } else if (_subcategories.isEmpty) {
        // Fallback to children from passed category only if we have nothing
        _subcategories = widget.category.children;
      }

      // Load contents for this category (uses cache-first)
      final contentsResponse = await _contentService.getContentsByCategory(
        widget.category.id,
        forceRefresh: forceRefresh,
      );

      if (contentsResponse.success && contentsResponse.data != null) {
        _contents = contentsResponse.data!;
      }
    } catch (e) {
      if (_subcategories.isEmpty && _contents.isEmpty) {
        _errorMessage = 'Failed to load data';
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // This is a "last level" category (it holds material) → remember it
      // for the home screen's Recently Visited section.
      if (_contents.isNotEmpty) {
        RecentCategoryService().record(_category);
      }
    }
  }

  /// Smart refresh - refreshes this page's data AND forces expanded accordion
  /// nodes to re-fetch their children (bumping the tick).
  Future<void> _refreshData() async {
    if (mounted) setState(() => _accordionRefreshTick++);
    await _loadData(forceRefresh: true);
  }

  // Get audio files for playlist
  List<ContentModel> get _audioContents {
    return _contents
        .where((c) => c.contentType.toLowerCase() == 'audio')
        .toList();
  }

  void _openContent(ContentModel content) async {
    // Quiz item: open the quiz player (attempt). Handled before "recents" so a
    // quiz doesn't land in Continue learning (which can't render it). Quiz
    // endpoints need auth, so guests are prompted to log in.
    if (content.isQuiz) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isGuestMode || authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to take this quiz')),
        );
        return;
      }
      if (content.quizId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizDetailScreen(
              quiz: QuizModel(
                id: content.quizId!,
                title: content.title,
                questionCount: content.questionCount ?? 0,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This quiz is currently unavailable.')),
        );
      }
      return;
    }

    // Remember it for "Continue learning" on Home.
    RecentContentService().add(content);

    // Remember the EXACT category this material belongs to for "Recently
    // Visited" — this is what makes accordion (deep) levels show up there,
    // since opening them never pushes a CategoryScreen.
    final mat = content.category;
    if (mat != null) {
      RecentCategoryService().record(CategoryModel(
        id: mat.id,
        title: mat.title,
        level: mat.level,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // Rich-text / article: render the HTML body, no download needed.
    if (content.isRichText) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RichTextScreen(content: content)),
      );
      return;
    }

    final downloadService = DownloadService();

    // Check if already downloaded
    final existingDownload = await downloadService.getDownloadedItem(
      content.id,
    );
    final isDownloaded =
        existingDownload != null &&
        File(existingDownload.localPath).existsSync();

    // If audio, show stream/download dialog
    if (content.contentType.toLowerCase() == 'audio') {
      _showAudioOptionsDialog(
        content,
        isDownloaded,
        existingDownload?.localPath,
      );
    }
    // If video: YouTube links are stream-only (no file to download), so play
    // directly; other videos show the stream/download dialog (same as audio).
    else if (content.isVideo) {
      if (content.isYoutube) {
        _playVideo(content, null);
      } else {
        _showVideoOptionsDialog(
          content,
          isDownloaded,
          existingDownload?.localPath,
        );
      }
    }
    // If PDF, download first then open
    else if (content.contentType.toLowerCase() == 'pdf') {
      if (isDownloaded) {
        // Already downloaded, open directly
        _openPdfViewer(content, existingDownload.localPath);
      } else {
        // Download first
        _showPdfDownloadDialog(content);
      }
    } else {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaterialDetailScreen(content: content),
          ),
        );
      }
    }
  }

  void _playVideo(ContentModel content, String? localPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(content: content, localPath: localPath),
      ),
    );
  }

  void _downloadAndPlayVideo(ContentModel content) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (currentUser == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please login to download'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.first == ConnectivityResult.none) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadProgressDialog(
        content: content,
        userId: currentUser.storageKey,
        onComplete: (localPath) {
          Navigator.pop(ctx);
          _playVideo(content, localPath);
        },
        onError: (error) {
          Navigator.pop(ctx);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Download failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      ),
    );
  }

  void _showAudioOptionsDialog(
    ContentModel content,
    bool isDownloaded,
    String? localPath,
  ) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Stream option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_circle_outline, color: colors.primary),
              ),
              title: Text(
                'Stream Now',
                style: TextStyle(color: colors.textPrimary),
              ),
              subtitle: Text(
                'Play directly without downloading',
                style: TextStyle(color: colors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _playAudio(content, null);
              },
            ),

            // Download option — hidden when admin disabled audio downloads
            // (still shown if the user already downloaded it).
            if (isDownloaded || AppSettingsService.current.allowAudioDownload) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? colors.success.withValues(alpha: 0.1)
                        : colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDownloaded ? Icons.download_done : Icons.download_outlined,
                    color: isDownloaded ? colors.success : colors.info,
                  ),
                ),
                title: Text(
                  isDownloaded ? 'Play Downloaded' : 'Download & Play',
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  isDownloaded
                      ? 'Play from saved file (offline)'
                      : 'Save for offline listening',
                  style: TextStyle(color: colors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isDownloaded) {
                    _playAudio(content, localPath);
                  } else {
                    _downloadAndPlayAudio(content);
                  }
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVideoOptionsDialog(
    ContentModel content,
    bool isDownloaded,
    String? localPath,
  ) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.play_circle_outline, color: colors.primary),
              ),
              title: Text('Stream Now', style: TextStyle(color: colors.textPrimary)),
              subtitle: Text(
                'Play directly without downloading',
                style: TextStyle(color: colors.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _playVideo(content, null);
              },
            ),
            // Download option — hidden when admin disabled video downloads
            // (still shown if the user already downloaded it).
            if (isDownloaded || AppSettingsService.current.allowVideoDownload) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? colors.success.withValues(alpha: 0.1)
                        : colors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDownloaded ? Icons.download_done : Icons.download_outlined,
                    color: isDownloaded ? colors.success : colors.info,
                  ),
                ),
                title: Text(
                  isDownloaded ? 'Play Downloaded' : 'Download & Play',
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  isDownloaded
                      ? 'Play from saved file (offline)'
                      : 'Save for offline viewing',
                  style: TextStyle(color: colors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isDownloaded) {
                    _playVideo(content, localPath);
                  } else {
                    _downloadAndPlayVideo(content);
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _playAudio(ContentModel content, String? localPath) {
    // Streaming needs a valid absolute URL (downloaded files are exempt).
    if (localPath == null && !content.hasPlayableUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This audio has no valid URL.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final audioService = context.read<AudioService>();

    if (localPath != null) {
      // Play from local path - single track only
      audioService.initSingle(content, localPath: localPath);
    } else if (authProvider.isGuestMode) {
      // Guest mode: only pass the single allowed audio, no playlist access
      audioService.initSingle(content);
    } else {
      // Logged in user: full playlist access
      final audioList = _audioContents;
      final index = audioList.indexWhere((c) => c.id == content.id);
      audioService.initPlaylist(audioList, index >= 0 ? index : 0);
    }
    audioService.play();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
    );
  }

  void _downloadAndPlayAudio(ContentModel content) async {
    // Get context-dependent values before async operations
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (currentUser == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please login to download'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check connectivity first
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.first == ConnectivityResult.none) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Show download progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadProgressDialog(
        content: content,
        userId: currentUser.storageKey,
        onComplete: (localPath) {
          Navigator.pop(ctx);
          _playAudio(content, localPath);
        },
        onError: (error) {
          Navigator.pop(ctx);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Download failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      ),
    );
  }

  void _showPdfDownloadDialog(ContentModel content) async {
    // Get context-dependent values before async operations
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (currentUser == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please login to download'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check connectivity first
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.first == ConnectivityResult.none) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadProgressDialog(
        content: content,
        userId: currentUser.storageKey,
        onComplete: (localPath) {
          Navigator.pop(ctx);
          _openPdfViewer(content, localPath);
        },
        onError: (error) {
          Navigator.pop(ctx);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Download failed: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      ),
    );
  }

  void _openPdfViewer(ContentModel content, String localPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(content: content, localPath: localPath),
      ),
    );
  }

  List<BreadcrumbItem> get _breadcrumbs {
    return [
      ...widget.parentBreadcrumbs,
      BreadcrumbItem(title: _category.title, category: _category),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const StudyZoneAppBar(),
      body: Column(
            children: [
              const ConnectivityBanner(),
              // The breadcrumb's bold trailing crumb is the page title, so a
              // separate ScreenHeader here was redundant and ate space above
              // the fold — removed.
              Breadcrumbs(items: _breadcrumbs),
              Divider(height: 1, color: colors.border),

              // Main Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorState(colors)
                    : _buildContent(colors),
              ),

              // Mini Player
              const MiniPlayer(),
            ],
          ),
    );
  }

  Widget _buildErrorState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: colors.textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeColors colors) {
    if (_subcategories.isEmpty && _contents.isEmpty) {
      // Scrollable + RefreshIndicator so a transient empty load (before sync
      // catches up) is recoverable with a pull, like every other screen.
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: colors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textHint),
            ),
          ],
        ),
      );
    }

    final authProvider = context.read<AuthProvider>();
    var displaySubcategories = _subcategories;
    var displayContents = _contents;

    // Filter for guest mode
    if (authProvider.isGuestMode) {
      final guestService = GuestService();
      displaySubcategories = guestService.filterCategoriesForGuest(
        _subcategories,
      );
      displayContents = guestService.filterContentForGuest(
        _contents,
        getFileType: (c) => c.contentType,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: colors.primary, // Add refresh color
      child: ListView(
        // Tight horizontal padding so cards/accordion use near-full width
        // (the nested accordion insets compound, so every px of width matters).
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        children: [
          // Guest Mode Limits Banner
          if (authProvider.isGuestMode)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Guest Mode: Showing limited content (${displaySubcategories.length} subcategory, ${displayContents.where((c) => c.contentType.toLowerCase().contains('audio')).length} audio, ${displayContents.where((c) => c.contentType.toLowerCase().contains('pdf')).length} PDF).',
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // Subcategories Section.
          // Levels 1-2 navigate as cards (new screen per level). From level 3
          // onward the whole remaining tree is shown inline as an accordion,
          // so the user expands downward instead of opening more screens.
          if (displaySubcategories.isNotEmpty) ...[
            Text(
              'Subcategories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.parentBreadcrumbs.length + 1 >= 3)
              CategoryAccordion(
                categories: displaySubcategories,
                onOpenContent: _openContent,
                depth: 0,
                trail: _breadcrumbs,
                refreshTick: _accordionRefreshTick,
                // Past the inline depth cap, a deeper category re-roots into a
                // fresh screen. `parentBreadcrumbs` already includes every
                // inline ancestor, so the breadcrumb trail stays unbroken.
                onOpenCategory: (cat, parentBreadcrumbs) {
                  if (cat.isLocked) {
                    RequestAccessSheet.show(context, cat);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryScreen(
                        category: cat,
                        parentBreadcrumbs: parentBreadcrumbs,
                      ),
                    ),
                  );
                },
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: displaySubcategories.length,
                itemBuilder: (context, index) {
                  final subcategory = displaySubcategories[index];
                  return CategoryCard(
                    category: subcategory,
                    onTap: () {
                      if (subcategory.isLocked) {
                        RequestAccessSheet.show(context, subcategory);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryScreen(
                            category: subcategory,
                            parentBreadcrumbs: widget.parentBreadcrumbs.isEmpty
                                ? [BreadcrumbItem(title: _category.title)]
                                : [
                                    ...widget.parentBreadcrumbs,
                                    BreadcrumbItem(title: _category.title),
                                  ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
          ],

          // Materials Section — shown as-is, in sort order (no type grouping).
          if (displayContents.isNotEmpty) ...[
            Text(
              'Materials',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ContentList(
              contents: displayContents,
              onOpen: _openContent,
            ),
          ],
        ],
      ),
    );
  }
}

/// Download progress dialog
class _DownloadProgressDialog extends StatefulWidget {
  final ContentModel content;
  final String userId;
  final void Function(String localPath) onComplete;
  final void Function(String error) onError;

  const _DownloadProgressDialog({
    required this.content,
    required this.userId,
    required this.onComplete,
    required this.onError,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      // One configured-Dio path handles any host (User-Agent, redirects,
      // timeouts) and derives the file extension from the URL.
      final item = await DownloadService().downloadContent(
        widget.content,
        widget.userId,
        onProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() => _isComplete = true);

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 300));

      widget.onComplete(item.localPath);
    } catch (e) {
      widget.onError(DownloadService.describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: _isComplete
                ? Icon(Icons.check, size: 40, color: colors.success)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation(colors.primary),
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            _isComplete ? 'Download Complete!' : 'Downloading...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content.title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
