import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import 'auth_providers.dart';
import 'role_permissions_provider.dart';

/// Repository for user management operations
class UserManagementRepository {
  final FirebaseFirestore _firestore;

  UserManagementRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Watch all users
  Stream<List<AppUser>> watchAllUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get a single user by ID
  Future<AppUser?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  /// Watch a single user by ID (real-time updates)
  Stream<AppUser?> watchUserById(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, doc.id);
    });
  }

  /// Create or update user profile
  Future<void> upsertUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Update user role
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _usersCollection.doc(uid).update({'role': role.name});
  }

  /// Activate/deactivate user
  Future<void> setUserActive(String uid, bool isActive) async {
    await _usersCollection.doc(uid).update({'isActive': isActive});
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, {
    String? displayName,
    String? department,
    String? phoneNumber,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (department != null) updates['department'] = department;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;

    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  /// Delete user (soft delete by deactivating)
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).update({'isActive': false});
  }

  /// Get user count by role
  Future<Map<UserRole, int>> getUserCountsByRole() async {
    final snapshot = await _usersCollection.get();
    final counts = <UserRole, int>{
      UserRole.superUser: 0,
      UserRole.admin: 0,
      UserRole.executive: 0,
      UserRole.approver: 0,
      UserRole.requester: 0,
    };

    for (final doc in snapshot.docs) {
      final user = AppUser.fromMap(doc.data(), doc.id);
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }

    return counts;
  }

  /// Ensure user exists in Firestore (called on login)
  Future<AppUser> ensureUserExists(String uid, String email, String? displayName) async {
    final existingUser = await getUserById(uid);

    if (existingUser != null) {
      // Check if this is a test user that needs role update
      final testRole = _getTestUserRole(email);
      if (testRole != null && existingUser.role != testRole) {
        // Update role for test user
        await updateUserRole(uid, testRole);
        await updateLastLogin(uid);
        return existingUser.copyWith(role: testRole, lastLoginAt: DateTime.now());
      }
      // Update last login
      await updateLastLogin(uid);
      return existingUser.copyWith(lastLoginAt: DateTime.now());
    }

    // Check for pre-registration by email
    final preReg = await getPreRegistration(email);

    // Determine role: test user > pre-registration > default
    UserRole role;
    final testRole = _getTestUserRole(email);
    if (testRole != null) {
      role = testRole;
    } else if (preReg != null) {
      role = _parseRole(preReg['role'] as String?);
    } else {
      role = UserRole.requester;
    }

    // Create new user
    final newUser = AppUser(
      uid: uid,
      email: email,
      displayName: preReg?['displayName'] as String? ?? displayName ?? _getTestUserDisplayName(email),
      department: preReg?['department'] as String?,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await upsertUser(newUser);

    // Delete pre-registration record if it existed
    if (preReg != null) {
      await deletePreRegistration(email);
    }

    return newUser;
  }

  /// Get role for test users based on email
  static UserRole? _getTestUserRole(String email) {
    switch (email.toLowerCase()) {
      case 'exec@example.com':
        return UserRole.executive;
      case 'su@example.com':
        return UserRole.superUser;
      case 'approve@example.com':
        return UserRole.approver;
      case 'req@example.com':
        return UserRole.requester;
      default:
        return null;
    }
  }

  /// Get display name for test users
  static String? _getTestUserDisplayName(String email) {
    switch (email.toLowerCase()) {
      case 'exec@example.com':
        return 'Test Executive';
      case 'su@example.com':
        return 'Test SuperUser';
      case 'approve@example.com':
        return 'Test Approver';
      case 'req@example.com':
        return 'Test Requester';
      default:
        return null;
    }
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
      default:
        return UserRole.requester;
    }
  }

  /// Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    final snapshot = await _usersCollection
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AppUser.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  /// Pre-register a user with email and role
  Future<void> preRegisterUser({
    required String email,
    required UserRole role,
    String? displayName,
    String? department,
  }) async {
    await _firestore.collection('preregistrations').doc(email.toLowerCase()).set({
      'email': email.toLowerCase(),
      'role': role.name,
      'displayName': displayName,
      'department': department,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get pre-registration by email
  Future<Map<String, dynamic>?> getPreRegistration(String email) async {
    final doc = await _firestore
        .collection('preregistrations')
        .doc(email.toLowerCase())
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  /// Delete pre-registration after user signs up
  Future<void> deletePreRegistration(String email) async {
    await _firestore.collection('preregistrations').doc(email.toLowerCase()).delete();
  }
}

/// Provider for user management repository
final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return UserManagementRepository(firestore);
});

/// Stream provider for all users
final allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.watchAllUsers();
});

/// Provider for current user's app profile (streams real-time updates)
final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final firebaseUser = ref.watch(currentUserProvider);
  if (firebaseUser == null) return Stream.value(null);

  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.watchUserById(firebaseUser.uid);
});

/// Provider to check if current user is admin or super user (based on Firestore role)
/// Note: This checks the user's role, not their permissions
final isAppAdminProvider = Provider<bool>((ref) {
  final appUserAsync = ref.watch(currentAppUserProvider);
  return appUserAsync.whenOrNull(
    data: (user) => user?.role == UserRole.admin || user?.role == UserRole.superUser,
  ) ?? false;
});

/// Provider to check if current user can approve projects (uses stored permissions)
final canApproveProvider = Provider<bool>((ref) {
  return ref.watch(canApproveProjectsProvider);
});

/// Provider to check if current user is a super user
final isSuperUserProvider = Provider<bool>((ref) {
  final appUserAsync = ref.watch(currentAppUserProvider);
  return appUserAsync.whenOrNull(
    data: (user) => user?.role == UserRole.superUser,
  ) ?? false;
});

/// Provider to check if current user is an executive
final isExecutiveProvider = Provider<bool>((ref) {
  final appUserAsync = ref.watch(currentAppUserProvider);
  return appUserAsync.whenOrNull(
    data: (user) => user?.role == UserRole.executive,
  ) ?? false;
});

/// Provider to check if current user can view executive dashboard (uses stored permissions)
final canViewExecutiveDashboardProvider = Provider<bool>((ref) {
  return ref.watch(canViewExecutiveDashboardPermProvider);
});

/// Filter state for user list
class UserFilter {
  final String searchQuery;
  final UserRole? roleFilter;
  final bool? activeFilter;

  const UserFilter({
    this.searchQuery = '',
    this.roleFilter,
    this.activeFilter,
  });

  UserFilter copyWith({
    String? searchQuery,
    UserRole? roleFilter,
    bool clearRoleFilter = false,
    bool? activeFilter,
    bool clearActiveFilter = false,
  }) {
    return UserFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      activeFilter: clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }
}

/// Provider for user filter state
final userFilterProvider = StateProvider<UserFilter>((ref) {
  return const UserFilter();
});

/// Filtered users provider
final filteredUsersProvider = Provider<AsyncValue<List<AppUser>>>((ref) {
  final usersAsync = ref.watch(allUsersStreamProvider);
  final filter = ref.watch(userFilterProvider);

  return usersAsync.whenData((users) {
    var filtered = users.where((user) {
      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final matchesEmail = user.email.toLowerCase().contains(query);
        final matchesName = user.displayName?.toLowerCase().contains(query) ?? false;
        if (!matchesEmail && !matchesName) return false;
      }

      // Role filter
      if (filter.roleFilter != null && user.role != filter.roleFilter) {
        return false;
      }

      // Active filter
      if (filter.activeFilter != null && user.isActive != filter.activeFilter) {
        return false;
      }

      return true;
    }).toList();

    return filtered;
  });
});

/// User stats provider
final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final usersAsync = ref.watch(allUsersStreamProvider);

  return usersAsync.when(
    data: (users) {
      final activeCount = users.where((u) => u.isActive).length;
      final superUserCount = users.where((u) => u.role == UserRole.superUser).length;
      final adminCount = users.where((u) => u.role == UserRole.admin).length;
      final executiveCount = users.where((u) => u.role == UserRole.executive).length;
      final approverCount = users.where((u) => u.role == UserRole.approver).length;
      final requesterCount = users.where((u) => u.role == UserRole.requester).length;

      return {
        'total': users.length,
        'active': activeCount,
        'inactive': users.length - activeCount,
        'superUsers': superUserCount,
        'admins': adminCount,
        'executives': executiveCount,
        'approvers': approverCount,
        'requesters': requesterCount,
      };
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
