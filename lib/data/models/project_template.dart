import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Categories for project templates
enum TemplateCategory {
  itInfrastructure('IT Infrastructure'),
  realEstate('Real Estate'),
  marketing('Marketing'),
  operations('Operations'),
  technology('Technology'),
  other('Other');

  final String displayName;
  const TemplateCategory(this.displayName);
}

/// Template for pre-populating financial items
class TemplateFinancialItem extends Equatable {
  final String category; // CapExCategory, OpExCategory, or BenefitCategory name
  final String description;
  final double? defaultAmount;
  final String? notes;

  const TemplateFinancialItem({
    required this.category,
    required this.description,
    this.defaultAmount,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'defaultAmount': defaultAmount,
      'notes': notes,
    };
  }

  factory TemplateFinancialItem.fromMap(Map<String, dynamic> map) {
    return TemplateFinancialItem(
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      defaultAmount: (map['defaultAmount'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [category, description, defaultAmount, notes];
}

/// A project template for quickly creating new projects
class ProjectTemplate extends Equatable {
  final String id;
  final String name;
  final String? description;
  final TemplateCategory category;
  final bool isActive;
  final bool isSystemTemplate; // System templates can't be deleted by users

  // Pre-filled project fields
  final String? segment;
  final String? businessUnitGroup;
  final String? businessUnit;
  final String? icCategory;
  final String? descriptionTemplate;
  final String? rationaleTemplate;
  final String currency;

  // Default project duration in months
  final int defaultDurationMonths;

  // Boolean flags
  final bool isCapExBudgeted;
  final bool isOpExBudgeted;
  final bool replacesCurrentAssets;
  final bool isHoaReimbursed;
  final bool hasGuaranteedMarketing;
  final bool hasLongTermCommitment;
  final bool hasRealEstateLease;
  final bool hasEquipmentLease;

  // Template financial items
  final List<TemplateFinancialItem> defaultCapExItems;
  final List<TemplateFinancialItem> defaultOpExItems;
  final List<TemplateFinancialItem> defaultBenefitItems;

  // Metadata
  final String? createdByUserId;
  final String? createdByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectTemplate({
    required this.id,
    required this.name,
    this.description,
    this.category = TemplateCategory.other,
    this.isActive = true,
    this.isSystemTemplate = false,
    this.segment,
    this.businessUnitGroup,
    this.businessUnit,
    this.icCategory,
    this.descriptionTemplate,
    this.rationaleTemplate,
    this.currency = 'USD',
    this.defaultDurationMonths = 12,
    this.isCapExBudgeted = false,
    this.isOpExBudgeted = false,
    this.replacesCurrentAssets = false,
    this.isHoaReimbursed = false,
    this.hasGuaranteedMarketing = false,
    this.hasLongTermCommitment = false,
    this.hasRealEstateLease = false,
    this.hasEquipmentLease = false,
    this.defaultCapExItems = const [],
    this.defaultOpExItems = const [],
    this.defaultBenefitItems = const [],
    this.createdByUserId,
    this.createdByUserName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectTemplate.fromMap(Map<String, dynamic> map, String id) {
    return ProjectTemplate(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Template',
      description: map['description'] as String?,
      category: _parseCategory(map['category'] as String?),
      isActive: map['isActive'] as bool? ?? true,
      isSystemTemplate: map['isSystemTemplate'] as bool? ?? false,
      segment: map['segment'] as String?,
      businessUnitGroup: map['businessUnitGroup'] as String?,
      businessUnit: map['businessUnit'] as String?,
      icCategory: map['icCategory'] as String?,
      descriptionTemplate: map['descriptionTemplate'] as String?,
      rationaleTemplate: map['rationaleTemplate'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      defaultDurationMonths: map['defaultDurationMonths'] as int? ?? 12,
      isCapExBudgeted: map['isCapExBudgeted'] as bool? ?? false,
      isOpExBudgeted: map['isOpExBudgeted'] as bool? ?? false,
      replacesCurrentAssets: map['replacesCurrentAssets'] as bool? ?? false,
      isHoaReimbursed: map['isHoaReimbursed'] as bool? ?? false,
      hasGuaranteedMarketing: map['hasGuaranteedMarketing'] as bool? ?? false,
      hasLongTermCommitment: map['hasLongTermCommitment'] as bool? ?? false,
      hasRealEstateLease: map['hasRealEstateLease'] as bool? ?? false,
      hasEquipmentLease: map['hasEquipmentLease'] as bool? ?? false,
      defaultCapExItems: _parseFinancialItems(map['defaultCapExItems']),
      defaultOpExItems: _parseFinancialItems(map['defaultOpExItems']),
      defaultBenefitItems: _parseFinancialItems(map['defaultBenefitItems']),
      createdByUserId: map['createdByUserId'] as String?,
      createdByUserName: map['createdByUserName'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.name,
      'isActive': isActive,
      'isSystemTemplate': isSystemTemplate,
      'segment': segment,
      'businessUnitGroup': businessUnitGroup,
      'businessUnit': businessUnit,
      'icCategory': icCategory,
      'descriptionTemplate': descriptionTemplate,
      'rationaleTemplate': rationaleTemplate,
      'currency': currency,
      'defaultDurationMonths': defaultDurationMonths,
      'isCapExBudgeted': isCapExBudgeted,
      'isOpExBudgeted': isOpExBudgeted,
      'replacesCurrentAssets': replacesCurrentAssets,
      'isHoaReimbursed': isHoaReimbursed,
      'hasGuaranteedMarketing': hasGuaranteedMarketing,
      'hasLongTermCommitment': hasLongTermCommitment,
      'hasRealEstateLease': hasRealEstateLease,
      'hasEquipmentLease': hasEquipmentLease,
      'defaultCapExItems': defaultCapExItems.map((e) => e.toMap()).toList(),
      'defaultOpExItems': defaultOpExItems.map((e) => e.toMap()).toList(),
      'defaultBenefitItems': defaultBenefitItems.map((e) => e.toMap()).toList(),
      'createdByUserId': createdByUserId,
      'createdByUserName': createdByUserName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProjectTemplate copyWith({
    String? id,
    String? name,
    String? description,
    TemplateCategory? category,
    bool? isActive,
    bool? isSystemTemplate,
    String? segment,
    String? businessUnitGroup,
    String? businessUnit,
    String? icCategory,
    String? descriptionTemplate,
    String? rationaleTemplate,
    String? currency,
    int? defaultDurationMonths,
    bool? isCapExBudgeted,
    bool? isOpExBudgeted,
    bool? replacesCurrentAssets,
    bool? isHoaReimbursed,
    bool? hasGuaranteedMarketing,
    bool? hasLongTermCommitment,
    bool? hasRealEstateLease,
    bool? hasEquipmentLease,
    List<TemplateFinancialItem>? defaultCapExItems,
    List<TemplateFinancialItem>? defaultOpExItems,
    List<TemplateFinancialItem>? defaultBenefitItems,
    String? createdByUserId,
    String? createdByUserName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      segment: segment ?? this.segment,
      businessUnitGroup: businessUnitGroup ?? this.businessUnitGroup,
      businessUnit: businessUnit ?? this.businessUnit,
      icCategory: icCategory ?? this.icCategory,
      descriptionTemplate: descriptionTemplate ?? this.descriptionTemplate,
      rationaleTemplate: rationaleTemplate ?? this.rationaleTemplate,
      currency: currency ?? this.currency,
      defaultDurationMonths: defaultDurationMonths ?? this.defaultDurationMonths,
      isCapExBudgeted: isCapExBudgeted ?? this.isCapExBudgeted,
      isOpExBudgeted: isOpExBudgeted ?? this.isOpExBudgeted,
      replacesCurrentAssets: replacesCurrentAssets ?? this.replacesCurrentAssets,
      isHoaReimbursed: isHoaReimbursed ?? this.isHoaReimbursed,
      hasGuaranteedMarketing: hasGuaranteedMarketing ?? this.hasGuaranteedMarketing,
      hasLongTermCommitment: hasLongTermCommitment ?? this.hasLongTermCommitment,
      hasRealEstateLease: hasRealEstateLease ?? this.hasRealEstateLease,
      hasEquipmentLease: hasEquipmentLease ?? this.hasEquipmentLease,
      defaultCapExItems: defaultCapExItems ?? this.defaultCapExItems,
      defaultOpExItems: defaultOpExItems ?? this.defaultOpExItems,
      defaultBenefitItems: defaultBenefitItems ?? this.defaultBenefitItems,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByUserName: createdByUserName ?? this.createdByUserName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TemplateCategory _parseCategory(String? category) {
    if (category == null) return TemplateCategory.other;
    try {
      return TemplateCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == category.toLowerCase(),
      );
    } catch (_) {
      return TemplateCategory.other;
    }
  }

  static List<TemplateFinancialItem> _parseFinancialItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) return [];
    return items
        .map((e) => TemplateFinancialItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        isActive,
        isSystemTemplate,
        segment,
        businessUnitGroup,
        businessUnit,
        icCategory,
        descriptionTemplate,
        rationaleTemplate,
        currency,
        defaultDurationMonths,
        isCapExBudgeted,
        isOpExBudgeted,
        replacesCurrentAssets,
        isHoaReimbursed,
        hasGuaranteedMarketing,
        hasLongTermCommitment,
        hasRealEstateLease,
        hasEquipmentLease,
        defaultCapExItems,
        defaultOpExItems,
        defaultBenefitItems,
        createdByUserId,
        createdByUserName,
        createdAt,
        updatedAt,
      ];
}
