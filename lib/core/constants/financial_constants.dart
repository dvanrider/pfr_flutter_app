/// Financial constants extracted from the PFR Excel model
library;

class FinancialConstants {
  FinancialConstants._();

  /// Cost of capital used for NPV calculations (15%)
  static const double hurdleRate = 0.15;

  /// Default tax rate for income tax calculations
  static const double defaultTaxRate = 0.25;

  /// Number of years in financial projections
  static const int projectionYears = 6;

  /// Maximum months for payback period calculation (5 years)
  static const int maxPaybackMonths = 60;

  /// Default contingency rate for capital expenditures
  static const double defaultContingencyRate = 0.15;

  /// Threshold for IC (Investment Committee) approval requirement
  static const double icApprovalThreshold = 1000000.0;

  /// Lease term threshold (years) requiring IC approval
  static const int leaseTermThresholdYears = 5;

  /// IRR threshold below which to display "N/A"
  static const double irrMinThreshold = 0.009;

  /// Default useful life in months by asset category
  static const Map<String, int> defaultUsefulLifeMonths = {
    'internalLaborIT': 36,
    'externalLabor': 36,
    'furnitureFixtures': 60,
    'computerEquipment': 36,
    'dataEquipment': 36,
    'telecomEquipment': 60,
    'hardware': 36,
    'software': 36,
    'buildingsImprovements': 240,
    'leaseholdImprovements': 120,
    'other': 60,
  };
}

/// Capital expenditure categories matching Excel model
enum CapExCategory {
  internalLaborIT('Internal Labor (IT Only)', 36),
  externalLabor('External Labor', 36),
  furnitureFixtures('Furniture & Fixtures', 60),
  computerEquipment('Computer Equipment', 36),
  dataEquipment('Data Equipment', 36),
  telecomEquipment('Telecom Equipment', 60),
  hardware('Hardware', 36),
  software('Software', 36),
  buildingsImprovements('Buildings/Bldg Improvements', 240),
  leaseholdImprovements('Leasehold Improvements', 120),
  other('Other', 60);

  const CapExCategory(this.displayName, this.defaultUsefulLifeMonths);

  final String displayName;
  final int defaultUsefulLifeMonths;
}

/// Operating expense categories matching Excel model
enum OpExCategory {
  internalLabor('Internal Labor'),
  externalLabor('External Labor'),
  cloudSubscriptionFees('Cloud Subscription Fees'),
  maintenanceFees('Maintenance Fees'),
  prepaidCloudAmortization('Prepaid Cloud Amortization'),
  rentNonCre('Rent - Non CRE'),
  rentCre('Rent - CRE Financials'),
  operatingCostsCre('Operating Costs - CRE Financials'),
  brokerageCommissions('Brokerage Commissions'),
  tenantImprovementAllowance('Tenant Improvement Allowance'),
  accretionCre('Accretion - CRE Financials (FIN 47)'),
  other('Other');

  const OpExCategory(this.displayName);

  final String displayName;
}

/// Benefit categories matching Excel model
enum BenefitCategory {
  capitalAvoidance('Capital Avoidance'),
  netRevenue('Net Revenue'),
  expenseReductions('Expense Reductions'),
  existingRent('Existing Rent'),
  costAvoidance('Cost Avoidance'),
  otherIncome('Other Income');

  const BenefitCategory(this.displayName);

  final String displayName;
}

/// Business units that can have benefits
enum BusinessUnit {
  wynD('WynD'),
  voi('VOI'),
  exchange('Exchange'),
  corporate('Corporate');

  const BusinessUnit(this.displayName);

  final String displayName;
}

/// Project status workflow
enum ProjectStatus {
  draft('Draft'),
  submitted('Submitted'),
  pendingApproval('Pending Approval'),
  approved('Approved'),
  rejected('Rejected'),
  onHold('On Hold'),
  cancelled('Cancelled');

  const ProjectStatus(this.displayName);

  final String displayName;
}

/// Approval roles in the workflow
enum ApprovalRole {
  projectSponsor('Project Sponsor'),
  executiveSponsor('Executive Sponsor'),
  investmentCommittee('Investment Committee');

  const ApprovalRole(this.displayName);

  final String displayName;
}

/// Financial metric status for traffic lighting
enum MetricStatus {
  green('Meets Target'),
  yellow('Near Target'),
  red('Below Target');

  const MetricStatus(this.displayName);

  final String displayName;
}

/// Budget vs Actuals variance status
enum VarianceStatus {
  favorable('Favorable'),
  unfavorable('Unfavorable'),
  neutral('On Target');

  const VarianceStatus(this.displayName);

  final String displayName;

  /// Get status based on variance amount and whether it's a cost or benefit
  static VarianceStatus fromVariance(double variance, {bool isCost = true}) {
    if (variance.abs() < 0.01) return VarianceStatus.neutral;
    // For costs: positive variance (under-spend) is favorable
    // For benefits: positive variance (exceeded target) is favorable
    return variance > 0 ? VarianceStatus.favorable : VarianceStatus.unfavorable;
  }
}
