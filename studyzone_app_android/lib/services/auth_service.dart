import '../models/api_response.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'cache_service.dart';

/// Authentication service handling login, register, logout
class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  /// Register a new user
  Future<ApiResponse<UserModel>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiService.post<AuthResponseData>(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone_number': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      fromJsonT: (data) => AuthResponseData.fromJson(data),
    );

    if (response.success && response.data != null) {
      final authData = response.data!;
      final user = UserModel.fromJson(authData.user);

      // Save token and user data
      await _storageService.saveToken(authData.token);
      await _storageService.saveUser(user);

      // Clear cache to ensure fresh data for new user session
      try {
        final cacheService = CacheService();
        await cacheService.clearAllCache();
      } catch (e) {
        // Ignored
      }

      return ApiResponse(success: true, message: response.message, data: user);
    }

    return ApiResponse(
      success: false,
      message: response.message,
      errors: response.errors,
    );
  }

  /// Login user with email or phone number
  Future<ApiResponse<UserModel>> login({
    required String login,
    required String password,
  }) async {
    final response = await _apiService.post<AuthResponseData>(
      '/auth/login',
      body: {'login': login, 'password': password},
      fromJsonT: (data) => AuthResponseData.fromJson(data),
    );

    if (response.success && response.data != null) {
      final authData = response.data!;
      final user = UserModel.fromJson(authData.user);

      // Save token and user data
      await _storageService.saveToken(authData.token);
      await _storageService.saveUser(user);

      // Clear cache to ensure fresh data for new user session
      try {
        final cacheService = CacheService();
        await cacheService.clearAllCache();
      } catch (e) {
        // Ignored
      }

      return ApiResponse(success: true, message: response.message, data: user);
    }

    return ApiResponse(
      success: false,
      message: response.message,
      errors: response.errors,
    );
  }

  /// Request a password-reset OTP to be emailed to [email].
  Future<ApiResponse<void>> forgotPassword({required String email}) async {
    final response = await _apiService.post(
      '/auth/forgot-password',
      body: {'email': email.trim()},
    );
    return ApiResponse(
      success: response.success,
      message: response.message,
      errors: response.errors,
    );
  }

  /// Verify the OTP and set a new password.
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiService.post(
      '/auth/reset-password',
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return ApiResponse(
      success: response.success,
      message: response.message,
      errors: response.errors,
    );
  }

  /// Get current user profile
  Future<ApiResponse<UserModel>> getProfile() async {
    final token = await _storageService.getToken();
    if (token == null) {
      return ApiResponse(
        success: false,
        message: 'No token found. Please login.',
      );
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/auth/user',
      token: token,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!);
      await _storageService.saveUser(user);

      return ApiResponse(success: true, message: response.message, data: user);
    }

    return ApiResponse(success: false, message: response.message);
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    final token = await _storageService.getToken();

    if (token != null) {
      await _apiService.post('/auth/logout', token: token);
    }

    // Clear local storage regardless of API response
    await _storageService.clearAll();

    return ApiResponse(success: true, message: 'Logged out successfully');
  }

  /// Clear the local session WITHOUT calling the logout API.
  /// Used when the token is already invalid (e.g. server returned 401).
  Future<void> clearSession() async {
    await _storageService.clearAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  /// Get stored user
  Future<UserModel?> getStoredUser() async {
    return await _storageService.getUser();
  }

  /// Update user profile. When [avatarPath] is provided, the request is sent
  /// as multipart so the image is uploaded alongside the other fields.
  Future<ApiResponse<UserModel>> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      return ApiResponse(
        success: false,
        message: 'No token found. Please login.',
      );
    }

    final ApiResponse<Map<String, dynamic>> response;

    if (avatarPath != null) {
      // Multipart upload (image + text fields).
      final fields = <String, String>{};
      if (name != null) fields['name'] = name;
      if (phone != null) fields['phone_number'] = phone;

      response = await _apiService.postMultipart<Map<String, dynamic>>(
        '/auth/update-profile',
        token: token,
        fields: fields,
        files: {'avatar': avatarPath},
        fromJsonT: (data) => data as Map<String, dynamic>,
      );
    } else {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone_number'] = phone;

      response = await _apiService.post<Map<String, dynamic>>(
        '/auth/update-profile',
        token: token,
        body: body,
        fromJsonT: (data) => data as Map<String, dynamic>,
      );
    }

    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!);
      await _storageService.saveUser(user);
      return ApiResponse(success: true, message: response.message, data: user);
    }

    return ApiResponse(
      success: false,
      message: response.message,
      errors: response.errors,
    );
  }
}
