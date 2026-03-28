class ArtisanModel {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String profession;
  final String? description;
  final int experienceYears;
  final String city;
  final String commune;
  final double? latitude;
  final double? longitude;
  final double averageRating;
  final int totalReviews;
  final String? profilePhotoUrl;
  final bool isVerified;
  final bool isCertified;
  final bool isAvailable;
  final bool hasActiveSubscription;
  final String? categoryId;
  final String? categoryName;
  final double? distance; // Calculated by backend search
  final DateTime? createdAt;

  ArtisanModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.profession,
    this.description,
    this.experienceYears = 0,
    required this.city,
    required this.commune,
    this.latitude,
    this.longitude,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.profilePhotoUrl,
    this.isVerified = false,
    this.isCertified = false,
    this.isAvailable = true,
    this.hasActiveSubscription = false,
    this.categoryId,
    this.categoryName,
    this.distance,
    this.createdAt,
  });

  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profile object from backend
    final profile = json['artisanProfile'] ?? json['profile'] ?? json;
    final user = json['user'] ?? json;

    return ArtisanModel(
      id: profile['id']?.toString() ?? json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? json['userId']?.toString() ?? '',
      firstName: user['firstName'] ?? json['firstName'] ?? '',
      lastName: user['lastName'] ?? json['lastName'] ?? '',
      phone: user['phone'] ?? json['phone'] ?? '',
      email: user['email'] ?? json['email'],
      profession: profile['profession'] ?? json['profession'] ?? '',
      description: profile['description'] ?? json['description'],
      experienceYears:
          profile['experienceYears'] ?? json['experienceYears'] ?? 0,
      city: profile['city'] ?? json['city'] ?? '',
      commune: profile['commune'] ?? json['commune'] ?? '',
      latitude: _toDouble(profile['latitude'] ?? json['latitude']),
      longitude: _toDouble(profile['longitude'] ?? json['longitude']),
      averageRating:
          _toDouble(profile['averageRating'] ?? json['averageRating']) ?? 0.0,
      totalReviews: profile['totalReviews'] ?? json['totalReviews'] ?? 0,
      profilePhotoUrl:
          profile['profilePhotoUrl'] ?? json['profilePhotoUrl'],
      isVerified: profile['isVerified'] ?? json['isVerified'] ?? false,
      isCertified: profile['isCertified'] ?? json['isCertified'] ?? false,
      isAvailable: profile['isAvailable'] ?? json['isAvailable'] ?? true,
      hasActiveSubscription: profile['hasActiveSubscription'] ??
          json['hasActiveSubscription'] ??
          false,
      categoryId: profile['categoryId']?.toString() ??
          json['categoryId']?.toString(),
      categoryName: json['categoryName'],
      distance: _toDouble(json['distance']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String get fullName => '$firstName $lastName';
}
