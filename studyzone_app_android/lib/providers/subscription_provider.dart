import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';

/// State for the subscription feature: plans, payment methods, and the user's
/// current status (active / pending / history).
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service;

  SubscriptionProvider({SubscriptionService? service})
      : _service = service ?? SubscriptionService();

  List<SubscriptionPlanModel> plans = [];
  List<PaymentMethodModel> paymentMethods = [];
  MySubscription? status;

  bool loadingPlans = false;
  bool loadingMethods = false;
  bool loadingStatus = false;
  bool submitting = false;

  String? plansError;
  String? methodsError;

  bool _statusLoadedOnce = false;

  // Convenience getters ------------------------------------------------------
  bool get hasActive => status?.hasActive ?? false;
  SubscriptionModel? get active => status?.active;
  SubscriptionModel? get pending => status?.pending;

  /// Load active plans (public).
  Future<void> loadPlans({bool force = false}) async {
    if (loadingPlans) return;
    if (plans.isNotEmpty && !force) return;
    loadingPlans = true;
    plansError = null;
    notifyListeners();

    final res = await _service.getPlans();
    if (res.success && res.data != null) {
      plans = res.data!;
    } else {
      plansError = res.message;
    }
    loadingPlans = false;
    notifyListeners();
  }

  /// Load payment methods (auth).
  Future<void> loadPaymentMethods({bool force = false}) async {
    if (loadingMethods) return;
    if (paymentMethods.isNotEmpty && !force) return;
    loadingMethods = true;
    methodsError = null;
    notifyListeners();

    final res = await _service.getPaymentMethods();
    if (res.success && res.data != null) {
      paymentMethods = res.data!;
    } else {
      methodsError = res.message;
    }
    loadingMethods = false;
    notifyListeners();
  }

  /// Load the user's subscription status (auth).
  Future<void> loadStatus({bool force = false}) async {
    if (loadingStatus) return;
    loadingStatus = true;
    notifyListeners();

    final res = await _service.getMyStatus();
    if (res.success && res.data != null) {
      status = res.data;
      _statusLoadedOnce = true;
    }
    loadingStatus = false;
    notifyListeners();
  }

  /// Load status once (used by lightweight entry points like the profile tile).
  Future<void> ensureStatus() async {
    if (_statusLoadedOnce) return;
    await loadStatus();
  }

  /// Submit a purchase request. On success, refreshes status.
  Future<ApiResponse> submit({
    required int planId,
    int? paymentMethodId,
    String? senderName,
    String? senderAccount,
    String? transactionReference,
    String? proofImagePath,
  }) async {
    submitting = true;
    notifyListeners();

    final res = await _service.submit(
      planId: planId,
      paymentMethodId: paymentMethodId,
      senderName: senderName,
      senderAccount: senderAccount,
      transactionReference: transactionReference,
      proofImagePath: proofImagePath,
    );

    submitting = false;
    notifyListeners();

    if (res.success) {
      await loadStatus(force: true);
    }
    return res;
  }

  /// Clear in-memory state (e.g. on logout).
  void reset() {
    plans = [];
    paymentMethods = [];
    status = null;
    _statusLoadedOnce = false;
    plansError = null;
    methodsError = null;
    notifyListeners();
  }
}
