import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../providers/auth_providers.dart';

/// Defines all available permissions in the system
enum Permission {
  createProjects,
  editOwnProjects,
  viewAllProjects,
  approveProjects,
  viewExecutiveDashboard,
  manageUsers,
  systemConfiguration,
  fullSystemAccess;

  String get displayName {
    switch (this) {
      case Permission.createProjects:
        return 'Create Projects';
      case Permission.editOwnProjects:
        return 'Edit Own Projects';
      case Permission.viewAllProjects:
        return 'View All Projects';
      case Permission.approveProjects:
        return 'Approve Projects';
      case Permission.viewExecutiveDashboard:
        return 'View Executive Dashboard';
      case Permission.manageUsers:
        return 'Manage Users';
      case Permission.systemConfiguration:
        return 'System Configuration';
      case Permission.fullSystemAccess:
        return 'Full System Access';
    }
  }

  String get description {
    switch (this) {
      case Permission.createProjects:
        return 'Can create new project funding requests';
      case Permission.editOwnProjects:
        return 'Can edit projects they created';
      case Permission.viewAllProjects:
        return 'Can view all projects in the system';
      case Permission.approveProjects:
        return 'Can approve or reject project requests';
      case Permission.viewExecutiveDashboard:
        return 'Can access the executive dashboard with metrics';
      case Permission.manageUsers:
        return 'Can manage user accounts and roles';
      case Permission.systemConfiguration:
        return 'Can modify system configuration settings';
      case Permission.fullSystemAccess:
        return 'Unrestricted access to all system features';
    }
  }
}

/// Stores permissions for a specific role
class RolePermissions extends Equatable {
  final UserRole role;
  final Set<Permission> permissions;
  final DateTime? updatedAt;
  final String? updatedBy;

  const RolePermissions({
    required this.role,
    required this.permissions,
    this.updatedAt,
    this.updatedBy,
  });

  /// Check if this role has a specific permission
  bool hasPermission(Permission permission) {
    // Full system access grants all permissions
    if (permissions.contains(Permission.fullSystemAccess)) {
      return true;
    }
    return permissions.contains(permission);
  }

  /// Create from Firestore document
  factory RolePermissions.fromMap(Map<String, dynamic> map, String roleId) {
    final permissionsList = (map['permissions'] as List<dynamic>?)
            ?.map((p) => _parsePermission(p as String))
            .whereType<Permission>()
            .toSet() ??
        {};

    return RolePermissions(
      role: _parseRole(roleId),
      permissions: permissionsList,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      updatedBy: map['updatedBy'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'permissions': permissions.map((p) => p.name).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  /// Get default permissions for a role
  factory RolePermissions.defaults(UserRole role) {
    Set<Permission> defaultPerms;

    switch (role) {
      case UserRole.requester:
        defaultPerms = {
          Permission.createProjects,
          Permission.editOwnProjects,
        };
        break;
      case UserRole.approver:
        defaultPerms = {
          Permission.createProjects,
          Permission.editOwnProjects,
          Permission.viewAllProjects,
          Permission.approveProjects,
        };
        break;
      case UserRole.executive:
        defaultPerms = {
          Permission.viewAllProjects,
          Permission.viewExecutiveDashboard,
        };
        break;
      case UserRole.admin:
        defaultPerms = {
          Permission.createProjects,
          Permission.editOwnProjects,
          Permission.viewAllProjects,
          Permission.approveProjects,
          Permission.viewExecutiveDashboard,
          Permission.manageUsers,
          Permission.systemConfiguration,
        };
        break;
      case UserRole.superUser:
        defaultPerms = Permission.values.toSet();
        break;
    }

    return RolePermissions(role: role, permissions: defaultPerms);
  }

  RolePermissions copyWith({
    UserRole? role,
    Set<Permission>? permissions,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return RolePermissions(
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'superuser':
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

  static Permission? _parsePermission(String permission) {
    try {
      return Permission.values.firstWhere(
        (p) => p.name.toLowerCase() == permission.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [role, permissions, updatedAt, updatedBy];
}
