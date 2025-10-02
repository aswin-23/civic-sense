import 'dart:convert';

enum UserRole {
  citizen,but
  staff,
  admin,
}

class User {
  final int userId;
  final String firebaseUid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? zone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.userId,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.zone,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      firebaseUid: json['firebase_uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      phone: json['phone'],
      zone: json['zone'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'zone': zone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserRole get userRole {
    switch (role.toLowerCase()) {
      case 'citizen':
        return UserRole.citizen;
      case 'staff':
        return UserRole.staff;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.citizen;
    }
  }

  User copyWith({
    int? userId,
    String? firebaseUid,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? zone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      zone: zone ?? this.zone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Role-based permissions
  bool get canCreateComplaints => userRole == UserRole.citizen;
  bool get canUpdateComplaintStatus => userRole == UserRole.staff || userRole == UserRole.admin;
  bool get canViewAnalytics => userRole == UserRole.admin;
  bool get canManageUsers => userRole == UserRole.admin;
  bool get canManageDepartments => userRole == UserRole.admin;
 
  @override
  String toString() {
    return 'User(userId: $userId, name: $name, email: $email, role: $role)';

  }
  


 bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
