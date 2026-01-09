import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/project.dart';
import '../../../data/models/financial_items.dart';
import '../../../providers/providers.dart';

/// Sensitivity variable type
enum SensitivityVariable {
  capex('CapEx', 'Capital Expenditure'),
  opex('OpEx', 'Operating Expenditure'),
  benefits('Benefits', 'Revenue/Benefits'),
  discountRate('Discount Rate', 'Discount Rate');

  final String label;
  final String description;
  const SensitivityVariable(this.label, this.description);
}

/// Sensitivity Analysis Screen
class SensitivityAnalysisScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const SensitivityAnalysisScreen({super.key, this.projectId});

  @override
  ConsumerState<SensitivityAnalysisScreen> createState() => _SensitivityAnalysisScreenState();
}

class _SensitivityAnalysisScreenState extends ConsumerState<SensitivityAnalysisScreen> {
  double _variationPercent = 20.0;
  SensitivityVariable? _selectedVariable;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    // If no project selected, show project selection screen
    if (_selectedProjectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sensitivity Analysis')),
        body: Row(
          children: [
            // Project selection panel
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Select Project',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: projectsAsync.when(
                      data: (projects) {
                        final validProjects = projects.where((p) =>
                            p.status == ProjectStatus.approved ||
                            p.status == ProjectStatus.submitted ||
                            p.status == ProjectStatus.pendingApproval).toList();
                        if (validProjects.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No approved projects available'),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: validProjects.length,
                          itemBuilder: (context, index) {
                            final project = validProjects[index];
                            return ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(project.projectName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(project.businessUnit),
                              onTap: () => setState(() => _selectedProjectId = project.id),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            ),
            // Placeholder for main content
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Select a project to analyze sensitivity', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final projectAsync = ref.watch(projectByIdProvider(_selectedProjectId!));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sensitivity Analysis')),
            body: const Center(child: Text('Project not found')),
          );
        }
        return _SensitivityScaffold(
          project: project,
          variationPercent: _variationPercent,
          selectedVariable: _selectedVariable,
          onVariationChanged: (value) => setState(() => _variationPercent = value),
          onVariableSelected: (variable) => setState(() => _selectedVariable = variable),
          onProjectChange: () => setState(() => _selectedProjectId = null),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Sensitivity Analysis')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Sensitivity Analysis')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SensitivityScaffold extends ConsumerWidget {
  final Project project;
  final double variationPercent;
  final SensitivityVariable? selectedVariable;
  final ValueChanged<double> onVariationChanged;
  final ValueChanged<SensitivityVariable?> onVariableSelected;
  final VoidCallback? onProjectChange;

  const _SensitivityScaffold({
    required this.project,
    required this.variationPercent,
    required this.selectedVariable,
    required this.onVariationChanged,
    required this.onVariableSelected,
    this.onProjectChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialsAsync = ref.watch(projectFinancialsProvider((
      projectId: project.id,
      startYear: project.startYear,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensitivity Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onProjectChange ?? () => context.go('/project/${project.id}/analysis'),
        ),
        actions: [
          if (onProjectChange != null)
            TextButton.icon(
              onPressed: onProjectChange,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text('Change Project', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: financialsAsync.when(
        data: (financials) => _SensitivityBody(
          project: project,
          financials: financials,
          variationPercent: variationPercent,
          selectedVariable: selectedVariable,
          onVariationChanged: onVariationChanged,
          onVariableSelected: onVariableSelected,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SensitivityBody extends StatelessWidget {
  final Project project;
  final ProjectFinancials financials;
  final double variationPercent;
  final SensitivityVariable? selectedVariable;
  final ValueChanged<double> onVariationChanged;
  final ValueChanged<SensitivityVariable?> onVariableSelected;

  const _SensitivityBody({
    required this.project,
    required this.financials,
    required this.variationPercent,
    required this.selectedVariable,
    required this.onVariationChanged,
    required this.onVariableSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Calculate base NPV
    final baseNPV = financials.calculateNPV(FinancialConstants.hurdleRate);

    // Calculate sensitivity for each variable
    final sensitivities = _calculateSensitivities(financials, variationPercent);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'What-if Scenarios & Sensitivity Analysis',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variation Range',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: variationPercent,
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: '±${variationPercent.toInt()}%',
                          onChanged: onVariationChanged,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '±${variationPercent.toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Base NPV
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      const Text('Base Case NPV'),
                      Text(
                        currencyFormat.format(baseNPV),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: baseNPV >= 0 ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tornado Chart
          Text(
            'Tornado Chart - NPV Sensitivity',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Shows the impact of ±${variationPercent.toInt()}% change in each variable on NPV',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _TornadoChart(
              sensitivities: sensitivities,
              baseNPV: baseNPV,
              variationPercent: variationPercent,
            ),
          ),
          const SizedBox(height: 32),

          // What-if scenarios table
          Text(
            'What-If Scenarios',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ScenariosTable(
            sensitivities: sensitivities,
            baseNPV: baseNPV,
            variationPercent: variationPercent,
          ),
          const SizedBox(height: 32),

          // Detailed variable analysis
          Text(
            'Variable Deep Dive',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: SensitivityVariable.values.map((v) {
              final isSelected = selectedVariable == v;
              return ChoiceChip(
                label: Text(v.label),
                selected: isSelected,
                onSelected: (selected) => onVariableSelected(selected ? v : null),
              );
            }).toList(),
          ),
          if (selectedVariable != null) ...[
            const SizedBox(height: 16),
            _VariableDetailCard(
              variable: selectedVariable!,
              financials: financials,
              variationPercent: variationPercent,
            ),
          ],
        ],
      ),
    );
  }

  List<_SensitivityResult> _calculateSensitivities(
    ProjectFinancials financials,
    double variationPercent,
  ) {
    final results = <_SensitivityResult>[];
    final variation = variationPercent / 100;

    // CapEx sensitivity
    final capexLow = _calculateAdjustedNPV(financials, capexFactor: 1 - variation);
    final capexHigh = _calculateAdjustedNPV(financials, capexFactor: 1 + variation);
    results.add(_SensitivityResult(
      variable: SensitivityVariable.capex,
      lowNPV: capexHigh, // Higher capex = lower NPV
      highNPV: capexLow, // Lower capex = higher NPV
      impact: (capexLow - capexHigh).abs(),
    ));

    // OpEx sensitivity
    final opexLow = _calculateAdjustedNPV(financials, opexFactor: 1 - variation);
    final opexHigh = _calculateAdjustedNPV(financials, opexFactor: 1 + variation);
    results.add(_SensitivityResult(
      variable: SensitivityVariable.opex,
      lowNPV: opexHigh,
      highNPV: opexLow,
      impact: (opexLow - opexHigh).abs(),
    ));

    // Benefits sensitivity
    final benefitsLow = _calculateAdjustedNPV(financials, benefitsFactor: 1 - variation);
    final benefitsHigh = _calculateAdjustedNPV(financials, benefitsFactor: 1 + variation);
    results.add(_SensitivityResult(
      variable: SensitivityVariable.benefits,
      lowNPV: benefitsLow,
      highNPV: benefitsHigh,
      impact: (benefitsHigh - benefitsLow).abs(),
    ));

    // Discount rate sensitivity
    final discountLow = financials.calculateNPV(FinancialConstants.hurdleRate * (1 - variation));
    final discountHigh = financials.calculateNPV(FinancialConstants.hurdleRate * (1 + variation));
    results.add(_SensitivityResult(
      variable: SensitivityVariable.discountRate,
      lowNPV: discountHigh, // Higher discount = lower NPV
      highNPV: discountLow, // Lower discount = higher NPV
      impact: (discountLow - discountHigh).abs(),
    ));

    // Sort by impact
    results.sort((a, b) => b.impact.compareTo(a.impact));

    return results;
  }

  double _calculateAdjustedNPV(
    ProjectFinancials financials, {
    double capexFactor = 1.0,
    double opexFactor = 1.0,
    double benefitsFactor = 1.0,
  }) {
    double npv = 0;
    final discountRate = FinancialConstants.hurdleRate;

    for (int i = 0; i < financials.projectionYears; i++) {
      final year = financials.startYear + i;
      final capex = financials.getCapExForYear(year) * capexFactor;
      final opex = financials.getOpExForYear(year) * opexFactor;
      final benefits = financials.getBenefitsForYear(year) * benefitsFactor;
      final cashFlow = benefits - capex - opex;
      npv += cashFlow / pow(1 + discountRate, i + 1);
    }

    return npv;
  }
}

class _SensitivityResult {
  final SensitivityVariable variable;
  final double lowNPV;
  final double highNPV;
  final double impact;

  _SensitivityResult({
    required this.variable,
    required this.lowNPV,
    required this.highNPV,
    required this.impact,
  });
}

class _TornadoChart extends StatelessWidget {
  final List<_SensitivityResult> sensitivities;
  final double baseNPV;
  final double variationPercent;

  const _TornadoChart({
    required this.sensitivities,
    required this.baseNPV,
    required this.variationPercent,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compact();

    // Find min and max for scaling
    double minNPV = baseNPV;
    double maxNPV = baseNPV;
    for (final s in sensitivities) {
      minNPV = math.min(minNPV, math.min(s.lowNPV, s.highNPV));
      maxNPV = math.max(maxNPV, math.max(s.lowNPV, s.highNPV));
    }

    // Add padding
    final range = maxNPV - minNPV;
    minNPV -= range * 0.1;
    maxNPV += range * 0.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.center,
            maxY: maxNPV,
            minY: minNPV,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final s = sensitivities[groupIndex];
                  return BarTooltipItem(
                    '${s.variable.label}\n'
                    'Low: \$${currencyFormat.format(s.lowNPV)}\n'
                    'High: \$${currencyFormat.format(s.highNPV)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= sensitivities.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        sensitivities[value.toInt()].variable.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${currencyFormat.format(value)}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxNPV - minNPV) / 5,
            ),
            borderData: FlBorderData(show: false),
            barGroups: sensitivities.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    fromY: s.lowNPV,
                    toY: s.highNPV,
                    width: 30,
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [Colors.red[400]!, Colors.green[400]!],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              );
            }).toList(),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: baseNPV,
                  color: Colors.black,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    labelResolver: (_) => 'Base NPV',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenariosTable extends StatelessWidget {
  final List<_SensitivityResult> sensitivities;
  final double baseNPV;
  final double variationPercent;

  const _ScenariosTable({
    required this.sensitivities,
    required this.baseNPV,
    required this.variationPercent,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Variable', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('-${variationPercent.toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Base', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('+${variationPercent.toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Impact', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...sensitivities.map((s) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(s.variable.description),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      currencyFormat.format(s.lowNPV),
                      style: TextStyle(color: s.lowNPV < baseNPV ? Colors.red : Colors.green),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(currencyFormat.format(baseNPV)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      currencyFormat.format(s.highNPV),
                      style: TextStyle(color: s.highNPV > baseNPV ? Colors.green : Colors.red),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currencyFormat.format(s.impact),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _VariableDetailCard extends StatelessWidget {
  final SensitivityVariable variable;
  final ProjectFinancials financials;
  final double variationPercent;

  const _VariableDetailCard({
    required this.variable,
    required this.financials,
    required this.variationPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Generate data points for line chart
    final dataPoints = <double, double>{};
    for (int percent = -50; percent <= 50; percent += 10) {
      final factor = 1 + (percent / 100);
      double npv;

      switch (variable) {
        case SensitivityVariable.capex:
          npv = _calculateAdjustedNPV(financials, capexFactor: factor);
          break;
        case SensitivityVariable.opex:
          npv = _calculateAdjustedNPV(financials, opexFactor: factor);
          break;
        case SensitivityVariable.benefits:
          npv = _calculateAdjustedNPV(financials, benefitsFactor: factor);
          break;
        case SensitivityVariable.discountRate:
          npv = financials.calculateNPV(FinancialConstants.hurdleRate * factor);
          break;
      }

      dataPoints[percent.toDouble()] = npv;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${variable.description} Impact on NPV',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('% Change'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('NPV'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${NumberFormat.compact().format(value)}',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints.entries
                          .map((e) => FlSpot(e.key, e.value))
                          .toList()
                        ..sort((a, b) => a.x.compareTo(b.x)),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      VerticalLine(x: 0, color: Colors.grey, strokeWidth: 1, dashArray: [5, 5]),
                    ],
                    horizontalLines: [
                      HorizontalLine(y: 0, color: Colors.grey, strokeWidth: 1, dashArray: [5, 5]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAdjustedNPV(
    ProjectFinancials financials, {
    double capexFactor = 1.0,
    double opexFactor = 1.0,
    double benefitsFactor = 1.0,
  }) {
    double npv = 0;
    final discountRate = FinancialConstants.hurdleRate;

    for (int i = 0; i < financials.projectionYears; i++) {
      final year = financials.startYear + i;
      final capex = financials.getCapExForYear(year) * capexFactor;
      final opex = financials.getOpExForYear(year) * opexFactor;
      final benefits = financials.getBenefitsForYear(year) * benefitsFactor;
      final cashFlow = benefits - capex - opex;
      npv += cashFlow / pow(1 + discountRate, i + 1);
    }

    return npv;
  }
}
