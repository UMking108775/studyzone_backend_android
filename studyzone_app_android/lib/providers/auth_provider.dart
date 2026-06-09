import 'package:flutter/material.dart';
import '../models/trial_info.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/cache_service.dart';
import '../services/push_notification_service.dart';

/// Authentication state management provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isGuestMode = false;
  bool _handlingSessionExpiry = false;
  TrialInfo? _lastTrial;

  AuthProvider({AuthService? authService})
    : _authService =
          authService ??
          AuthService(
            apiService: ApiService(),
            storageService: StorageService(),
          );

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isGuestMode => _isGuestMode;

  /// Free-trial result from the most recent successful registration (null if no
  /// trial was granted).
  TrialInfo? get lastTrial => _lastTrial;

  /// Consume the pending trial result (returns it once, then clears it) so the
  /// congrats popup is shown exactly once — on the home screen, after it loads.
  TrialInfo? takeTrial() {
    final t = _lastTrial;
    _lastTrial = null;
    return t;
  }

  /// Enter guest mode (preview without login)
  void enterGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  /// Exit guest mode
  void exitGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }

  /// Initialize auth state on app start
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      _user = await _authService.getStoredUser();
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Login user with email or phone number
  Future<bool> login({required String login, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.login(login: login, password: password);

    _isLoading = false;

    if (response.success && response.data != null) {
      _user = response.data;
      // Register this device for push as soon as we're authenticated.
      PushNotificationService.registerToken();
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastTrial = null;
    notifyListeners();

    // Stable device id lets the server stop trial-farming from one phone.
    final deviceId = await DeviceService.deviceId();

    final response = await _authService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
      deviceId: deviceId,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _user = response.data;
      _lastTrial = _authService.lastTrial;
      // Register this device for push as soon as we're authenticated.
      PushNotificationService.registerToken();
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.hasErrors
          ? response.allErrorMessages
          : response.message;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    // Clear user-specific data (but NOT downloads - they persist per user)
    try {
      // Stop and clear audio player
      final AudioService audioService = AudioService();
      await audioService.stop();

      // Clear all cached data (API response cache only)
      final CacheService cacheService = CacheService();
      await cacheService.clearAllCache();
    } catch (e) {
      debugPrint('Error clearing user data on logout: $e');
    }

    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Handle an expired/invalid session (token rejected with 401).
  /// Clears the local session without calling the logout API and forces
  /// re-login. Returns whether a session was actually expired.
  Future<bool> handleSessionExpired() async {
    if (_handlingSessionExpiry) return false;
    if (_user == null && !_isGuestMode) return false; // already logged out / nothing to do
    _handlingSessionExpiry = true;
    try {
      await _authService.clearSession();
      try {
        await AudioService().stop();
        await CacheService().clearAllCache();
      } catch (e) {
        debugPrint('Error clearing data on session expiry: $e');
      }
      _user = null;
      _isGuestMode = false;
      _errorMessage = 'Your session has expired. Please log in again.';
      notifyListeners();
      return true;
    } finally {
      // Always reset the guard, even if a listener throws during
      // notifyListeners(), so session-expiry handling never gets stuck off.
      _handlingSessionExpiry = false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _authService.updateProfile(
      name: name,
      phone: phone,
      avatarPath: avatarPath,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _user = response.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.hasErrors
          ? response.allErrorMessages
          : response.message;
      notifyListeners();
      return false;
    }
  }
}
