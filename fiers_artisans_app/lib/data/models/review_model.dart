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
      clientId: json['clientId']?.toString() ?? json['client_id']?.toString() ?? '',
      artisanId: json['artisanId']?.toString() ?? json['artisan_id']?.toString() ?? '',
      clientName: json['clientName'] ?? json['client']?['firstName'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
