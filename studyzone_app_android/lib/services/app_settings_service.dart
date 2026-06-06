import 'api_service.dart';
import 'storage_service.dart';

/// App-wide settings controlled by the admin (e.g. download permissions).
class AppSettings {
  final bool allowAudioDownload;
  final bool allowVideoDownload;

  const AppSettings({
    this.allowAudioDownload = true,
    this.allowVideoDownload = true,
  });
}

/// Fetches admin-controlled app settings and caches them in memory. Defaults to
/// permissive (download allowed) until/if the server says otherwise.
class AppSettingsService {
  static AppSettings _current = const AppSettings();

  /// Last known settings (safe default until [load] completes).
  static AppSettings get current => _current;

  final ApiService _apiService;
  final StorageService _storageService;

  AppSettingsService({ApiService? apiService, StorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? StorageService();

  Future<AppSettings> load() async {
    final token = await _storageService.getToken();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/app-settings',
      token: token,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );
    if (response.success && response.data != null) {
      final data = response.data!;
      _current = AppSettings(
        allowAudioDownload: data['allow_audio_download'] != false,
        allowVideoDownload: data['allow_video_download'] != false,
      );
    }
    return _current;
  }
}
