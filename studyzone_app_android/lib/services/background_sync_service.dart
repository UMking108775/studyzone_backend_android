import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';
import 'category_service.dart';
import 'content_service.dart';
import 'help_service.dart';
import 'api_service.dart';
import '../models/category_model.dart';
import '../models/content_model.dart';

/// Background sync service for silent data synchronization
/// Automatically syncs data when app is open and internet is available
/// Enhanced with reactive streams to auto-update UI when data changes
class BackgroundSyncService extends ChangeNotifier {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final CacheService _cacheService = CacheService();
  late CategoryService _categoryService;
  late ContentService _contentService;
  late HelpService _helpService; // Cached instance to avoid memory leak

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;
  DateTime? _lastSyncTime;
  StreamSubscription? _connectivitySubscription;

  // Sync interval: 30 seconds when app is active (faster for real-time updates)
  static const int _syncIntervalSeconds = 30;

  // Stream controllers for reactive UI updates
  StreamController<List<CategoryModel>>? _categoriesController;
  StreamController<SyncEvent>? _syncEventController;

  // Last known data hashes for change detection
  int _lastCategoriesHash = 0;
  List<CategoryModel> _lastCategories = [];

  /// Stream of category updates
  Stream<List<CategoryModel>> get categoriesStream {
    _ensureControllers();
    return _categoriesController!.stream;
  }

  /// Stream of sync events (for UI to react to changes)
  Stream<SyncEvent> get syncEvents {
    _ensureControllers();
    return _syncEventController!.stream;
  }

  /// Get current categories
  List<CategoryModel> get currentCategories => _lastCategories;

  void _ensureControllers() {
    _categoriesController ??= StreamController<List<CategoryModel>>.broadcast();
    _syncEventController ??= StreamController<SyncEvent>.broadcast();
  }

  /// Initialize background sync
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _categoryService = CategoryService();
    _contentService = ContentService();
    _helpService = HelpService(apiService: ApiService()); // Initialize once
    _ensureControllers();

    // Start periodic sync
    _startPeriodicSync();

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (result.isNotEmpty && result.first != ConnectivityResult.none) {
        // Device came online - trigger sync
        _silentSync();
      }
    });

    // Do initial sync
    await _silentSync();
  }

  /// Start periodic background sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: _syncIntervalSeconds),
      (_) => _silentSync(),
    );
  }

  /// Stop background sync
  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _categoriesController?.close();
    _syncEventController?.close();
    _categoriesController = null;
    _syncEventController = null;
    _isInitialized = false;
    super.dispose();
  }

  /// Silent sync - fetches data in background without UI interruption
  Future<void> _silentSync() async {
    if (_isSyncing) return;

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.first == ConnectivityResult.none) {
      return; // No internet, skip sync
    }

    _isSyncing = true;

    try {
      debugPrint('[BackgroundSync] Starting silent sync...');

      // Sync categories and check for changes
      await _syncCategories();

      // Sync all content (materials) for active categories
      await _syncAllContent();

      // Sync tickets (only for logged in users)
      await _syncTickets();

      // Update last sync time
      await _cacheService.updateLastSyncTime();
      _lastSyncTime = DateTime.now();
      notifyListeners();

      debugPrint('[BackgroundSync] Sync completed successfully');
    } catch (e) {
      debugPrint('[BackgroundSync] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync categories recursively (Deep Sync)
  Future<void> _syncCategories() async {
    try {
      // On the very first sync of a session, seed the baseline hash from the
      // existing cache. Without this the first sync compares against 0 and is
      // silently swallowed — so a rename/edit made while the app was closed
      // would be written to cache but never pushed to the open UI.
      if (_lastCategoriesHash == 0) {
        final cached = await _cacheService.getCachedCategories();
        if (cached != null && cached.isNotEmpty) {
          _lastCategoriesHash = _calculateCategoriesHash(cached);
        }
      }

      // 1. Fetch Level 1 (Main Categories)
      final response = await _categoryService.getCategories(
        forceRefresh: true,
        background: true,
      );
      if (response.success && response.data != null) {
        final categories = response.data!;
        final activeCategories = categories.where((c) => c.isActive).toList();

        // 2. Fetch deeper levels for active categories
        // We rebuild the tree with fresh data from sub-calls
        final deepTree = await _fetchDeepTree(activeCategories);

        // 3. Calculate hash on the FULL deep tree
        final newHash = _calculateCategoriesHash(deepTree);

        // Emit whenever the fresh tree differs from the last known state
        // (seeded from cache above), so changes propagate on the first sync
        // too — not only on the second.
        final hasChanged = newHash != _lastCategoriesHash;

        _lastCategoriesHash = newHash;
        _lastCategories = deepTree;

        // 4. Update Caches
        await _cacheService.cacheCategories(deepTree);
        await _cacheSubcategoriesRecursive(deepTree);

        // 5. Notify UI
        if (hasChanged) {
          debugPrint('[BackgroundSync] Deep tree changed! Notifying UI...');
          _ensureControllers();
          _categoriesController?.add(deepTree);
          _syncEventController?.add(
            SyncEvent(
              type: SyncEventType.categoriesUpdated,
              message: 'Categories updated',
              data: deepTree,
            ),
          );
          notifyListeners();
        }

        debugPrint(
          '[BackgroundSync] categories synced: ${deepTree.length} active roots',
        );
      }
    } catch (e) {
      debugPrint('[BackgroundSync] Categories sync failed: $e');
    }
  }

  /// Helper to fetch children for list of categories
  Future<List<CategoryModel>> _fetchDeepTree(List<CategoryModel> roots) async {
    List<CategoryModel> completeRoots = [];

    for (var root in roots) {
      // Fetch children (Level 2)
      final subResponse = await _categoryService.getSubcategories(
        root.id,
        forceRefresh: true,
      );

      List<CategoryModel> children = [];
      if (subResponse.success && subResponse.data != null) {
        // Filter active children
        final activeSubs = subResponse.data!.where((c) => c.isActive).toList();

        // Fetch children of children (Level 3)
        List<CategoryModel> deepChildren = [];
        for (var sub in activeSubs) {
          final subSubResponse = await _categoryService.getSubcategories(
            sub.id,
            forceRefresh: true,
          );

          if (!subSubResponse.success) {
            throw Exception('Failed to sync deep level for category ${sub.id}');
          }

          if (subSubResponse.success && subSubResponse.data != null) {
            final activeSubSubs = subSubResponse.data!
                .where((c) => c.isActive)
                .toList();

            // Reconstruct Level 2 with its children
            // Note: CategoryModel might need 'copyWith' or we rely on 'children' field if mutable/copyable
            // Since it's final, we likely need to assume 'children' field in JSON or Constructor
            // We need to attach these children to the parent 'sub'.
            // Simplest way: The 'activeSubs' list contains Level 2 items.
            // We need to Create a new CategoryModel that is a copy of 'sub' but with 'activeSubSubs' as children.

            deepChildren.add(_copyWithChildren(sub, activeSubSubs));
          } else {
            deepChildren.add(sub);
          }
        }
        children = deepChildren;
      } else if (!subResponse.success) {
        // Safety check: if fetch failed, abort to prevent cache corruption
        throw Exception('Failed to sync level 2 for category ${root.id}');
      }

      // Reconstruct Level 1 with its children
      completeRoots.add(_copyWithChildren(root, children));
    }
    return completeRoots;
  }

  CategoryModel _copyWithChildren(
    CategoryModel original,
    List<CategoryModel> newChildren,
  ) {
    return CategoryModel(
      id: original.id,
      title: original.title,
      image: original.image,
      parentId: original.parentId,
      level: original.level,
      isActive: original.isActive,
      // Preserve access flags — dropping these here made the Free/Locked
      // badge flicker (correct on first load, gone after each sync).
      isFree: original.isFree,
      isLocked: original.isLocked,
      contentsCount: original.contentsCount,
      children: newChildren, // Attached fresh children
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
    );
  }

  /// Recursively cache subcategories from the main tree
  Future<void> _cacheSubcategoriesRecursive(
    List<CategoryModel> categories,
  ) async {
    for (final cat in categories) {
      if (cat.children.isNotEmpty) {
        // Cache children as subcategories for this parent
        await _cacheService.cacheSubcategories(cat.id, cat.children);
        // Recurse
        await _cacheSubcategoriesRecursive(cat.children);
      }
    }
  }

  /// Sync content for every category the user has actually opened — at ANY
  /// depth, not just level-1 roots. We refresh the categories we already hold
  /// a content cache for (the user's working set), most-recently-viewed first,
  /// capped so the sync stays bounded. Change is detected against the previous
  /// cache so the very first sync after an edit still notifies the UI.
  Future<void> _syncAllContent() async {
    try {
      final ids = await _cacheService.cachedContentCategoryIds();
      if (ids.isEmpty) return;

      // Bound the work: keep the most-recently-viewed categories fresh.
      final targets = ids.take(40).toList();

      bool anyContentChanged = false;

      for (final categoryId in targets) {
        // Read the previous cache BEFORE the refresh overwrites it, so we can
        // tell whether anything actually changed.
        final oldCached = await _cacheService.getCachedContent(categoryId);
        final oldHash = oldCached != null ? _hashContent(oldCached) : null;

        final response = await _contentService.getContentsByCategory(
          categoryId,
          forceRefresh: true,
          background: true,
        );

        if (response.success && response.data != null) {
          final newHash = _hashContent(response.data!);
          if (oldHash != null && oldHash != newHash) {
            anyContentChanged = true;
          }
        }

        // Small delay to keep the device/server happy.
        await Future.delayed(const Duration(milliseconds: 80));
      }

      if (anyContentChanged) {
        debugPrint('[BackgroundSync] Content changed! Notifying UI...');
        _ensureControllers();
        _syncEventController?.add(
          SyncEvent(
            type: SyncEventType.contentUpdated,
            message: 'Content updated',
            data: null, // Generic update
          ),
        );
        notifyListeners();
      }

      debugPrint('[BackgroundSync] All content synced (${targets.length})');
    } catch (e) {
      debugPrint('[BackgroundSync] Content sync failed: $e');
    }
  }

  /// Order-independent? No — order matters (reorder is a change). Hash by
  /// id + title + type + position so adds, removes, renames and reorders are
  /// all detected.
  int _hashContent(List<ContentModel> content) {
    int hash = content.length;
    for (final c in content) {
      hash = hash * 31 + c.id;
      hash = hash * 31 + c.title.hashCode;
      hash = hash * 31 + c.contentType.hashCode;
    }
    return hash;
  }

  /// Calculate hash of categories for change detection (Recursive)
  int _calculateCategoriesHash(List<CategoryModel> categories) {
    // Create a hash based on IDs, active status, titles, count, AND children
    int hash = categories.length;
    for (final cat in categories) {
      hash = hash * 31 + cat.id.hashCode;
      hash = hash * 31 + cat.isActive.hashCode;
      hash = hash * 31 + cat.title.hashCode;
      // Include access flags so toggling free/paid (or granting access)
      // in admin propagates the badge change to the UI live.
      hash = hash * 31 + cat.isFree.hashCode;
      hash = hash * 31 + cat.isLocked.hashCode;

      // Recursively hash children to detect nested changes
      if (cat.children.isNotEmpty) {
        hash = hash * 31 + _calculateCategoriesHash(cat.children);
      }
    }
    return hash;
  }

  /// Sync tickets silently for logged-in users
  Future<void> _syncTickets() async {
    try {
      // Use cached HelpService instance (not creating new one each time)
      final response = await _helpService.getMyTickets(forceRefresh: true);
      if (response.success && response.data != null) {
        debugPrint(
          '[BackgroundSync] Tickets synced: ${response.data!.length} items',
        );
      }
    } catch (e) {
      // Silently fail - user may not be logged in
      debugPrint('[BackgroundSync] Tickets sync skipped: $e');
    }
  }

  /// Force sync now (for manual refresh scenarios)
  Future<void> forceSync() async {
    // Reset hash to ensure change detection triggers
    _lastCategoriesHash = 0;
    await _cacheService.invalidateCategoriesCache();
    await _silentSync();
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Sync event types
enum SyncEventType { categoriesUpdated, contentUpdated, ticketsUpdated }

/// Sync event for UI notifications
class SyncEvent {
  final SyncEventType type;
  final String message;
  final dynamic data;

  SyncEvent({required this.type, required this.message, this.data});
}
