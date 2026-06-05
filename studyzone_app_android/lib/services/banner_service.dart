import '../models/banner_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Fetches the Home promotional banners from the backend.
class BannerService {
  final ApiService _apiService;
  final StorageService _storageService;

  BannerService({ApiService? apiService, StorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? StorageService();

  Future<List<BannerModel>> getBanners() async {
    final token = await _storageService.getToken();
    final response = await _apiService.get<List<dynamic>>(
      '/banners',
      token: token,
      fromJsonT: (data) => data as List<dynamic>,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .where((b) => b.imageUrl.isNotEmpty)
          .toList();
    }
    return [];
  }
}
