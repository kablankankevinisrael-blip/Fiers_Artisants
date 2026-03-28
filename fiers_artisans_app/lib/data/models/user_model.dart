class UserModel {
  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String role; // 'artisan' | 'client' | 'admin'
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
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      role: json['role'] ?? 'client',
      email: json['email'],
      isPhoneVerified:
          json['isPhoneVerified'] ?? json['is_phone_verified'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'email': email,
        'isPhoneVerified': isPhoneVerified,
        'isActive': isActive,
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
