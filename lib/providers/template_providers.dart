import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/project_template.dart';

/// Repository for project template operations
class TemplateRepository {
  final FirebaseFirestore _firestore;

  TemplateRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('project_templates');

  /// Watch all active templates
  Stream<List<ProjectTemplate>> watchAllTemplates() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectTemplate.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Watch all templates (including inactive) for admin
  Stream<List<ProjectTemplate>> watchAllTemplatesAdmin() {
    return _collection.orderBy('name').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => ProjectTemplate.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Watch templates by category
  Stream<List<ProjectTemplate>> watchTemplatesByCategory(TemplateCategory category) {
    return _collection
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.name)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectTemplate.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get a single template by ID
  Future<ProjectTemplate?> getTemplate(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ProjectTemplate.fromMap(doc.data()!, doc.id);
  }

  /// Create a new template
  Future<ProjectTemplate> createTemplate(ProjectTemplate template) async {
    final docRef = _collection.doc();
    final newTemplate = template.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newTemplate.toMap());
    return newTemplate;
  }

  /// Update an existing template
  Future<void> updateTemplate(ProjectTemplate template) async {
    final updatedTemplate = template.copyWith(updatedAt: DateTime.now());
    await _collection.doc(template.id).update(updatedTemplate.toMap());
  }

  /// Delete a template (soft delete by setting isActive to false)
  Future<void> deleteTemplate(String templateId) async {
    await _collection.doc(templateId).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Permanently delete a template (admin only)
  Future<void> permanentlyDeleteTemplate(String templateId) async {
    await _collection.doc(templateId).delete();
  }

  /// Duplicate a template
  Future<ProjectTemplate> duplicateTemplate(
    ProjectTemplate source, {
    required String newName,
    String? createdByUserId,
    String? createdByUserName,
  }) async {
    final docRef = _collection.doc();
    final newTemplate = source.copyWith(
      id: docRef.id,
      name: newName,
      isSystemTemplate: false, // Duplicates are never system templates
      createdByUserId: createdByUserId,
      createdByUserName: createdByUserName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newTemplate.toMap());
    return newTemplate;
  }

  /// Create system default templates (called during initial setup)
  Future<void> createDefaultTemplates() async {
    // Check if any system templates exist
    final existing = await _collection
        .where('isSystemTemplate', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // Already initialized

    final defaultTemplates = [
      ProjectTemplate(
        id: '',
        name: 'IT Infrastructure',
        description: 'Standard IT infrastructure project with hardware and software components',
        category: TemplateCategory.itInfrastructure,
        isSystemTemplate: true,
        icCategory: 'Technology',
        descriptionTemplate: 'This project involves the implementation of IT infrastructure to support business operations.',
        rationaleTemplate: 'The investment is required to maintain competitive operations and ensure system reliability.',
        isCapExBudgeted: true,
        defaultDurationMonths: 12,
        defaultCapExItems: const [
          TemplateFinancialItem(
            category: 'hardware',
            description: 'Server Hardware',
          ),
          TemplateFinancialItem(
            category: 'software',
            description: 'Software Licenses',
          ),
          TemplateFinancialItem(
            category: 'externalLabor',
            description: 'Implementation Services',
          ),
        ],
        defaultOpExItems: const [
          TemplateFinancialItem(
            category: 'maintenanceFees',
            description: 'Annual Maintenance',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectTemplate(
        id: '',
        name: 'Real Estate Lease',
        description: 'Standard real estate lease project',
        category: TemplateCategory.realEstate,
        isSystemTemplate: true,
        icCategory: 'Real Estate',
        descriptionTemplate: 'This project involves entering into a real estate lease agreement.',
        rationaleTemplate: 'The lease is required to support business expansion and operational needs.',
        hasRealEstateLease: true,
        hasLongTermCommitment: true,
        defaultDurationMonths: 60,
        defaultOpExItems: const [
          TemplateFinancialItem(
            category: 'rentCre',
            description: 'Monthly Rent',
          ),
          TemplateFinancialItem(
            category: 'operatingCostsCre',
            description: 'Operating Costs (CAM)',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectTemplate(
        id: '',
        name: 'Marketing Campaign',
        description: 'Standard marketing campaign with guaranteed spend',
        category: TemplateCategory.marketing,
        isSystemTemplate: true,
        icCategory: 'Marketing',
        descriptionTemplate: 'This marketing campaign is designed to increase brand awareness and drive revenue.',
        rationaleTemplate: 'Marketing investment is projected to generate positive ROI through increased sales.',
        hasGuaranteedMarketing: true,
        isOpExBudgeted: true,
        defaultDurationMonths: 12,
        defaultOpExItems: const [
          TemplateFinancialItem(
            category: 'externalLabor',
            description: 'Agency Fees',
          ),
          TemplateFinancialItem(
            category: 'other',
            description: 'Media Spend',
          ),
        ],
        defaultBenefitItems: const [
          TemplateFinancialItem(
            category: 'netRevenue',
            description: 'Projected Revenue Increase',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectTemplate(
        id: '',
        name: 'Equipment Purchase',
        description: 'Standard equipment acquisition project',
        category: TemplateCategory.operations,
        isSystemTemplate: true,
        icCategory: 'Operations',
        descriptionTemplate: 'This project involves the purchase of equipment to support operations.',
        rationaleTemplate: 'Equipment acquisition will improve operational efficiency and reduce costs.',
        isCapExBudgeted: true,
        hasEquipmentLease: false,
        defaultDurationMonths: 6,
        defaultCapExItems: const [
          TemplateFinancialItem(
            category: 'computerEquipment',
            description: 'Equipment Purchase',
          ),
          TemplateFinancialItem(
            category: 'externalLabor',
            description: 'Installation Services',
          ),
        ],
        defaultOpExItems: const [
          TemplateFinancialItem(
            category: 'maintenanceFees',
            description: 'Equipment Maintenance',
          ),
        ],
        defaultBenefitItems: const [
          TemplateFinancialItem(
            category: 'expenseReductions',
            description: 'Operational Efficiency Savings',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProjectTemplate(
        id: '',
        name: 'Blank Template',
        description: 'Start from scratch with no pre-filled values',
        category: TemplateCategory.other,
        isSystemTemplate: true,
        defaultDurationMonths: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Create all templates
    for (final template in defaultTemplates) {
      await createTemplate(template);
    }
  }
}

/// Provider for template repository
final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(FirebaseFirestore.instance);
});

/// Stream provider for all active templates
final allTemplatesProvider = StreamProvider<List<ProjectTemplate>>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return repository.watchAllTemplates();
});

/// Stream provider for all templates (admin view)
final allTemplatesAdminProvider = StreamProvider<List<ProjectTemplate>>((ref) {
  final repository = ref.watch(templateRepositoryProvider);
  return repository.watchAllTemplatesAdmin();
});

/// Stream provider for templates by category
final templatesByCategoryProvider =
    StreamProvider.family<List<ProjectTemplate>, TemplateCategory>((ref, category) {
  final repository = ref.watch(templateRepositoryProvider);
  return repository.watchTemplatesByCategory(category);
});

/// Future provider for a single template
final templateByIdProvider =
    FutureProvider.family<ProjectTemplate?, String>((ref, templateId) {
  final repository = ref.watch(templateRepositoryProvider);
  return repository.getTemplate(templateId);
});

/// Provider to initialize default templates
final initializeDefaultTemplatesProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(templateRepositoryProvider);
  await repository.createDefaultTemplates();
});
