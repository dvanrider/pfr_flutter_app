import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/system_config.dart';

/// Repository for system configuration
class SystemConfigRepository {
  final FirebaseFirestore _firestore;
  static const String _configDocId = 'app_settings';

  SystemConfigRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _firestore.collection('config').doc(_configDocId);

  /// Watch system configuration (real-time updates)
  Stream<SystemConfig> watchConfig() {
    return _configDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return SystemConfig.defaults();
      }
      return SystemConfig.fromMap(doc.data()!);
    });
  }

  /// Get current configuration
  Future<SystemConfig> getConfig() async {
    final doc = await _configDoc.get();
    if (!doc.exists || doc.data() == null) {
      return SystemConfig.defaults();
    }
    return SystemConfig.fromMap(doc.data()!);
  }

  /// Save configuration
  Future<void> saveConfig(SystemConfig config, String userId) async {
    final updated = config.copyWith(
      updatedAt: DateTime.now(),
      updatedBy: userId,
    );
    await _configDoc.set(updated.toMap());
  }

  /// Update hurdle rate
  Future<void> updateHurdleRate(double rate, String userId) async {
    await _configDoc.set({
      'hurdleRate': rate,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  /// Update projection years
  Future<void> updateProjectionYears(int years, String userId) async {
    await _configDoc.set({
      'projectionYears': years,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  /// Update auto-approve threshold
  Future<void> updateAutoApproveThreshold(double threshold, String userId) async {
    await _configDoc.set({
      'autoApproveThreshold': threshold,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  /// Update approval chain
  Future<void> updateApprovalChain(List<ApprovalLevel> chain, String userId) async {
    await _configDoc.set({
      'approvalChain': chain.map((e) => e.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  /// Update dropdown options
  Future<void> updateDropdownOptions({
    required String field,
    required List<DropdownOption> options,
    required String userId,
  }) async {
    await _configDoc.set({
      field: options.map((e) => e.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  /// Initialize config with defaults if not exists
  Future<void> initializeIfNeeded() async {
    final doc = await _configDoc.get();
    if (!doc.exists) {
      await _configDoc.set(SystemConfig.defaults().toMap());
    }
  }
}

/// Provider for system config repository
final systemConfigRepositoryProvider = Provider<SystemConfigRepository>((ref) {
  return SystemConfigRepository(FirebaseFirestore.instance);
});

/// Stream provider for system configuration
final systemConfigProvider = StreamProvider<SystemConfig>((ref) {
  final repository = ref.watch(systemConfigRepositoryProvider);
  return repository.watchConfig();
});

/// Provider for hurdle rate (convenience accessor)
final hurdleRateProvider = Provider<double>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.hurdleRate) ?? 0.15;
});

/// Provider for projection years (convenience accessor)
final projectionYearsProvider = Provider<int>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.projectionYears) ?? 6;
});

/// Provider for contingency rate (convenience accessor)
final contingencyRateProvider = Provider<double>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.contingencyRate) ?? 0.10;
});

/// Provider for auto-approve threshold
final autoApproveThresholdProvider = Provider<double>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.autoApproveThreshold) ?? 0;
});

/// Provider for approval chain
final approvalChainProvider = Provider<List<ApprovalLevel>>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.approvalChain) ?? [];
});

/// Provider for active segments dropdown
final segmentsDropdownProvider = Provider<List<DropdownOption>>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.activeSegments) ?? [];
});

/// Provider for active business unit groups dropdown
final businessUnitGroupsDropdownProvider = Provider<List<DropdownOption>>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.activeBusinessUnitGroups) ?? [];
});

/// Provider for active business units dropdown
final businessUnitsDropdownProvider = Provider<List<DropdownOption>>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.activeBusinessUnits) ?? [];
});

/// Provider for active IC categories dropdown
final icCategoriesDropdownProvider = Provider<List<DropdownOption>>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.activeIcCategories) ?? [];
});

/// Provider for active currencies dropdown
final currenciesDropdownProvider = Provider<List<DropdownOption>>((ref) {
  final config = ref.watch(systemConfigProvider);
  return config.whenOrNull(data: (c) => c.activeCurrencies) ?? [];
});
