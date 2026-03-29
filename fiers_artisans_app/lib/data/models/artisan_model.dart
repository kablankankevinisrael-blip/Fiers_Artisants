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
    final profile = json['artisan_profile'] ?? json['artisanProfile'] ?? json['profile'] ?? json;
    final user = json['user'] ?? json;

    return ArtisanModel(
      id: profile['id']?.toString() ?? json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      firstName: profile['first_name'] ?? profile['firstName'] ?? user['first_name'] ?? '',
      lastName: profile['last_name'] ?? profile['lastName'] ?? user['last_name'] ?? '',
      phone: user['phone_number'] ?? user['phone'] ?? json['phone_number'] ?? '',
      email: user['email'] ?? json['email'],
      profession: profile['business_name'] ?? profile['profession'] ?? json['business_name'] ?? '',
      description: profile['bio'] ?? profile['description'] ?? json['bio'] ?? json['description'],
      experienceYears:
          profile['years_experience'] ?? profile['experienceYears'] ?? json['years_experience'] ?? 0,
      city: profile['city'] ?? json['city'] ?? '',
      commune: profile['commune'] ?? json['commune'] ?? '',
      latitude: _toDouble(profile['latitude'] ?? json['latitude']),
      longitude: _toDouble(profile['longitude'] ?? json['longitude']),
      averageRating:
          _toDouble(profile['rating_avg'] ?? profile['averageRating'] ?? json['rating_avg']) ?? 0.0,
      totalReviews: profile['total_reviews'] ?? profile['totalReviews'] ?? json['total_reviews'] ?? 0,
      profilePhotoUrl:
          profile['profile_photo_url'] ?? profile['profilePhotoUrl'] ?? json['profilePhotoUrl'],
      isVerified: (user['verification_status'] ?? json['verification_status']) == 'VERIFIED' ||
          (user['verification_status'] ?? json['verification_status']) == 'CERTIFIED' ||
          (profile['isVerified'] ?? json['isVerified'] ?? false) == true,
      isCertified: (user['verification_status'] ?? json['verification_status']) == 'CERTIFIED' ||
          (profile['isCertified'] ?? json['isCertified'] ?? false) == true,
      isAvailable: profile['is_available'] ?? profile['isAvailable'] ?? json['is_available'] ?? true,
      hasActiveSubscription: profile['is_subscription_active'] ??
          profile['hasActiveSubscription'] ??
          json['is_subscription_active'] ??
          false,
      categoryId: profile['category_id']?.toString() ??
          profile['categoryId']?.toString() ??
          json['category_id']?.toString(),
      categoryName: profile['category']?['name'] ?? json['categoryName'],
      distance: _toDouble(json['distance']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
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
