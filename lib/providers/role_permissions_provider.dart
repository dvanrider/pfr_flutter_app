import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/role_permissions.dart';
import 'auth_providers.dart';

/// Repository for role permissions operations
class RolePermissionsRepository {
  final FirebaseFirestore _firestore;

  RolePermissionsRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('role_permissions');

  /// Get permissions for a specific role
  Future<RolePermissions> getPermissions(UserRole role) async {
    final doc = await _collection.doc(role.name).get();

    if (!doc.exists || doc.data() == null) {
      // Return defaults if not configured
      return RolePermissions.defaults(role);
    }

    return RolePermissions.fromMap(doc.data()!, role.name);
  }

  /// Watch permissions for a specific role
  Stream<RolePermissions> watchPermissions(UserRole role) {
    return _collection.doc(role.name).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return RolePermissions.defaults(role);
      }
      return RolePermissions.fromMap(doc.data()!, role.name);
    });
  }

  /// Get all role permissions
  Future<Map<UserRole, RolePermissions>> getAllPermissions() async {
    final result = <UserRole, RolePermissions>{};

    for (final role in UserRole.values) {
      result[role] = await getPermissions(role);
    }

    return result;
  }

  /// Watch all role permissions
  Stream<Map<UserRole, RolePermissions>> watchAllPermissions() {
    return _collection.snapshots().map((snapshot) {
      final result = <UserRole, RolePermissions>{};

      // Start with defaults for all roles
      for (final role in UserRole.values) {
        result[role] = RolePermissions.defaults(role);
      }

      // Override with stored values
      for (final doc in snapshot.docs) {
        try {
          final rolePerms = RolePermissions.fromMap(doc.data(), doc.id);
          result[rolePerms.role] = rolePerms;
        } catch (_) {
          // Skip invalid documents
        }
      }

      return result;
    });
  }

  /// Save permissions for a role
  Future<void> savePermissions(RolePermissions permissions) async {
    await _collection.doc(permissions.role.name).set(permissions.toMap());
  }

  /// Reset permissions to defaults for a role
  Future<void> resetToDefaults(UserRole role) async {
    final defaults = RolePermissions.defaults(role);
    await savePermissions(defaults);
  }

  /// Initialize all roles with default permissions (if not exists)
  Future<void> initializeDefaults() async {
    for (final role in UserRole.values) {
      final doc = await _collection.doc(role.name).get();
      if (!doc.exists) {
        await savePermissions(RolePermissions.defaults(role));
      }
    }
  }
}

/// Provider for role permissions repository
final rolePermissionsRepositoryProvider =
    Provider<RolePermissionsRepository>((ref) {
  return RolePermissionsRepository(FirebaseFirestore.instance);
});

/// Stream provider for all role permissions
final allRolePermissionsProvider =
    StreamProvider<Map<UserRole, RolePermissions>>((ref) {
  final repository = ref.watch(rolePermissionsRepositoryProvider);
  return repository.watchAllPermissions();
});

/// Provider for a specific role's permissions
final rolePermissionsProvider =
    StreamProvider.family<RolePermissions, UserRole>((ref, role) {
  final repository = ref.watch(rolePermissionsRepositoryProvider);
  return repository.watchPermissions(role);
});

/// Provider to check if current user has a specific permission
final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final userProfileAsync = ref.watch(userProfileProvider);
  final allPermsAsync = ref.watch(allRolePermissionsProvider);

  return userProfileAsync.whenOrNull(
        data: (profile) {
          if (profile == null) return false;

          // Safety net: SuperUser and Admin always have their essential permissions
          // This prevents lockout if Firestore permissions are corrupted
          if (profile.role == UserRole.superUser) {
            return true; // SuperUser always has all permissions
          }
          if (profile.role == UserRole.admin) {
            // Admin always has these critical permissions
            if (permission == Permission.manageUsers ||
                permission == Permission.systemConfiguration ||
                permission == Permission.viewAllProjects) {
              return true;
            }
          }
          if (profile.role == UserRole.executive) {
            // Executive always has these permissions
            if (permission == Permission.viewAllProjects ||
                permission == Permission.viewExecutiveDashboard) {
              return true;
            }
          }

          return allPermsAsync.whenOrNull(
                data: (allPerms) {
                  final rolePerms = allPerms[profile.role];
                  if (rolePerms == null) return false;
                  return rolePerms.hasPermission(permission);
                },
              ) ??
              // Fallback to defaults while loading
              RolePermissions.defaults(profile.role).hasPermission(permission);
        },
      ) ??
      false;
});

/// Provider to get current user's permissions
final currentUserPermissionsProvider = Provider<Set<Permission>>((ref) {
  final userProfileAsync = ref.watch(userProfileProvider);
  final allPermsAsync = ref.watch(allRolePermissionsProvider);

  return userProfileAsync.whenOrNull(
        data: (profile) {
          if (profile == null) return <Permission>{};

          return allPermsAsync.whenOrNull(
                data: (allPerms) {
                  final rolePerms = allPerms[profile.role];
                  if (rolePerms == null) {
                    return RolePermissions.defaults(profile.role).permissions;
                  }
                  return rolePerms.permissions;
                },
              ) ??
              RolePermissions.defaults(profile.role).permissions;
        },
      ) ??
      <Permission>{};
});

/// Provider to check if user can create projects
final canCreateProjectsProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.createProjects));
});

/// Provider to check if user can view all projects
final canViewAllProjectsProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.viewAllProjects));
});

/// Provider to check if user can approve projects
final canApproveProjectsProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.approveProjects));
});

/// Provider to check if user can view executive dashboard
final canViewExecutiveDashboardPermProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.viewExecutiveDashboard));
});

/// Provider to check if user can manage users
final canManageUsersProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.manageUsers));
});

/// Provider to check if user can configure system
final canConfigureSystemProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.systemConfiguration));
});

/// Provider to check if user has full system access
final hasFullAccessProvider = Provider<bool>((ref) {
  return ref.watch(hasPermissionProvider(Permission.fullSystemAccess));
});
