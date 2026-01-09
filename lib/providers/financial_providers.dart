import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/financial_constants.dart';
import '../data/models/financial_items.dart';
import 'project_providers.dart';

/// Repository for CapEx items
class CapExRepository {
  final FirebaseFirestore _firestore;

  CapExRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String projectId) =>
      _firestore.collection('projects').doc(projectId).collection('capex');

  CapExItem _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String projectId) {
    final data = doc.data()!;
    return CapExItem(
      id: doc.id,
      projectId: projectId,
      category: _parseCapExCategory(data['category'] ?? ''),
      description: data['description'] ?? '',
      yearlyAmounts: _parseYearlyAmounts(data['yearlyAmounts']),
      usefulLifeMonths: data['usefulLifeMonths'] ?? 36,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toFirestore(CapExItem item) {
    return {
      'category': item.category.name,
      'description': item.description,
      'yearlyAmounts': item.yearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'usefulLifeMonths': item.usefulLifeMonths,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }

  Stream<List<CapExItem>> watchAll(String projectId) {
    return _collection(projectId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc, projectId)).toList(),
        );
  }

  Future<CapExItem> create(CapExItem item) async {
    final now = DateTime.now();
    final newItem = item.copyWith(createdAt: now, updatedAt: now);
    final docRef = await _collection(item.projectId).add(_toFirestore(newItem));
    return newItem.copyWith(id: docRef.id);
  }

  Future<void> update(CapExItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _collection(item.projectId).doc(item.id).update(_toFirestore(updated));
  }

  Future<void> delete(String projectId, String itemId) async {
    await _collection(projectId).doc(itemId).delete();
  }
}

/// Repository for OpEx items
class OpExRepository {
  final FirebaseFirestore _firestore;

  OpExRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String projectId) =>
      _firestore.collection('projects').doc(projectId).collection('opex');

  OpExItem _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String projectId) {
    final data = doc.data()!;
    return OpExItem(
      id: doc.id,
      projectId: projectId,
      category: _parseOpExCategory(data['category'] ?? ''),
      description: data['description'] ?? '',
      yearlyAmounts: _parseYearlyAmounts(data['yearlyAmounts']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toFirestore(OpExItem item) {
    return {
      'category': item.category.name,
      'description': item.description,
      'yearlyAmounts': item.yearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }

  Stream<List<OpExItem>> watchAll(String projectId) {
    return _collection(projectId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc, projectId)).toList(),
        );
  }

  Future<OpExItem> create(OpExItem item) async {
    final now = DateTime.now();
    final newItem = item.copyWith(createdAt: now, updatedAt: now);
    final docRef = await _collection(item.projectId).add(_toFirestore(newItem));
    return newItem.copyWith(id: docRef.id);
  }

  Future<void> update(OpExItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _collection(item.projectId).doc(item.id).update(_toFirestore(updated));
  }

  Future<void> delete(String projectId, String itemId) async {
    await _collection(projectId).doc(itemId).delete();
  }
}

/// Repository for Benefit items
class BenefitRepository {
  final FirebaseFirestore _firestore;

  BenefitRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _collection(String projectId) =>
      _firestore.collection('projects').doc(projectId).collection('benefits');

  BenefitItem _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String projectId) {
    final data = doc.data()!;
    return BenefitItem(
      id: doc.id,
      projectId: projectId,
      category: _parseBenefitCategory(data['category'] ?? ''),
      businessUnit: _parseBusinessUnit(data['businessUnit'] ?? ''),
      description: data['description'] ?? '',
      yearlyAmounts: _parseYearlyAmounts(data['yearlyAmounts']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toFirestore(BenefitItem item) {
    return {
      'category': item.category.name,
      'businessUnit': item.businessUnit.name,
      'description': item.description,
      'yearlyAmounts': item.yearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }

  Stream<List<BenefitItem>> watchAll(String projectId) {
    return _collection(projectId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc, projectId)).toList(),
        );
  }

  Future<BenefitItem> create(BenefitItem item) async {
    final now = DateTime.now();
    final newItem = item.copyWith(createdAt: now, updatedAt: now);
    final docRef = await _collection(item.projectId).add(_toFirestore(newItem));
    return newItem.copyWith(id: docRef.id);
  }

  Future<void> update(BenefitItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    await _collection(item.projectId).doc(item.id).update(_toFirestore(updated));
  }

  Future<void> delete(String projectId, String itemId) async {
    await _collection(projectId).doc(itemId).delete();
  }
}

// Providers
final capexRepositoryProvider = Provider<CapExRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CapExRepository(firestore);
});

final opexRepositoryProvider = Provider<OpExRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return OpExRepository(firestore);
});

final benefitRepositoryProvider = Provider<BenefitRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return BenefitRepository(firestore);
});

/// Watch all CapEx items for a project
final capexItemsProvider = StreamProvider.family<List<CapExItem>, String>((ref, projectId) {
  final repository = ref.watch(capexRepositoryProvider);
  return repository.watchAll(projectId);
});

/// Watch all OpEx items for a project
final opexItemsProvider = StreamProvider.family<List<OpExItem>, String>((ref, projectId) {
  final repository = ref.watch(opexRepositoryProvider);
  return repository.watchAll(projectId);
});

/// Watch all Benefit items for a project
final benefitItemsProvider = StreamProvider.family<List<BenefitItem>, String>((ref, projectId) {
  final repository = ref.watch(benefitRepositoryProvider);
  return repository.watchAll(projectId);
});

/// Combined project financials provider
final projectFinancialsProvider = Provider.family<AsyncValue<ProjectFinancials>, ({String projectId, int startYear})>((ref, params) {
  final capexAsync = ref.watch(capexItemsProvider(params.projectId));
  final opexAsync = ref.watch(opexItemsProvider(params.projectId));
  final benefitsAsync = ref.watch(benefitItemsProvider(params.projectId));

  return capexAsync.when(
    data: (capexItems) => opexAsync.when(
      data: (opexItems) => benefitsAsync.when(
        data: (benefitItems) => AsyncValue.data(ProjectFinancials(
          capexItems: capexItems,
          opexItems: opexItems,
          benefitItems: benefitItems,
          startYear: params.startYear,
        )),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Helper functions for parsing enums
Map<int, double> _parseYearlyAmounts(dynamic data) {
  if (data == null) return {};
  final map = data as Map<String, dynamic>;
  return map.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
}

CapExCategory _parseCapExCategory(String value) {
  return CapExCategory.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => CapExCategory.other,
  );
}

OpExCategory _parseOpExCategory(String value) {
  return OpExCategory.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => OpExCategory.other,
  );
}

BenefitCategory _parseBenefitCategory(String value) {
  return BenefitCategory.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => BenefitCategory.otherIncome,
  );
}

BusinessUnit _parseBusinessUnit(String value) {
  return BusinessUnit.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => BusinessUnit.corporate,
  );
}
