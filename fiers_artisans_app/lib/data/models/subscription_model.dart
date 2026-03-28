class SubscriptionModel {
  final String id;
  final String artisanId;
  final String status; // 'active' | 'expired' | 'pending'
  final DateTime? startDate;
  final DateTime? endDate;
  final int amountFcfa;
  final String? paymentMethod;

  SubscriptionModel({
    required this.id,
    required this.artisanId,
    required this.status,
    this.startDate,
    this.endDate,
    this.amountFcfa = 5000,
    this.paymentMethod,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      artisanId: json['artisanId']?.toString() ?? '',
      status: json['status'] ?? 'expired',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      amountFcfa: json['amount'] ?? json['amountFcfa'] ?? 5000,
      paymentMethod: json['paymentMethod'],
    );
  }

  bool get isActive => status == 'active' && !isExpired;

  bool get isExpired {
    if (endDate == null) return true;
    return DateTime.now().isAfter(endDate!);
  }

  int get daysRemaining {
    if (endDate == null) return 0;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
}
