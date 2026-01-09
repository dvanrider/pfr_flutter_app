import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/financial_constants.dart';
import '../data/models/project.dart';
import 'auth_providers.dart';
import 'role_permissions_provider.dart';

/// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Project filter state
class ProjectFilter {
  final String searchQuery;
  final String? statusFilter;
  final ProjectSortField sortField;
  final bool sortAscending;

  const ProjectFilter({
    this.searchQuery = '',
    this.statusFilter,
    this.sortField = ProjectSortField.date,
    this.sortAscending = false,
  });

  ProjectFilter copyWith({
    String? searchQuery,
    String? statusFilter,
    bool clearStatusFilter = false,
    ProjectSortField? sortField,
    bool? sortAscending,
  }) {
    return ProjectFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

enum ProjectSortField { date, name, cost, npv }

/// Provider for project filter state
final projectFilterProvider = StateProvider<ProjectFilter>((ref) {
  return const ProjectFilter();
});

/// Repository class for project operations using Firestore
class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection('projects');

  /// Convert Firestore document to Project
  Project _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Project(
      id: doc.id,
      userId: data['userId'],
      pfrNumber: data['pfrNumber'] ?? '',
      segment: data['segment'] ?? '',
      businessUnitGroup: data['businessUnitGroup'] ?? '',
      businessUnit: data['businessUnit'] ?? '',
      projectName: data['projectName'] ?? '',
      initiativeSponsor: data['initiativeSponsor'],
      executiveSponsor: data['executiveSponsor'],
      projectRequester: data['projectRequester'],
      icCategory: data['icCategory'],
      physicalAddress: data['physicalAddress'],
      description: data['description'],
      rationale: data['rationale'],
      submissionDate: data['submissionDate'] != null
          ? (data['submissionDate'] as Timestamp).toDate()
          : null,
      projectStartDate: (data['projectStartDate'] as Timestamp).toDate(),
      projectEndDate: (data['projectEndDate'] as Timestamp).toDate(),
      benefitStartDate: data['benefitStartDate'] != null
          ? (data['benefitStartDate'] as Timestamp).toDate()
          : null,
      lobApprovalDate: data['lobApprovalDate'] != null
          ? (data['lobApprovalDate'] as Timestamp).toDate()
          : null,
      nextIcUpdateDate: data['nextIcUpdateDate'] != null
          ? (data['nextIcUpdateDate'] as Timestamp).toDate()
          : null,
      currency: data['currency'] ?? 'USD',
      isCapExBudgeted: data['isCapExBudgeted'] ?? false,
      isOpExBudgeted: data['isOpExBudgeted'] ?? false,
      opExCostCenter: data['opExCostCenter'],
      ongoingOpExCostCenter: data['ongoingOpExCostCenter'],
      replacesCurrentAssets: data['replacesCurrentAssets'] ?? false,
      isHoaReimbursed: data['isHoaReimbursed'] ?? false,
      hoaBillbackCode: data['hoaBillbackCode'],
      hasGuaranteedMarketing: data['hasGuaranteedMarketing'] ?? false,
      guaranteedMarketingDetails: data['guaranteedMarketingDetails'],
      hasLongTermCommitment: data['hasLongTermCommitment'] ?? false,
      hasRealEstateLease: data['hasRealEstateLease'] ?? false,
      hasEquipmentLease: data['hasEquipmentLease'] ?? false,
      hasSupplementalFunding: data['hasSupplementalFunding'] ?? false,
      status: _parseStatus(data['status'] ?? 'draft'),
      statusHistory: _parseStatusHistory(data['statusHistory']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  List<StatusNote> _parseStatusHistory(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data
        .map((item) => StatusNote.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Convert Project to Firestore data
  Map<String, dynamic> _toFirestore(Project project) {
    return {
      'userId': project.userId,
      'pfrNumber': project.pfrNumber,
      'segment': project.segment,
      'businessUnitGroup': project.businessUnitGroup,
      'businessUnit': project.businessUnit,
      'projectName': project.projectName,
      'initiativeSponsor': project.initiativeSponsor,
      'executiveSponsor': project.executiveSponsor,
      'projectRequester': project.projectRequester,
      'icCategory': project.icCategory,
      'physicalAddress': project.physicalAddress,
      'description': project.description,
      'rationale': project.rationale,
      'submissionDate': project.submissionDate != null
          ? Timestamp.fromDate(project.submissionDate!)
          : null,
      'projectStartDate': Timestamp.fromDate(project.projectStartDate),
      'projectEndDate': Timestamp.fromDate(project.projectEndDate),
      'benefitStartDate': project.benefitStartDate != null
          ? Timestamp.fromDate(project.benefitStartDate!)
          : null,
      'lobApprovalDate': project.lobApprovalDate != null
          ? Timestamp.fromDate(project.lobApprovalDate!)
          : null,
      'nextIcUpdateDate': project.nextIcUpdateDate != null
          ? Timestamp.fromDate(project.nextIcUpdateDate!)
          : null,
      'currency': project.currency,
      'isCapExBudgeted': project.isCapExBudgeted,
      'isOpExBudgeted': project.isOpExBudgeted,
      'opExCostCenter': project.opExCostCenter,
      'ongoingOpExCostCenter': project.ongoingOpExCostCenter,
      'replacesCurrentAssets': project.replacesCurrentAssets,
      'isHoaReimbursed': project.isHoaReimbursed,
      'hoaBillbackCode': project.hoaBillbackCode,
      'hasGuaranteedMarketing': project.hasGuaranteedMarketing,
      'guaranteedMarketingDetails': project.guaranteedMarketingDetails,
      'hasLongTermCommitment': project.hasLongTermCommitment,
      'hasRealEstateLease': project.hasRealEstateLease,
      'hasEquipmentLease': project.hasEquipmentLease,
      'hasSupplementalFunding': project.hasSupplementalFunding,
      'status': project.status.name,
      'statusHistory': project.statusHistory.map((n) => n.toMap()).toList(),
      'createdAt': Timestamp.fromDate(project.createdAt),
      'updatedAt': Timestamp.fromDate(project.updatedAt),
    };
  }

  ProjectStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return ProjectStatus.draft;
      case 'submitted':
        return ProjectStatus.submitted;
      case 'pendingapproval':
      case 'pending_approval':
        return ProjectStatus.pendingApproval;
      case 'approved':
        return ProjectStatus.approved;
      case 'rejected':
        return ProjectStatus.rejected;
      case 'onhold':
      case 'on_hold':
        return ProjectStatus.onHold;
      case 'cancelled':
        return ProjectStatus.cancelled;
      default:
        return ProjectStatus.draft;
    }
  }

  /// Watch all projects as a stream
  Stream<List<Project>> watchAllProjects() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromFirestore).toList());
  }

  /// Watch projects for a specific user
  Stream<List<Project>> watchProjectsByUserId(String userId) {
    return _projectsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromFirestore).toList());
  }

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    final snapshot = await _projectsCollection.get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  /// Get a single project by ID
  Future<Project?> getProjectById(String id) async {
    final doc = await _projectsCollection.doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  /// Create a new project
  Future<Project> createProject(Project project) async {
    final now = DateTime.now();
    final newProject = project.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    final docRef = await _projectsCollection.add(_toFirestore(newProject));
    return newProject.copyWith(id: docRef.id);
  }

  /// Update an existing project
  Future<void> updateProject(Project project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    await _projectsCollection.doc(project.id).update(_toFirestore(updated));
  }

  /// Delete a project
  Future<void> deleteProject(String id) async {
    await _projectsCollection.doc(id).delete();
  }
}

/// Provider for the project repository
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ProjectRepository(firestore);
});

/// Provider that watches user's projects from Firestore
/// Users with "View All Projects" permission see all projects, others see only their own
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final canViewAll = ref.watch(canViewAllProjectsProvider);

  // If no user is logged in, return empty list
  if (user == null) {
    return Stream.value([]);
  }

  // Users with permission see all projects
  if (canViewAll) {
    return repository.watchAllProjects();
  }

  // Regular users see only their projects
  return repository.watchProjectsByUserId(user.uid);
});

/// Provider for filtered and sorted projects
final filteredProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final projectsAsync = ref.watch(projectsStreamProvider);
  final filter = ref.watch(projectFilterProvider);

  return projectsAsync.whenData((projects) {
    var filtered = projects.where((p) {
      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final matchesName = p.projectName.toLowerCase().contains(query);
        final matchesPfr = p.pfrNumber.toLowerCase().contains(query);
        if (!matchesName && !matchesPfr) return false;
      }

      // Status filter
      if (filter.statusFilter != null && filter.statusFilter!.isNotEmpty) {
        if (filter.statusFilter != 'All') {
          if (p.status.displayName != filter.statusFilter) return false;
        }
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      final result = switch (filter.sortField) {
        ProjectSortField.name => a.projectName.compareTo(b.projectName),
        ProjectSortField.date => a.createdAt.compareTo(b.createdAt),
        ProjectSortField.cost => a.createdAt.compareTo(b.createdAt),
        ProjectSortField.npv => a.createdAt.compareTo(b.createdAt),
      };
      return filter.sortAscending ? result : -result;
    });

    return filtered;
  });
});

/// Provider to get a single project by ID
final projectByIdProvider = FutureProvider.family<Project?, String>((ref, id) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectById(id);
});

/// Provider for recent projects (last 3)
final recentProjectsProvider = Provider<AsyncValue<List<Project>>>((ref) {
  final projectsAsync = ref.watch(projectsStreamProvider);
  return projectsAsync.whenData((projects) {
    final sorted = List<Project>.from(projects)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(3).toList();
  });
});

/// Provider for project counts by status
final projectCountsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final projectsAsync = ref.watch(projectsStreamProvider);
  return projectsAsync.whenData((projects) {
    final counts = <String, int>{
      'total': projects.length,
      'draft': 0,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
    };

    for (final project in projects) {
      switch (project.status) {
        case ProjectStatus.draft:
          counts['draft'] = (counts['draft'] ?? 0) + 1;
          break;
        case ProjectStatus.pendingApproval:
        case ProjectStatus.submitted:
          counts['pending'] = (counts['pending'] ?? 0) + 1;
          break;
        case ProjectStatus.approved:
          counts['approved'] = (counts['approved'] ?? 0) + 1;
          break;
        case ProjectStatus.rejected:
          counts['rejected'] = (counts['rejected'] ?? 0) + 1;
          break;
        default:
          break;
      }
    }

    return counts;
  });
});
