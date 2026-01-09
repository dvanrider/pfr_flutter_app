import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Approval level in the workflow chain
class ApprovalLevel extends Equatable {
  final String id;
  final String name;
  final String role; // e.g., 'manager', 'director', 'vp'
  final int order;
  final double? maxApprovalAmount; // null means unlimited

  const ApprovalLevel({
    required this.id,
    required this.name,
    required this.role,
    required this.order,
    this.maxApprovalAmount,
  });

  factory ApprovalLevel.fromMap(Map<String, dynamic> map) {
    return ApprovalLevel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      maxApprovalAmount: (map['maxApprovalAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'order': order,
      'maxApprovalAmount': maxApprovalAmount,
    };
  }

  ApprovalLevel copyWith({
    String? id,
    String? name,
    String? role,
    int? order,
    double? maxApprovalAmount,
    bool clearMaxAmount = false,
  }) {
    return ApprovalLevel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      order: order ?? this.order,
      maxApprovalAmount: clearMaxAmount ? null : (maxApprovalAmount ?? this.maxApprovalAmount),
    );
  }

  @override
  List<Object?> get props => [id, name, role, order, maxApprovalAmount];
}

/// Dropdown option for configurable lists
class DropdownOption extends Equatable {
  final String value;
  final String label;
  final bool isActive;
  final int sortOrder;

  const DropdownOption({
    required this.value,
    required this.label,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory DropdownOption.fromMap(Map<String, dynamic> map) {
    return DropdownOption(
      value: map['value'] as String? ?? '',
      label: map['label'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'label': label,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  @override
  List<Object?> get props => [value, label, isActive, sortOrder];
}

/// System-wide configuration settings
class SystemConfig extends Equatable {
  // Financial settings
  final double hurdleRate;
  final int projectionYears;
  final double contingencyRate;

  // Approval settings
  final double autoApproveThreshold; // Auto-approve projects under this amount
  final List<ApprovalLevel> approvalChain;

  // Dropdown options
  final List<DropdownOption> segments;
  final List<DropdownOption> businessUnitGroups;
  final List<DropdownOption> businessUnits;
  final List<DropdownOption> icCategories;
  final List<DropdownOption> currencies;

  // Metadata
  final DateTime updatedAt;
  final String? updatedBy;

  const SystemConfig({
    this.hurdleRate = 0.15,
    this.projectionYears = 6,
    this.contingencyRate = 0.10,
    this.autoApproveThreshold = 0,
    this.approvalChain = const [],
    this.segments = const [],
    this.businessUnitGroups = const [],
    this.businessUnits = const [],
    this.icCategories = const [],
    this.currencies = const [],
    required this.updatedAt,
    this.updatedBy,
  });

  /// Default configuration with standard values
  factory SystemConfig.defaults() {
    return SystemConfig(
      hurdleRate: 0.15,
      projectionYears: 6,
      contingencyRate: 0.10,
      autoApproveThreshold: 0,
      approvalChain: const [
        ApprovalLevel(id: '1', name: 'Manager', role: 'manager', order: 1, maxApprovalAmount: 50000),
        ApprovalLevel(id: '2', name: 'Director', role: 'director', order: 2, maxApprovalAmount: 250000),
        ApprovalLevel(id: '3', name: 'VP', role: 'vp', order: 3, maxApprovalAmount: 1000000),
        ApprovalLevel(id: '4', name: 'Executive', role: 'executive', order: 4),
      ],
      segments: const [
        DropdownOption(value: 'retail', label: 'Retail', sortOrder: 1),
        DropdownOption(value: 'commercial', label: 'Commercial', sortOrder: 2),
        DropdownOption(value: 'industrial', label: 'Industrial', sortOrder: 3),
        DropdownOption(value: 'residential', label: 'Residential', sortOrder: 4),
      ],
      businessUnitGroups: const [
        DropdownOption(value: 'north', label: 'North Region', sortOrder: 1),
        DropdownOption(value: 'south', label: 'South Region', sortOrder: 2),
        DropdownOption(value: 'east', label: 'East Region', sortOrder: 3),
        DropdownOption(value: 'west', label: 'West Region', sortOrder: 4),
      ],
      businessUnits: const [
        DropdownOption(value: 'bu-001', label: 'Business Unit 001', sortOrder: 1),
        DropdownOption(value: 'bu-002', label: 'Business Unit 002', sortOrder: 2),
        DropdownOption(value: 'bu-003', label: 'Business Unit 003', sortOrder: 3),
      ],
      icCategories: const [
        DropdownOption(value: 'growth', label: 'Growth', sortOrder: 1),
        DropdownOption(value: 'maintenance', label: 'Maintenance', sortOrder: 2),
        DropdownOption(value: 'compliance', label: 'Compliance', sortOrder: 3),
        DropdownOption(value: 'cost-reduction', label: 'Cost Reduction', sortOrder: 4),
      ],
      currencies: const [
        DropdownOption(value: 'USD', label: 'US Dollar (USD)', sortOrder: 1),
        DropdownOption(value: 'EUR', label: 'Euro (EUR)', sortOrder: 2),
        DropdownOption(value: 'GBP', label: 'British Pound (GBP)', sortOrder: 3),
        DropdownOption(value: 'CAD', label: 'Canadian Dollar (CAD)', sortOrder: 4),
      ],
      updatedAt: DateTime.now(),
    );
  }

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    return SystemConfig(
      hurdleRate: (map['hurdleRate'] as num?)?.toDouble() ?? 0.15,
      projectionYears: map['projectionYears'] as int? ?? 6,
      contingencyRate: (map['contingencyRate'] as num?)?.toDouble() ?? 0.10,
      autoApproveThreshold: (map['autoApproveThreshold'] as num?)?.toDouble() ?? 0,
      approvalChain: (map['approvalChain'] as List<dynamic>?)
          ?.map((e) => ApprovalLevel.fromMap(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      segments: _parseOptions(map['segments']),
      businessUnitGroups: _parseOptions(map['businessUnitGroups']),
      businessUnits: _parseOptions(map['businessUnits']),
      icCategories: _parseOptions(map['icCategories']),
      currencies: _parseOptions(map['currencies']),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  static List<DropdownOption> _parseOptions(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data
        .map((e) => DropdownOption.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'hurdleRate': hurdleRate,
      'projectionYears': projectionYears,
      'contingencyRate': contingencyRate,
      'autoApproveThreshold': autoApproveThreshold,
      'approvalChain': approvalChain.map((e) => e.toMap()).toList(),
      'segments': segments.map((e) => e.toMap()).toList(),
      'businessUnitGroups': businessUnitGroups.map((e) => e.toMap()).toList(),
      'businessUnits': businessUnits.map((e) => e.toMap()).toList(),
      'icCategories': icCategories.map((e) => e.toMap()).toList(),
      'currencies': currencies.map((e) => e.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  SystemConfig copyWith({
    double? hurdleRate,
    int? projectionYears,
    double? contingencyRate,
    double? autoApproveThreshold,
    List<ApprovalLevel>? approvalChain,
    List<DropdownOption>? segments,
    List<DropdownOption>? businessUnitGroups,
    List<DropdownOption>? businessUnits,
    List<DropdownOption>? icCategories,
    List<DropdownOption>? currencies,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SystemConfig(
      hurdleRate: hurdleRate ?? this.hurdleRate,
      projectionYears: projectionYears ?? this.projectionYears,
      contingencyRate: contingencyRate ?? this.contingencyRate,
      autoApproveThreshold: autoApproveThreshold ?? this.autoApproveThreshold,
      approvalChain: approvalChain ?? this.approvalChain,
      segments: segments ?? this.segments,
      businessUnitGroups: businessUnitGroups ?? this.businessUnitGroups,
      businessUnits: businessUnits ?? this.businessUnits,
      icCategories: icCategories ?? this.icCategories,
      currencies: currencies ?? this.currencies,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get active options only for a dropdown
  List<DropdownOption> get activeSegments =>
      segments.where((o) => o.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<DropdownOption> get activeBusinessUnitGroups =>
      businessUnitGroups.where((o) => o.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<DropdownOption> get activeBusinessUnits =>
      businessUnits.where((o) => o.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<DropdownOption> get activeIcCategories =>
      icCategories.where((o) => o.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<DropdownOption> get activeCurrencies =>
      currencies.where((o) => o.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Get the required approval level for a given amount
  ApprovalLevel? getRequiredApprovalLevel(double amount) {
    final sortedChain = List<ApprovalLevel>.from(approvalChain)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final level in sortedChain) {
      if (level.maxApprovalAmount == null || amount <= level.maxApprovalAmount!) {
        return level;
      }
    }
    return sortedChain.isNotEmpty ? sortedChain.last : null;
  }

  /// Check if amount qualifies for auto-approval
  bool canAutoApprove(double amount) {
    return autoApproveThreshold > 0 && amount <= autoApproveThreshold;
  }

  @override
  List<Object?> get props => [
        hurdleRate,
        projectionYears,
        contingencyRate,
        autoApproveThreshold,
        approvalChain,
        segments,
        businessUnitGroups,
        businessUnits,
        icCategories,
        currencies,
        updatedAt,
        updatedBy,
      ];
}
