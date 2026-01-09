import 'package:equatable/equatable.dart';
import '../../core/constants/financial_constants.dart';

/// Represents a status change note with timestamp and user info
class StatusNote extends Equatable {
  final ProjectStatus status;
  final String note;
  final DateTime timestamp;
  final String? userId;
  final String? userName;

  const StatusNote({
    required this.status,
    required this.note,
    required this.timestamp,
    this.userId,
    this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userName': userName,
    };
  }

  factory StatusNote.fromMap(Map<String, dynamic> map) {
    return StatusNote(
      status: _parseStatus(map['status'] as String? ?? 'draft'),
      note: map['note'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
    );
  }

  static ProjectStatus _parseStatus(String status) {
    final normalized = status.toLowerCase().replaceAll('_', '');
    for (final s in ProjectStatus.values) {
      if (s.name.toLowerCase() == normalized ||
          s.name.toLowerCase().replaceAll('_', '') == normalized) {
        return s;
      }
    }
    return ProjectStatus.draft;
  }

  @override
  List<Object?> get props => [status, note, timestamp, userId, userName];
}

/// Main Project entity representing a Project Funding Request
class Project extends Equatable {
  final String id;
  final String? userId;
  final String pfrNumber;
  final String segment;
  final String businessUnitGroup;
  final String businessUnit;
  final String projectName;
  final String? initiativeSponsor;
  final String? executiveSponsor;
  final String? projectRequester;
  final String? icCategory;
  final String? physicalAddress;
  final String? description;
  final String? rationale;

  final DateTime? submissionDate;
  final DateTime projectStartDate;
  final DateTime projectEndDate;
  final DateTime? benefitStartDate;
  final DateTime? lobApprovalDate;
  final DateTime? nextIcUpdateDate;

  final String currency;
  final bool isCapExBudgeted;
  final bool isOpExBudgeted;
  final String? opExCostCenter;
  final String? ongoingOpExCostCenter;
  final bool replacesCurrentAssets;
  final bool isHoaReimbursed;
  final String? hoaBillbackCode;
  final bool hasGuaranteedMarketing;
  final String? guaranteedMarketingDetails;
  final bool hasLongTermCommitment;
  final bool hasRealEstateLease;
  final bool hasEquipmentLease;
  final bool hasSupplementalFunding;

  final ProjectStatus status;
  final List<StatusNote> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    this.userId,
    required this.pfrNumber,
    required this.segment,
    required this.businessUnitGroup,
    required this.businessUnit,
    required this.projectName,
    this.initiativeSponsor,
    this.executiveSponsor,
    this.projectRequester,
    this.icCategory,
    this.physicalAddress,
    this.description,
    this.rationale,
    this.submissionDate,
    required this.projectStartDate,
    required this.projectEndDate,
    this.benefitStartDate,
    this.lobApprovalDate,
    this.nextIcUpdateDate,
    this.currency = 'USD',
    this.isCapExBudgeted = false,
    this.isOpExBudgeted = false,
    this.opExCostCenter,
    this.ongoingOpExCostCenter,
    this.replacesCurrentAssets = false,
    this.isHoaReimbursed = false,
    this.hoaBillbackCode,
    this.hasGuaranteedMarketing = false,
    this.guaranteedMarketingDetails,
    this.hasLongTermCommitment = false,
    this.hasRealEstateLease = false,
    this.hasEquipmentLease = false,
    this.hasSupplementalFunding = false,
    this.status = ProjectStatus.draft,
    this.statusHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the start year for projections
  int get startYear => projectStartDate.year;

  /// Returns the end year for projections
  int get endYear => projectEndDate.year;

  /// Copy with pattern for immutability
  Project copyWith({
    String? id,
    String? userId,
    String? pfrNumber,
    String? segment,
    String? businessUnitGroup,
    String? businessUnit,
    String? projectName,
    String? initiativeSponsor,
    String? executiveSponsor,
    String? projectRequester,
    String? icCategory,
    String? physicalAddress,
    String? description,
    String? rationale,
    DateTime? submissionDate,
    DateTime? projectStartDate,
    DateTime? projectEndDate,
    DateTime? benefitStartDate,
    DateTime? lobApprovalDate,
    DateTime? nextIcUpdateDate,
    String? currency,
    bool? isCapExBudgeted,
    bool? isOpExBudgeted,
    String? opExCostCenter,
    String? ongoingOpExCostCenter,
    bool? replacesCurrentAssets,
    bool? isHoaReimbursed,
    String? hoaBillbackCode,
    bool? hasGuaranteedMarketing,
    String? guaranteedMarketingDetails,
    bool? hasLongTermCommitment,
    bool? hasRealEstateLease,
    bool? hasEquipmentLease,
    bool? hasSupplementalFunding,
    ProjectStatus? status,
    List<StatusNote>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pfrNumber: pfrNumber ?? this.pfrNumber,
      segment: segment ?? this.segment,
      businessUnitGroup: businessUnitGroup ?? this.businessUnitGroup,
      businessUnit: businessUnit ?? this.businessUnit,
      projectName: projectName ?? this.projectName,
      initiativeSponsor: initiativeSponsor ?? this.initiativeSponsor,
      executiveSponsor: executiveSponsor ?? this.executiveSponsor,
      projectRequester: projectRequester ?? this.projectRequester,
      icCategory: icCategory ?? this.icCategory,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      description: description ?? this.description,
      rationale: rationale ?? this.rationale,
      submissionDate: submissionDate ?? this.submissionDate,
      projectStartDate: projectStartDate ?? this.projectStartDate,
      projectEndDate: projectEndDate ?? this.projectEndDate,
      benefitStartDate: benefitStartDate ?? this.benefitStartDate,
      lobApprovalDate: lobApprovalDate ?? this.lobApprovalDate,
      nextIcUpdateDate: nextIcUpdateDate ?? this.nextIcUpdateDate,
      currency: currency ?? this.currency,
      isCapExBudgeted: isCapExBudgeted ?? this.isCapExBudgeted,
      isOpExBudgeted: isOpExBudgeted ?? this.isOpExBudgeted,
      opExCostCenter: opExCostCenter ?? this.opExCostCenter,
      ongoingOpExCostCenter: ongoingOpExCostCenter ?? this.ongoingOpExCostCenter,
      replacesCurrentAssets: replacesCurrentAssets ?? this.replacesCurrentAssets,
      isHoaReimbursed: isHoaReimbursed ?? this.isHoaReimbursed,
      hoaBillbackCode: hoaBillbackCode ?? this.hoaBillbackCode,
      hasGuaranteedMarketing: hasGuaranteedMarketing ?? this.hasGuaranteedMarketing,
      guaranteedMarketingDetails: guaranteedMarketingDetails ?? this.guaranteedMarketingDetails,
      hasLongTermCommitment: hasLongTermCommitment ?? this.hasLongTermCommitment,
      hasRealEstateLease: hasRealEstateLease ?? this.hasRealEstateLease,
      hasEquipmentLease: hasEquipmentLease ?? this.hasEquipmentLease,
      hasSupplementalFunding: hasSupplementalFunding ?? this.hasSupplementalFunding,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pfrNumber,
        segment,
        businessUnitGroup,
        businessUnit,
        projectName,
        initiativeSponsor,
        executiveSponsor,
        projectRequester,
        icCategory,
        physicalAddress,
        description,
        rationale,
        submissionDate,
        projectStartDate,
        projectEndDate,
        benefitStartDate,
        lobApprovalDate,
        nextIcUpdateDate,
        currency,
        isCapExBudgeted,
        isOpExBudgeted,
        opExCostCenter,
        ongoingOpExCostCenter,
        replacesCurrentAssets,
        isHoaReimbursed,
        hoaBillbackCode,
        hasGuaranteedMarketing,
        guaranteedMarketingDetails,
        hasLongTermCommitment,
        hasRealEstateLease,
        hasEquipmentLease,
        hasSupplementalFunding,
        status,
        statusHistory,
        createdAt,
        updatedAt,
      ];
}
