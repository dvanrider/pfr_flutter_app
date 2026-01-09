import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream of auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Auth error message
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Auth Repository for authentication operations
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthRepository(auth);
});

/// User role enum
enum UserRole {
  requester,
  approver,
  executive,
  admin,
  superUser;

  String get displayName {
    switch (this) {
      case UserRole.requester:
        return 'Requester';
      case UserRole.approver:
        return 'Approver';
      case UserRole.executive:
        return 'Executive';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superUser:
        return 'Super User';
    }
  }

  String get description {
    switch (this) {
      case UserRole.requester:
        return 'Can create and submit project requests';
      case UserRole.approver:
        return 'Can approve or reject project requests';
      case UserRole.executive:
        return 'View-only access to all metrics and dashboards';
      case UserRole.admin:
        return 'Full access including user management';
      case UserRole.superUser:
        return 'Unrestricted access to all system features';
    }
  }
}

/// User profile model stored in Firestore
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.role = UserRole.requester,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin || role == UserRole.superUser;

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: _parseRole(data['role']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
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
      case 'user':
      default:
        return UserRole.requester;
    }
  }
}

/// User profile repository
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get or create user profile
  Future<UserProfile> getOrCreateProfile(User user) async {
    final doc = await _usersCollection.doc(user.uid).get();

    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }

    // Create new profile
    final profile = UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      role: UserRole.requester,
      createdAt: DateTime.now(),
    );

    await _usersCollection.doc(user.uid).set(profile.toFirestore());
    return profile;
  }

  /// Watch user profile
  Stream<UserProfile?> watchProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  /// Update user role (admin only)
  Future<void> updateRole(String userId, UserRole role) async {
    await _usersCollection.doc(userId).update({'role': role.name});
  }

  /// Get all users (admin only)
  Future<List<UserProfile>> getAllUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }
}

/// User profile repository provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(FirebaseFirestore.instance);
});

/// Current user profile stream provider
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.watchProfile(user.uid);
});

/// Check if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.isAdmin ?? false;
});
