import 'package:equatable/equatable.dart';
import '../../core/constants/financial_constants.dart';

/// Capital Expenditure line item
class CapExItem extends Equatable {
  final String id;
  final String projectId;
  final CapExCategory category;
  final String description;
  final Map<int, double> yearlyAmounts; // year -> budgeted amount
  final Map<int, double> actualYearlyAmounts; // year -> actual amount
  final int usefulLifeMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CapExItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.description,
    required this.yearlyAmounts,
    this.actualYearlyAmounts = const {},
    required this.usefulLifeMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => yearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  double get totalActualAmount => actualYearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  /// Variance = Budget - Actual (positive = under-spend = favorable for costs)
  double get totalVariance => totalAmount - totalActualAmount;

  double? get variancePercent => totalAmount > 0 ? (totalVariance / totalAmount) * 100 : null;

  double getVarianceForYear(int year) {
    final budget = yearlyAmounts[year] ?? 0.0;
    final actual = actualYearlyAmounts[year] ?? 0.0;
    return budget - actual;
  }

  CapExItem copyWith({
    String? id,
    String? projectId,
    CapExCategory? category,
    String? description,
    Map<int, double>? yearlyAmounts,
    Map<int, double>? actualYearlyAmounts,
    int? usefulLifeMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CapExItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      description: description ?? this.description,
      yearlyAmounts: yearlyAmounts ?? this.yearlyAmounts,
      actualYearlyAmounts: actualYearlyAmounts ?? this.actualYearlyAmounts,
      usefulLifeMonths: usefulLifeMonths ?? this.usefulLifeMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, category, description, yearlyAmounts, actualYearlyAmounts, usefulLifeMonths, createdAt, updatedAt];
}

/// Operating Expenditure line item
class OpExItem extends Equatable {
  final String id;
  final String projectId;
  final OpExCategory category;
  final String description;
  final Map<int, double> yearlyAmounts; // year -> budgeted amount
  final Map<int, double> actualYearlyAmounts; // year -> actual amount
  final DateTime createdAt;
  final DateTime updatedAt;

  const OpExItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.description,
    required this.yearlyAmounts,
    this.actualYearlyAmounts = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => yearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  double get totalActualAmount => actualYearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  /// Variance = Budget - Actual (positive = under-spend = favorable for costs)
  double get totalVariance => totalAmount - totalActualAmount;

  double? get variancePercent => totalAmount > 0 ? (totalVariance / totalAmount) * 100 : null;

  double getVarianceForYear(int year) {
    final budget = yearlyAmounts[year] ?? 0.0;
    final actual = actualYearlyAmounts[year] ?? 0.0;
    return budget - actual;
  }

  OpExItem copyWith({
    String? id,
    String? projectId,
    OpExCategory? category,
    String? description,
    Map<int, double>? yearlyAmounts,
    Map<int, double>? actualYearlyAmounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OpExItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      description: description ?? this.description,
      yearlyAmounts: yearlyAmounts ?? this.yearlyAmounts,
      actualYearlyAmounts: actualYearlyAmounts ?? this.actualYearlyAmounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, category, description, yearlyAmounts, actualYearlyAmounts, createdAt, updatedAt];
}

/// Benefit line item
class BenefitItem extends Equatable {
  final String id;
  final String projectId;
  final BenefitCategory category;
  final BusinessUnit businessUnit;
  final String description;
  final Map<int, double> yearlyAmounts; // year -> budgeted amount
  final Map<int, double> actualYearlyAmounts; // year -> actual amount
  final DateTime createdAt;
  final DateTime updatedAt;

  const BenefitItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.businessUnit,
    required this.description,
    required this.yearlyAmounts,
    this.actualYearlyAmounts = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => yearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  double get totalActualAmount => actualYearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  /// Variance = Actual - Budget (positive = exceeded target = favorable for benefits)
  double get totalVariance => totalActualAmount - totalAmount;

  double? get variancePercent => totalAmount > 0 ? (totalVariance / totalAmount) * 100 : null;

  double getVarianceForYear(int year) {
    final budget = yearlyAmounts[year] ?? 0.0;
    final actual = actualYearlyAmounts[year] ?? 0.0;
    return actual - budget; // Reversed for benefits
  }

  BenefitItem copyWith({
    String? id,
    String? projectId,
    BenefitCategory? category,
    BusinessUnit? businessUnit,
    String? description,
    Map<int, double>? yearlyAmounts,
    Map<int, double>? actualYearlyAmounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BenefitItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      businessUnit: businessUnit ?? this.businessUnit,
      description: description ?? this.description,
      yearlyAmounts: yearlyAmounts ?? this.yearlyAmounts,
      actualYearlyAmounts: actualYearlyAmounts ?? this.actualYearlyAmounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, category, businessUnit, description, yearlyAmounts, actualYearlyAmounts, createdAt, updatedAt];
}

/// Aggregated financial summary for a project
class ProjectFinancials {
  final List<CapExItem> capexItems;
  final List<OpExItem> opexItems;
  final List<BenefitItem> benefitItems;
  final int startYear;
  final int projectionYears;

  ProjectFinancials({
    required this.capexItems,
    required this.opexItems,
    required this.benefitItems,
    required this.startYear,
    this.projectionYears = 6,
  });

  /// Get total CapEx for a specific year
  double getCapExForYear(int year) {
    return capexItems.fold(0.0, (sum, item) => sum + (item.yearlyAmounts[year] ?? 0.0));
  }

  /// Get total OpEx for a specific year
  double getOpExForYear(int year) {
    return opexItems.fold(0.0, (sum, item) => sum + (item.yearlyAmounts[year] ?? 0.0));
  }

  /// Get total Benefits for a specific year
  double getBenefitsForYear(int year) {
    return benefitItems.fold(0.0, (sum, item) => sum + (item.yearlyAmounts[year] ?? 0.0));
  }

  /// Get total costs (CapEx + OpEx) for a specific year
  double getCostsForYear(int year) {
    return getCapExForYear(year) + getOpExForYear(year);
  }

  /// Get net cash flow for a specific year
  double getNetCashFlowForYear(int year) {
    return getBenefitsForYear(year) - getCostsForYear(year);
  }

  // ==================== ACTUALS METHODS ====================

  /// Get actual CapEx for a specific year
  double getActualCapExForYear(int year) {
    return capexItems.fold(0.0, (sum, item) => sum + (item.actualYearlyAmounts[year] ?? 0.0));
  }

  /// Get actual OpEx for a specific year
  double getActualOpExForYear(int year) {
    return opexItems.fold(0.0, (sum, item) => sum + (item.actualYearlyAmounts[year] ?? 0.0));
  }

  /// Get actual Benefits for a specific year
  double getActualBenefitsForYear(int year) {
    return benefitItems.fold(0.0, (sum, item) => sum + (item.actualYearlyAmounts[year] ?? 0.0));
  }

  /// Get actual total costs for a specific year
  double getActualCostsForYear(int year) {
    return getActualCapExForYear(year) + getActualOpExForYear(year);
  }

  // ==================== VARIANCE METHODS ====================

  /// Get cost variance for a year (positive = under-spend = favorable)
  double getCostVarianceForYear(int year) {
    return getCostsForYear(year) - getActualCostsForYear(year);
  }

  /// Get benefit variance for a year (positive = exceeded target = favorable)
  double getBenefitVarianceForYear(int year) {
    return getActualBenefitsForYear(year) - getBenefitsForYear(year);
  }

  /// Get CapEx variance for a year
  double getCapExVarianceForYear(int year) {
    return getCapExForYear(year) - getActualCapExForYear(year);
  }

  /// Get OpEx variance for a year
  double getOpExVarianceForYear(int year) {
    return getOpExForYear(year) - getActualOpExForYear(year);
  }

  /// Get yearly CapEx as a list
  List<double> get yearlyCapEx {
    return List.generate(projectionYears, (i) => getCapExForYear(startYear + i));
  }

  /// Get yearly OpEx as a list
  List<double> get yearlyOpEx {
    return List.generate(projectionYears, (i) => getOpExForYear(startYear + i));
  }

  /// Get yearly Benefits as a list
  List<double> get yearlyBenefits {
    return List.generate(projectionYears, (i) => getBenefitsForYear(startYear + i));
  }

  /// Get yearly total costs as a list
  List<double> get yearlyCosts {
    return List.generate(projectionYears, (i) => getCostsForYear(startYear + i));
  }

  /// Get yearly net cash flow as a list
  List<double> get yearlyNetCashFlow {
    return List.generate(projectionYears, (i) => getNetCashFlowForYear(startYear + i));
  }

  /// Get cumulative cash flow as a list
  List<double> get yearlyCumulative {
    final result = <double>[];
    double sum = 0;
    for (final net in yearlyNetCashFlow) {
      sum += net;
      result.add(sum);
    }
    return result;
  }

  // ==================== ACTUALS YEARLY LISTS ====================

  /// Get yearly actual CapEx as a list
  List<double> get yearlyActualCapEx {
    return List.generate(projectionYears, (i) => getActualCapExForYear(startYear + i));
  }

  /// Get yearly actual OpEx as a list
  List<double> get yearlyActualOpEx {
    return List.generate(projectionYears, (i) => getActualOpExForYear(startYear + i));
  }

  /// Get yearly actual Benefits as a list
  List<double> get yearlyActualBenefits {
    return List.generate(projectionYears, (i) => getActualBenefitsForYear(startYear + i));
  }

  /// Get yearly actual total costs as a list
  List<double> get yearlyActualCosts {
    return List.generate(projectionYears, (i) => getActualCostsForYear(startYear + i));
  }

  // ==================== VARIANCE YEARLY LISTS ====================

  /// Get yearly cost variance as a list
  List<double> get yearlyCostVariance {
    return List.generate(projectionYears, (i) => getCostVarianceForYear(startYear + i));
  }

  /// Get yearly benefit variance as a list
  List<double> get yearlyBenefitVariance {
    return List.generate(projectionYears, (i) => getBenefitVarianceForYear(startYear + i));
  }

  /// Get yearly CapEx variance as a list
  List<double> get yearlyCapExVariance {
    return List.generate(projectionYears, (i) => getCapExVarianceForYear(startYear + i));
  }

  /// Get yearly OpEx variance as a list
  List<double> get yearlyOpExVariance {
    return List.generate(projectionYears, (i) => getOpExVarianceForYear(startYear + i));
  }

  /// Total CapEx across all years
  double get totalCapEx => yearlyCapEx.fold(0.0, (sum, v) => sum + v);

  /// Total OpEx across all years
  double get totalOpEx => yearlyOpEx.fold(0.0, (sum, v) => sum + v);

  /// Total Benefits across all years
  double get totalBenefits => yearlyBenefits.fold(0.0, (sum, v) => sum + v);

  /// Total costs (CapEx + OpEx)
  double get totalCosts => totalCapEx + totalOpEx;

  // ==================== ACTUALS TOTALS ====================

  /// Total actual CapEx across all years
  double get totalActualCapEx => yearlyActualCapEx.fold(0.0, (sum, v) => sum + v);

  /// Total actual OpEx across all years
  double get totalActualOpEx => yearlyActualOpEx.fold(0.0, (sum, v) => sum + v);

  /// Total actual Benefits across all years
  double get totalActualBenefits => yearlyActualBenefits.fold(0.0, (sum, v) => sum + v);

  /// Total actual costs
  double get totalActualCosts => totalActualCapEx + totalActualOpEx;

  // ==================== VARIANCE TOTALS ====================

  /// Total cost variance (positive = under-spend = favorable)
  double get totalCostVariance => totalCosts - totalActualCosts;

  /// Total benefit variance (positive = exceeded target = favorable)
  double get totalBenefitVariance => totalActualBenefits - totalBenefits;

  /// Total CapEx variance
  double get totalCapExVariance => totalCapEx - totalActualCapEx;

  /// Total OpEx variance
  double get totalOpExVariance => totalOpEx - totalActualOpEx;

  /// CapEx percentage of total costs
  int get capExPercent => totalCosts > 0 ? ((totalCapEx / totalCosts) * 100).round() : 0;

  /// OpEx percentage of total costs
  int get opExPercent => totalCosts > 0 ? ((totalOpEx / totalCosts) * 100).round() : 0;

  /// Check if project has any actuals data entered
  bool get hasActualsData {
    return capexItems.any((item) => item.actualYearlyAmounts.isNotEmpty) ||
           opexItems.any((item) => item.actualYearlyAmounts.isNotEmpty) ||
           benefitItems.any((item) => item.actualYearlyAmounts.isNotEmpty);
  }

  /// Calculate NPV at given discount rate
  double calculateNPV(double discountRate) {
    double npv = 0;
    for (int i = 0; i < projectionYears; i++) {
      final cashFlow = getNetCashFlowForYear(startYear + i);
      npv += cashFlow / pow(1 + discountRate, i + 1);
    }
    return npv;
  }

  /// Calculate IRR using Newton-Raphson method
  double? calculateIRR({int maxIterations = 100, double tolerance = 0.0001}) {
    final cashFlows = yearlyNetCashFlow;

    // Check if we have both positive and negative cash flows
    final hasPositive = cashFlows.any((cf) => cf > 0);
    final hasNegative = cashFlows.any((cf) => cf < 0);
    if (!hasPositive || !hasNegative) return null;

    double rate = 0.1; // Initial guess

    for (int i = 0; i < maxIterations; i++) {
      double npv = 0;
      double derivative = 0;

      for (int t = 0; t < cashFlows.length; t++) {
        final discountFactor = pow(1 + rate, t + 1);
        npv += cashFlows[t] / discountFactor;
        derivative -= (t + 1) * cashFlows[t] / pow(1 + rate, t + 2);
      }

      if (derivative.abs() < 1e-10) break;

      final newRate = rate - npv / derivative;

      if ((newRate - rate).abs() < tolerance) {
        return newRate;
      }

      rate = newRate;

      // Bound the rate to reasonable values
      if (rate < -0.99) rate = -0.99;
      if (rate > 10) rate = 10;
    }

    return rate;
  }

  /// Calculate simple payback period in months
  int? calculatePaybackMonths() {
    double cumulative = 0;

    for (int year = 0; year < projectionYears; year++) {
      final yearCashFlow = getNetCashFlowForYear(startYear + year);
      final previousCumulative = cumulative;
      cumulative += yearCashFlow;

      if (cumulative >= 0 && previousCumulative < 0) {
        // Payback occurred this year - interpolate to get months
        final monthsInYear = ((-previousCumulative) / yearCashFlow * 12).round();
        return (year * 12) + monthsInYear;
      } else if (year == 0 && cumulative >= 0) {
        // Payback in first year
        if (yearCashFlow > 0) {
          return ((totalCosts - cumulative + yearCashFlow) / yearCashFlow * 12).round();
        }
        return 0;
      }
    }

    return null; // No payback within projection period
  }

  /// Check if project has any financial data
  bool get hasData => capexItems.isNotEmpty || opexItems.isNotEmpty || benefitItems.isNotEmpty;
}

/// Power function for double
double pow(double base, int exponent) {
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
