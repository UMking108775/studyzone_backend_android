// Models for the local-payment subscription feature.

/// A subscription plan offered by the admin (any duration, price, features).
class SubscriptionPlanModel {
  final int id;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final String currency;
  final List<String> features;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    this.description,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.features,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'PKR',
      features: ((json['features'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
    );
  }

  /// Friendly duration label, e.g. "1 month", "3 months", "1 year".
  String get durationLabel {
    final d = durationDays;
    if (d % 365 == 0 && d >= 365) {
      final y = d ~/ 365;
      return y == 1 ? '1 year' : '$y years';
    }
    if (d % 30 == 0 && d >= 30) {
      final m = d ~/ 30;
      return m == 1 ? '1 month' : '$m months';
    }
    if (d % 7 == 0 && d >= 7) {
      final w = d ~/ 7;
      return w == 1 ? '1 week' : '$w weeks';
    }
    return d == 1 ? '1 day' : '$d days';
  }
}

/// A local payment method the user can pay to (bank / EasyPaisa / JazzCash …).
class PaymentMethodModel {
  final int id;
  final String name;
  final String type;
  final String? accountTitle;
  final String? accountNumber;
  final String? instructions;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    this.accountTitle,
    this.accountNumber,
    this.instructions,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      accountTitle: json['account_title']?.toString(),
      accountNumber: json['account_number']?.toString(),
      instructions: json['instructions']?.toString(),
    );
  }
}

/// A single subscription record (purchase request or active subscription).
class SubscriptionModel {
  final int id;
  final String planName;
  final String status; // pending | approved | rejected
  final bool isTrial;
  final double amount;
  final String currency;
  final int? durationDays;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? adminNote;
  final DateTime? createdAt;

  SubscriptionModel({
    required this.id,
    required this.planName,
    required this.status,
    this.isTrial = false,
    required this.amount,
    required this.currency,
    this.durationDays,
    this.startsAt,
    this.endsAt,
    this.adminNote,
    this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      planName: json['plan_name']?.toString() ?? 'Subscription',
      status: json['status']?.toString() ?? 'pending',
      isTrial: json['is_trial'] == true,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'PKR',
      durationDays: (json['duration_days'] as num?)?.toInt(),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
      adminNote: json['admin_note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isApproved => status == 'approved';

  /// Approved and still within its active window.
  bool get isActive =>
      isApproved && endsAt != null && endsAt!.isAfter(DateTime.now());

  /// Days remaining for an active subscription (0 if expired/none).
  int get daysRemaining {
    if (endsAt == null) return 0;
    final diff = endsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

/// The user's subscription status snapshot.
class MySubscription {
  final bool hasActive;
  final SubscriptionModel? active;
  final SubscriptionModel? pending;
  final List<SubscriptionModel> history;

  MySubscription({
    required this.hasActive,
    this.active,
    this.pending,
    this.history = const [],
  });

  factory MySubscription.fromJson(Map<String, dynamic> json) {
    return MySubscription(
      hasActive: json['has_active_subscription'] == true,
      active: json['active'] is Map<String, dynamic>
          ? SubscriptionModel.fromJson(json['active'])
          : null,
      pending: json['pending'] is Map<String, dynamic>
          ? SubscriptionModel.fromJson(json['pending'])
          : null,
      history: ((json['history'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((e) => SubscriptionModel.fromJson(e))
          .toList(),
    );
  }

  /// The most recent rejected request (if any) — shown so the user can retry.
  SubscriptionModel? get latestRejected {
    for (final s in history) {
      if (s.isRejected) return s;
    }
    return null;
  }
}
