import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../providers/auth_providers.dart';

export '../../providers/auth_providers.dart' show UserRole;

/// Application user with role and profile information
class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? photoUrl;
  final String? department;
  final String? phoneNumber;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = UserRole.requester,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.photoUrl,
    this.department,
    this.phoneNumber,
  });

  /// Create from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      role: _parseRole(map['role'] as String?),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(map['lastLoginAt']),
      photoUrl: map['photoUrl'] as String?,
      department: map['department'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  /// Parse DateTime from various formats (Timestamp, String, or null)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'department': department,
      'phoneNumber': phoneNumber,
    };
  }

  static UserRole _parseRole(String? role) {
    if (role == null) return UserRole.requester;
    switch (role.toLowerCase()) {
      case 'superuser':
      case 'super_user':
        return UserRole.superUser;
      case 'admin':
        return UserRole.admin;
      case 'executive':
        return UserRole.executive;
      case 'approver':
        return UserRole.approver;
      case 'requester':
      default:
        return UserRole.requester;
    }
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? photoUrl,
    String? department,
    String? phoneNumber,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      photoUrl: photoUrl ?? this.photoUrl,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  /// Get initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        role,
        isActive,
        createdAt,
        lastLoginAt,
        photoUrl,
        department,
        phoneNumber,
      ];
}
