import 'package:equatable/equatable.dart';
import '../../core/constants/financial_constants.dart';

/// Capital Expenditure line item
class CapExItem extends Equatable {
  final String id;
  final String projectId;
  final CapExCategory category;
  final String description;
  final Map<int, double> yearlyAmounts; // year -> amount
  final int usefulLifeMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CapExItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.description,
    required this.yearlyAmounts,
    required this.usefulLifeMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => yearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  CapExItem copyWith({
    String? id,
    String? projectId,
    CapExCategory? category,
    String? description,
    Map<int, double>? yearlyAmounts,
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
      usefulLifeMonths: usefulLifeMonths ?? this.usefulLifeMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, category, description, yearlyAmounts, usefulLifeMonths, createdAt, updatedAt];
}

/// Operating Expenditure line item
class OpExItem extends Equatable {
  final String id;
  final String projectId;
  final OpExCategory category;
  final String description;
  final Map<int, double> yearlyAmounts; // year -> amount
  final DateTime createdAt;
  final DateTime updatedAt;

  const OpExItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.description,
    required this.yearlyAmounts,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => yearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  OpExItem copyWith({
    String? id,
    String? projectId,
    OpExCategory? category,
    String? description,
    Map<int, double>? yearlyAmounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OpExItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      category: category ?? this.category,
      description: description ?? this.description,
      yearlyAmounts: yearlyAmounts ?? this.yearlyAmounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, category, description, yearlyAmounts, createdAt, updatedAt];
}

/// Benefit line item
class BenefitItem extends Equatable {
  final String id;
  final String projectId;
  final BenefitCategory category;
  final BusinessUnit businessUnit;
  final String description;
  final Map<int, double> yearlyAmounts; // year -> amount
  final DateTime createdAt;
  final DateTime updatedAt;

  const BenefitItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.businessUnit,
    required this.description,
    required this.yearlyAmounts,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => yearlyAmounts.values.fold(0.0, (sum, v) => sum + v);

  BenefitItem copyWith({
    String? id,
    String? projectId,
    BenefitCategory? category,
    BusinessUnit? businessUnit,
    String? description,
    Map<int, double>? yearlyAmounts,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, category, businessUnit, description, yearlyAmounts, createdAt, updatedAt];
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

  /// Total CapEx across all years
  double get totalCapEx => yearlyCapEx.fold(0.0, (sum, v) => sum + v);

  /// Total OpEx across all years
  double get totalOpEx => yearlyOpEx.fold(0.0, (sum, v) => sum + v);

  /// Total Benefits across all years
  double get totalBenefits => yearlyBenefits.fold(0.0, (sum, v) => sum + v);

  /// Total costs (CapEx + OpEx)
  double get totalCosts => totalCapEx + totalOpEx;

  /// CapEx percentage of total costs
  int get capExPercent => totalCosts > 0 ? ((totalCapEx / totalCosts) * 100).round() : 0;

  /// OpEx percentage of total costs
  int get opExPercent => totalCosts > 0 ? ((totalOpEx / totalCosts) * 100).round() : 0;

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
