/// Result of the free-trial grant returned by the register endpoint.
class TrialInfo {
  final bool granted;
  final int days;
  final DateTime? endsAt;

  const TrialInfo({required this.granted, required this.days, this.endsAt});

  factory TrialInfo.fromJson(Map<String, dynamic> json) {
    return TrialInfo(
      granted: json['granted'] == true,
      days: (json['days'] as num?)?.toInt() ?? 0,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'].toString())
          : null,
    );
  }
}
