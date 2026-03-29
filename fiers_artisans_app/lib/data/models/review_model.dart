class ReviewModel {
  final String id;
  final String clientId;
  final String artisanId;
  final String? clientName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.clientId,
    required this.artisanId,
    this.clientName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
      artisanId: json['artisan_id']?.toString() ?? json['artisanId']?.toString() ?? '',
      clientName: json['client']?['first_name'] ?? json['clientName'] ?? json['client']?['firstName'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
