class UserModel {
  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;
  final String? email;
  final bool isPhoneVerified;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.email,
    this.isPhoneVerified = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      phone: json['phone_number'] ?? json['phone'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      role: (json['role'] ?? 'CLIENT').toString().toLowerCase(),
      email: json['email'],
      isPhoneVerified:
          json['is_phone_verified'] ?? json['isPhoneVerified'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phone,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'email': email,
        'is_phone_verified': isPhoneVerified,
        'is_active': isActive,
      };

  String get fullName => '$firstName $lastName';

  UserModel copyWith({
    String? phone,
    String? firstName,
    String? lastName,
    String? email,
    bool? isPhoneVerified,
  }) {
    return UserModel(
      id: id,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role,
      email: email ?? this.email,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
