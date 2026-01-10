import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/financial_constants.dart';
import '../data/models/project.dart';
import '../data/models/financial_items.dart';

class SeedDataService {
  final FirebaseFirestore _firestore;

  SeedDataService(this._firestore);

  Future<void> seedSampleData() async {
    // Check if data already exists
    final existing = await _firestore.collection('projects').limit(1).get();
    if (existing.docs.isNotEmpty) {
      return; // Data already exists
    }

    await _seedProjects();
  }

  /// Force seed sample data even if data already exists
  /// Seeds projects for the current logged-in user
  Future<void> forceSeedSampleData() async {
    await _seedProjects();
  }

  /// Delete all seed data (all projects and their financial data for the current user)
  Future<int> cleanupSeedData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;

    // Get all projects for the current user
    final projectsQuery = await _firestore
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .get();

    int deletedCount = 0;

    for (final projectDoc in projectsQuery.docs) {
      // Delete subcollections first (capex, opex, benefits)
      await _deleteSubcollection(projectDoc.reference, 'capex');
      await _deleteSubcollection(projectDoc.reference, 'opex');
      await _deleteSubcollection(projectDoc.reference, 'benefits');

      // Delete the project document
      await projectDoc.reference.delete();
      deletedCount++;
    }

    return deletedCount;
  }

  /// Helper to delete all documents in a subcollection
  Future<void> _deleteSubcollection(DocumentReference parentDoc, String subcollectionName) async {
    final subcollection = await parentDoc.collection(subcollectionName).get();
    for (final doc in subcollection.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _seedProjects() async {
    // Get current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Create sample projects
    final projectsData = [
      _createProject1(),
      _createProject2(),
      _createProject3(),
      _createProject4(),
      _createProject5(),
    ];

    // Use a batch for each project to ensure all data is written together
    for (int i = 0; i < projectsData.length; i++) {
      try {
        final projectData = projectsData[i];
        final project = projectData['project'] as Project;
        final capex = projectData['capex'] as List<CapExItem>;
        final opex = projectData['opex'] as List<OpExItem>;
        final benefits = projectData['benefits'] as List<BenefitItem>;

        // Create the project document
        final projectRef = _firestore.collection('projects').doc();

        // Use batch write for this project and its financial data
        final batch = _firestore.batch();

        // Add project
        batch.set(projectRef, _projectToFirestore(project, userId));

        // Add CapEx items
        for (final item in capex) {
          final capexRef = projectRef.collection('capex').doc();
          batch.set(capexRef, _capexToFirestore(item));
        }

        // Add OpEx items
        for (final item in opex) {
          final opexRef = projectRef.collection('opex').doc();
          batch.set(opexRef, _opexToFirestore(item));
        }

        // Add Benefit items
        for (final item in benefits) {
          final benefitRef = projectRef.collection('benefits').doc();
          batch.set(benefitRef, _benefitToFirestore(item));
        }

        // Commit the batch
        await batch.commit();

      } catch (e) {
        rethrow;
      }
    }
  }

  Map<String, dynamic> _createProject1() {
    final now = DateTime.now();
    final startYear = now.year;

    final project = Project(
      id: '',
      pfrNumber: 'PFR-2026-001',
      segment: 'Technology',
      businessUnitGroup: 'Technology',
      businessUnit: 'Software Development',
      projectName: 'Cloud Migration Initiative',
      initiativeSponsor: 'John Smith',
      executiveSponsor: 'Sarah Johnson',
      projectRequester: 'Mike Williams',
      icCategory: 'Strategic',
      description: 'Migrate legacy on-premise infrastructure to cloud-based solutions to improve scalability, reduce operational costs, and enhance disaster recovery capabilities.',
      rationale: 'Current infrastructure is reaching end-of-life with increasing maintenance costs. Cloud migration will reduce TCO by 35% over 5 years while improving system availability to 99.9%.',
      projectStartDate: DateTime(startYear, 1, 1),
      projectEndDate: DateTime(startYear + 2, 12, 31),
      benefitStartDate: DateTime(startYear + 1, 7, 1),
      currency: 'USD',
      isCapExBudgeted: true,
      isOpExBudgeted: true,
      status: ProjectStatus.approved,
      createdAt: now,
      updatedAt: now,
    );

    // Project 1 has actuals data to demonstrate Budget vs Actuals feature
    final capex = [
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.software,
        description: 'Cloud platform licenses and setup',
        yearlyAmounts: {startYear: 150000, startYear + 1: 50000},
        actualYearlyAmounts: {startYear: 142000}, // Under budget by $8K
        usefulLifeMonths: 36,
        createdAt: now,
        updatedAt: now,
      ),
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.externalLabor,
        description: 'Migration consultants',
        yearlyAmounts: {startYear: 200000, startYear + 1: 100000},
        actualYearlyAmounts: {startYear: 215000}, // Over budget by $15K
        usefulLifeMonths: 36,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final opex = [
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.cloudSubscriptionFees,
        description: 'Cloud hosting subscription',
        yearlyAmounts: {
          startYear: 30000,
          startYear + 1: 60000,
          startYear + 2: 60000,
          startYear + 3: 60000,
          startYear + 4: 60000,
          startYear + 5: 60000,
        },
        actualYearlyAmounts: {startYear: 28500}, // Under budget
        createdAt: now,
        updatedAt: now,
      ),
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.maintenanceFees,
        description: 'Support and maintenance',
        yearlyAmounts: {
          startYear + 1: 20000,
          startYear + 2: 20000,
          startYear + 3: 20000,
          startYear + 4: 20000,
          startYear + 5: 20000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final benefits = [
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.expenseReductions,
        businessUnit: BusinessUnit.corporate,
        description: 'Legacy infrastructure cost savings',
        yearlyAmounts: {
          startYear + 1: 80000,
          startYear + 2: 150000,
          startYear + 3: 180000,
          startYear + 4: 180000,
          startYear + 5: 180000,
        },
        createdAt: now,
        updatedAt: now,
      ),
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.costAvoidance,
        businessUnit: BusinessUnit.corporate,
        description: 'Avoided hardware refresh',
        yearlyAmounts: {
          startYear + 2: 100000,
          startYear + 4: 100000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return {'project': project, 'capex': capex, 'opex': opex, 'benefits': benefits};
  }

  Map<String, dynamic> _createProject2() {
    final now = DateTime.now();
    final startYear = now.year;

    final project = Project(
      id: '',
      pfrNumber: 'PFR-2026-002',
      segment: 'Operations',
      businessUnitGroup: 'Operations',
      businessUnit: 'IT Infrastructure',
      projectName: 'Data Center Modernization',
      initiativeSponsor: 'Emily Chen',
      executiveSponsor: 'David Brown',
      projectRequester: 'Lisa Anderson',
      icCategory: 'Operational',
      description: 'Upgrade data center infrastructure with modern servers, storage, and networking equipment to support growing business demands.',
      rationale: 'Current equipment is 7 years old with increasing failure rates. Modernization will improve performance by 300% and reduce energy costs.',
      projectStartDate: DateTime(startYear, 3, 1),
      projectEndDate: DateTime(startYear + 1, 6, 30),
      benefitStartDate: DateTime(startYear + 1, 1, 1),
      currency: 'USD',
      isCapExBudgeted: true,
      replacesCurrentAssets: true,
      status: ProjectStatus.pendingApproval,
      createdAt: now,
      updatedAt: now,
    );

    final capex = [
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.computerEquipment,
        description: 'Server hardware',
        yearlyAmounts: {startYear: 300000},
        usefulLifeMonths: 60,
        createdAt: now,
        updatedAt: now,
      ),
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.dataEquipment,
        description: 'Storage arrays',
        yearlyAmounts: {startYear: 150000},
        usefulLifeMonths: 60,
        createdAt: now,
        updatedAt: now,
      ),
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.telecomEquipment,
        description: 'Network switches and routers',
        yearlyAmounts: {startYear: 75000},
        usefulLifeMonths: 60,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final opex = [
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.maintenanceFees,
        description: 'Hardware support contracts',
        yearlyAmounts: {
          startYear + 1: 40000,
          startYear + 2: 40000,
          startYear + 3: 40000,
          startYear + 4: 40000,
          startYear + 5: 40000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final benefits = [
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.expenseReductions,
        businessUnit: BusinessUnit.corporate,
        description: 'Energy cost reduction',
        yearlyAmounts: {
          startYear + 1: 50000,
          startYear + 2: 50000,
          startYear + 3: 50000,
          startYear + 4: 50000,
          startYear + 5: 50000,
        },
        createdAt: now,
        updatedAt: now,
      ),
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.capitalAvoidance,
        businessUnit: BusinessUnit.corporate,
        description: 'Avoided emergency repairs',
        yearlyAmounts: {
          startYear + 1: 30000,
          startYear + 2: 40000,
          startYear + 3: 50000,
          startYear + 4: 60000,
          startYear + 5: 70000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return {'project': project, 'capex': capex, 'opex': opex, 'benefits': benefits};
  }

  Map<String, dynamic> _createProject3() {
    final now = DateTime.now();
    final startYear = now.year;

    final project = Project(
      id: '',
      pfrNumber: 'PFR-2026-003',
      segment: 'Marketing',
      businessUnitGroup: 'Marketing',
      businessUnit: 'Data Analytics',
      projectName: 'Customer Analytics Platform',
      initiativeSponsor: 'Rachel Green',
      executiveSponsor: 'Tom Harris',
      projectRequester: 'Amy Wilson',
      icCategory: 'Growth',
      description: 'Implement an advanced customer analytics platform to drive personalized marketing campaigns and improve customer retention.',
      rationale: 'Data-driven marketing will increase customer lifetime value by 25% and reduce churn by 15% within 2 years.',
      projectStartDate: DateTime(startYear, 6, 1),
      projectEndDate: DateTime(startYear + 1, 5, 31),
      benefitStartDate: DateTime(startYear + 1, 1, 1),
      currency: 'USD',
      isCapExBudgeted: false,
      isOpExBudgeted: true,
      hasLongTermCommitment: true,
      status: ProjectStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    final capex = [
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.software,
        description: 'Analytics platform license',
        yearlyAmounts: {startYear: 120000},
        usefulLifeMonths: 36,
        createdAt: now,
        updatedAt: now,
      ),
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.externalLabor,
        description: 'Implementation services',
        yearlyAmounts: {startYear: 80000},
        usefulLifeMonths: 36,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final opex = [
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.cloudSubscriptionFees,
        description: 'Platform subscription',
        yearlyAmounts: {
          startYear + 1: 50000,
          startYear + 2: 50000,
          startYear + 3: 50000,
          startYear + 4: 50000,
          startYear + 5: 50000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final benefits = [
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.netRevenue,
        businessUnit: BusinessUnit.corporate,
        description: 'Increased customer retention revenue',
        yearlyAmounts: {
          startYear + 1: 100000,
          startYear + 2: 200000,
          startYear + 3: 300000,
          startYear + 4: 350000,
          startYear + 5: 400000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return {'project': project, 'capex': capex, 'opex': opex, 'benefits': benefits};
  }

  Map<String, dynamic> _createProject4() {
    final now = DateTime.now();
    final startYear = now.year;

    final project = Project(
      id: '',
      pfrNumber: 'PFR-2026-004',
      segment: 'Finance',
      businessUnitGroup: 'Finance',
      businessUnit: 'Accounting Systems',
      projectName: 'ERP System Upgrade',
      initiativeSponsor: 'Michael Scott',
      executiveSponsor: 'Jan Levinson',
      projectRequester: 'Kevin Malone',
      icCategory: 'Compliance',
      description: 'Upgrade the existing ERP system to the latest version to ensure compliance with new accounting standards and improve financial reporting capabilities.',
      rationale: 'Current ERP version will be unsupported next year. Upgrade ensures continued vendor support, security patches, and compliance with new GAAP standards.',
      projectStartDate: DateTime(startYear, 2, 1),
      projectEndDate: DateTime(startYear + 1, 3, 31),
      benefitStartDate: DateTime(startYear + 1, 4, 1),
      currency: 'USD',
      isCapExBudgeted: true,
      isOpExBudgeted: true,
      status: ProjectStatus.approved,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 5)),
    );

    final capex = [
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.software,
        description: 'ERP license upgrade',
        yearlyAmounts: {startYear: 250000},
        usefulLifeMonths: 60,
        createdAt: now,
        updatedAt: now,
      ),
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.externalLabor,
        description: 'Implementation consultants',
        yearlyAmounts: {startYear: 180000, startYear + 1: 50000},
        usefulLifeMonths: 60,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final opex = [
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.maintenanceFees,
        description: 'Annual maintenance and support',
        yearlyAmounts: {
          startYear + 1: 45000,
          startYear + 2: 45000,
          startYear + 3: 47000,
          startYear + 4: 47000,
          startYear + 5: 49000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final benefits = [
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.expenseReductions,
        businessUnit: BusinessUnit.corporate,
        description: 'Reduced manual reconciliation effort',
        yearlyAmounts: {
          startYear + 1: 60000,
          startYear + 2: 75000,
          startYear + 3: 75000,
          startYear + 4: 75000,
          startYear + 5: 75000,
        },
        createdAt: now,
        updatedAt: now,
      ),
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.costAvoidance,
        businessUnit: BusinessUnit.corporate,
        description: 'Avoided audit penalties',
        yearlyAmounts: {
          startYear + 1: 25000,
          startYear + 2: 25000,
          startYear + 3: 25000,
          startYear + 4: 25000,
          startYear + 5: 25000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return {'project': project, 'capex': capex, 'opex': opex, 'benefits': benefits};
  }

  Map<String, dynamic> _createProject5() {
    final now = DateTime.now();
    final startYear = now.year;

    final project = Project(
      id: '',
      pfrNumber: 'PFR-2026-005',
      segment: 'Human Resources',
      businessUnitGroup: 'Human Resources',
      businessUnit: 'Talent Management',
      projectName: 'Employee Experience Platform',
      initiativeSponsor: 'Toby Flenderson',
      executiveSponsor: 'Holly Flax',
      projectRequester: 'Pam Beesly',
      icCategory: 'Strategic',
      description: 'Deploy a comprehensive employee experience platform to streamline HR processes, improve employee engagement, and enhance talent retention.',
      rationale: 'Employee turnover costs are increasing. A modern HR platform will reduce turnover by 20% and decrease HR administrative time by 40%.',
      projectStartDate: DateTime(startYear, 4, 1),
      projectEndDate: DateTime(startYear, 12, 31),
      benefitStartDate: DateTime(startYear + 1, 1, 1),
      currency: 'USD',
      isCapExBudgeted: false,
      isOpExBudgeted: true,
      hasLongTermCommitment: true,
      status: ProjectStatus.rejected,
      createdAt: now.subtract(const Duration(days: 60)),
      updatedAt: now.subtract(const Duration(days: 10)),
    );

    final capex = [
      CapExItem(
        id: '',
        projectId: '',
        category: CapExCategory.software,
        description: 'Platform setup and configuration',
        yearlyAmounts: {startYear: 85000},
        usefulLifeMonths: 36,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final opex = [
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.cloudSubscriptionFees,
        description: 'SaaS subscription (per employee)',
        yearlyAmounts: {
          startYear: 40000,
          startYear + 1: 80000,
          startYear + 2: 85000,
          startYear + 3: 90000,
          startYear + 4: 95000,
          startYear + 5: 100000,
        },
        createdAt: now,
        updatedAt: now,
      ),
      OpExItem(
        id: '',
        projectId: '',
        category: OpExCategory.externalLabor,
        description: 'HR team training',
        yearlyAmounts: {startYear: 15000, startYear + 1: 5000},
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final benefits = [
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.expenseReductions,
        businessUnit: BusinessUnit.corporate,
        description: 'Reduced turnover costs',
        yearlyAmounts: {
          startYear + 1: 120000,
          startYear + 2: 180000,
          startYear + 3: 200000,
          startYear + 4: 200000,
          startYear + 5: 200000,
        },
        createdAt: now,
        updatedAt: now,
      ),
      BenefitItem(
        id: '',
        projectId: '',
        category: BenefitCategory.expenseReductions,
        businessUnit: BusinessUnit.corporate,
        description: 'HR administrative time savings',
        yearlyAmounts: {
          startYear + 1: 35000,
          startYear + 2: 45000,
          startYear + 3: 50000,
          startYear + 4: 50000,
          startYear + 5: 50000,
        },
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return {'project': project, 'capex': capex, 'opex': opex, 'benefits': benefits};
  }

  Map<String, dynamic> _projectToFirestore(Project project, String? userId) {
    return {
      'userId': userId,
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
      'submissionDate': project.submissionDate != null ? Timestamp.fromDate(project.submissionDate!) : null,
      'projectStartDate': Timestamp.fromDate(project.projectStartDate),
      'projectEndDate': Timestamp.fromDate(project.projectEndDate),
      'benefitStartDate': project.benefitStartDate != null ? Timestamp.fromDate(project.benefitStartDate!) : null,
      'lobApprovalDate': project.lobApprovalDate != null ? Timestamp.fromDate(project.lobApprovalDate!) : null,
      'nextIcUpdateDate': project.nextIcUpdateDate != null ? Timestamp.fromDate(project.nextIcUpdateDate!) : null,
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
      'createdAt': Timestamp.fromDate(project.createdAt),
      'updatedAt': Timestamp.fromDate(project.updatedAt),
    };
  }

  Map<String, dynamic> _capexToFirestore(CapExItem item) {
    return {
      'category': item.category.name,
      'description': item.description,
      'yearlyAmounts': item.yearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'actualYearlyAmounts': item.actualYearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'usefulLifeMonths': item.usefulLifeMonths,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }

  Map<String, dynamic> _opexToFirestore(OpExItem item) {
    return {
      'category': item.category.name,
      'description': item.description,
      'yearlyAmounts': item.yearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'actualYearlyAmounts': item.actualYearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }

  Map<String, dynamic> _benefitToFirestore(BenefitItem item) {
    return {
      'category': item.category.name,
      'businessUnit': item.businessUnit.name,
      'description': item.description,
      'yearlyAmounts': item.yearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'actualYearlyAmounts': item.actualYearlyAmounts.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': Timestamp.fromDate(item.createdAt),
      'updatedAt': Timestamp.fromDate(item.updatedAt),
    };
  }
}
