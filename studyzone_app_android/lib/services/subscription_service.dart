import '../models/api_response.dart';
import '../models/subscription_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// API calls for the local-payment subscription feature.
class SubscriptionService {
  final ApiService _apiService;
  final StorageService _storageService;

  SubscriptionService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  /// Public: active subscription plans.
  Future<ApiResponse<List<SubscriptionPlanModel>>> getPlans() async {
    try {
      final response = await _apiService.get('/subscription-plans', token: null);
      if (response.success && response.data is List) {
        final plans = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => SubscriptionPlanModel.fromJson(e))
            .toList();
        return ApiResponse(success: true, message: response.message, data: plans);
      }
      return ApiResponse(success: false, message: response.message);
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to load plans: $e');
    }
  }

  /// Auth: payment methods the user can pay to.
  Future<ApiResponse<List<PaymentMethodModel>>> getPaymentMethods() async {
    final token = await _storageService.getToken();
    if (token == null) {
      return ApiResponse(success: false, message: 'Please login first');
    }
    try {
      final response = await _apiService.get('/payment-methods', token: token);
      if (response.success && response.data is List) {
        final methods = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => PaymentMethodModel.fromJson(e))
            .toList();
        return ApiResponse(success: true, message: response.message, data: methods);
      }
      return ApiResponse(success: false, message: response.message);
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to load payment methods: $e');
    }
  }

  /// Auth: the user's subscription status (active + pending + history).
  Future<ApiResponse<MySubscription>> getMyStatus() async {
    final token = await _storageService.getToken();
    if (token == null) {
      return ApiResponse(success: false, message: 'Please login first');
    }
    try {
      final response = await _apiService.get(
        '/subscriptions/me',
        token: token,
        suppressAuthRedirect: true,
      );
      if (response.success && response.data is Map<String, dynamic>) {
        return ApiResponse(
          success: true,
          message: response.message,
          data: MySubscription.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return ApiResponse(success: false, message: response.message);
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to load subscription: $e');
    }
  }

  /// Auth: submit a subscription purchase request (with optional proof image).
  Future<ApiResponse> submit({
    required int planId,
    int? paymentMethodId,
    String? senderName,
    String? senderAccount,
    String? transactionReference,
    String? proofImagePath,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      return ApiResponse(success: false, message: 'Please login first');
    }
    try {
      final fields = <String, String>{
        'subscription_plan_id': planId.toString(),
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId.toString(),
        if (senderName != null && senderName.trim().isNotEmpty)
          'sender_name': senderName.trim(),
        if (senderAccount != null && senderAccount.trim().isNotEmpty)
          'sender_account': senderAccount.trim(),
        if (transactionReference != null && transactionReference.trim().isNotEmpty)
          'transaction_reference': transactionReference.trim(),
      };

      final files = <String, String>{
        if (proofImagePath != null && proofImagePath.isNotEmpty) 'proof': proofImagePath,
      };

      final response = await _apiService.postMultipart(
        '/subscriptions',
        token: token,
        fields: fields,
        files: files.isEmpty ? null : files,
      );

      return response;
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to submit request: $e');
    }
  }
}
