import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/project.dart';
import '../../../data/models/financial_items.dart';
import '../../../providers/providers.dart';
import '../../../services/pdf_export_service.dart';
import '../../widgets/comments_section.dart';
import '../../widgets/attachments_section.dart';

class AnalysisDashboardScreen extends ConsumerWidget {
  final String projectId;

  const AnalysisDashboardScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return projectAsync.when(
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Analysis Dashboard'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/projects'),
              ),
            ),
            body: const Center(child: Text('Project not found')),
          );
        }
        return _DashboardScaffold(project: project);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Analysis Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Analysis Dashboard')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DashboardScaffold extends ConsumerWidget {
  final Project project;

  const _DashboardScaffold({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialsAsync = ref.watch(projectFinancialsProvider((
      projectId: project.id,
      startYear: project.startYear,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/projects'),
        ),
        actions: [
          if (ref.watch(canViewExecutiveDashboardProvider))
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => context.go('/executive'),
              tooltip: 'Executive Dashboard',
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.go('/help/metrics'),
            tooltip: 'Metrics Guide',
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () => context.go('/project/${project.id}/financials'),
            tooltip: 'Edit Financials',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/project/${project.id}'),
            tooltip: 'Edit Project',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: financialsAsync.whenOrNull(
              data: (financials) => () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF...')),
                );
                try {
                  await PdfExportService.exportProject(
                    project: project,
                    financials: financials,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error exporting PDF: $e')),
                    );
                  }
                }
              },
            ),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: financialsAsync.when(
        data: (financials) => _DashboardBody(project: project, financials: financials),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading financials: $e')),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Project project;
  final ProjectFinancials financials;

  const _DashboardBody({required this.project, required this.financials});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProjectHeader(project: project),
          const SizedBox(height: 24),
          if (!financials.hasData)
            _NoDataCard(projectId: project.id)
          else ...[
            _KeyMetricsRow(financials: financials),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _CashFlowChart(financials: financials, startYear: project.startYear),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _CostBreakdownCard(financials: financials),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ProjectDetailsCard(project: project)),
              const SizedBox(width: 24),
              Expanded(child: _TimelineCard(project: project)),
            ],
          ),
          if (financials.hasData) ...[
            const SizedBox(height: 24),
            _YearlyBreakdownTable(financials: financials, startYear: project.startYear),
            if (financials.hasActualsData) ...[
              const SizedBox(height: 24),
              _VarianceSummarySection(financials: financials, startYear: project.startYear),
            ],
          ],
          const SizedBox(height: 24),
          // Collaboration Section
          _CollaborationSection(projectId: project.id, projectName: project.projectName),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// Collaboration section with Comments and Attachments
class _CollaborationSection extends StatelessWidget {
  final String projectId;
  final String projectName;

  const _CollaborationSection({
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collaboration',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CommentsSection(
                projectId: projectId,
                projectName: projectName,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: AttachmentsSection(
                projectId: projectId,
                projectName: projectName,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoDataCard extends StatelessWidget {
  final String projectId;

  const _NoDataCard({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Financial Data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add CapEx, OpEx, and Benefits to see financial analysis',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/project/$projectId/financials'),
                icon: const Icon(Icons.add),
                label: const Text('Add Financial Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final Project project;

  const _ProjectHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          project.pfrNumber,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: project.statusHistory.isNotEmpty
                            ? 'Latest: ${project.statusHistory.last.note}'
                            : 'No status notes',
                        child: _StatusChip(status: project.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.projectName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${project.segment} / ${project.businessUnitGroup} / ${project.businessUnit}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Currency',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                Text(
                  project.currency,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ProjectStatus.draft:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        break;
      case ProjectStatus.submitted:
      case ProjectStatus.pendingApproval:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case ProjectStatus.approved:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case ProjectStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case ProjectStatus.onHold:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case ProjectStatus.cancelled:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KeyMetricsRow extends StatelessWidget {
  final ProjectFinancials financials;

  const _KeyMetricsRow({required this.financials});

  void _showNPVDrillDown(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final rate = FinancialConstants.hurdleRate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green),
            SizedBox(width: 12),
            Text('NPV Breakdown'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Cash Flow', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Present Value', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...List.generate(financials.projectionYears, (i) {
                      final year = financials.startYear + i;
                      final cashFlow = financials.getNetCashFlowForYear(year);
                      final discountFactor = math.pow(1 + rate, i + 1);
                      final presentValue = cashFlow / discountFactor;
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('$year')),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(cashFlow), style: TextStyle(color: cashFlow >= 0 ? Colors.green[700] : Colors.red[700]))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('÷ ${discountFactor.toStringAsFixed(2)}')),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(presentValue), style: TextStyle(color: presentValue >= 0 ? Colors.green[700] : Colors.red[700]))),
                        ],
                      );
                    }),
                    TableRow(
                      decoration: BoxDecoration(color: Colors.blue[50]),
                      children: [
                        const Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Padding(padding: EdgeInsets.all(8), child: Text('')),
                        const Padding(padding: EdgeInsets.all(8), child: Text('')),
                        Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(financials.calculateNPV(rate)), style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showIRRDrillDown(BuildContext context) {
    final irr = financials.calculateIRR();
    final hurdleRate = FinancialConstants.hurdleRate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.percent, color: Colors.blue),
            SizedBox(width: 12),
            Text('IRR Analysis'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Project IRR:'),
                        Text(
                          irr != null ? '${(irr * 100).toStringAsFixed(2)}%' : 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: irr != null && irr >= hurdleRate ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hurdle Rate:'),
                        Text(
                          '${(hurdleRate * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Spread:'),
                        Text(
                          irr != null ? '${((irr - hurdleRate) * 100).toStringAsFixed(2)}%' : 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: irr != null && irr >= hurdleRate ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (irr != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: irr >= hurdleRate ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: irr >= hurdleRate ? Colors.green : Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        irr >= hurdleRate ? Icons.check_circle : Icons.warning,
                        color: irr >= hurdleRate ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          irr >= hurdleRate
                              ? 'Project exceeds the required rate of return'
                              : 'Project is below the required rate of return',
                          style: TextStyle(color: irr >= hurdleRate ? Colors.green[800] : Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPaybackDrillDown(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final cumulative = financials.yearlyCumulative;
    final paybackMonths = financials.calculatePaybackMonths();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange),
            SizedBox(width: 12),
            Text('Payback Timeline'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Net Cash Flow', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Cumulative', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...List.generate(financials.projectionYears, (i) {
                      final year = financials.startYear + i;
                      final netCashFlow = financials.getNetCashFlowForYear(year);
                      final cumulativeValue = cumulative[i];
                      final isPaidBack = cumulativeValue >= 0;
                      return TableRow(
                        decoration: isPaidBack ? BoxDecoration(color: Colors.green[50]) : null,
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('$year')),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(netCashFlow), style: TextStyle(color: netCashFlow >= 0 ? Colors.green[700] : Colors.red[700]))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(cumulativeValue), style: TextStyle(color: cumulativeValue >= 0 ? Colors.green[700] : Colors.red[700]))),
                          Padding(padding: const EdgeInsets.all(8), child: Icon(isPaidBack ? Icons.check_circle : Icons.remove_circle_outline, color: isPaidBack ? Colors.green : Colors.grey, size: 18)),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          paybackMonths != null
                              ? 'Payback achieved in ${paybackMonths ~/ 12} years and ${paybackMonths % 12} months'
                              : 'Payback not achieved within projection period',
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showInvestmentDrillDown(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Group CapEx by category
    final capexByCategory = <CapExCategory, double>{};
    for (final item in financials.capexItems) {
      capexByCategory[item.category] = (capexByCategory[item.category] ?? 0) + item.totalAmount;
    }

    // Group OpEx by category
    final opexByCategory = <OpExCategory, double>{};
    for (final item in financials.opexItems) {
      opexByCategory[item.category] = (opexByCategory[item.category] ?? 0) + item.totalAmount;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.indigo),
            SizedBox(width: 12),
            Text('Investment Breakdown'),
          ],
        ),
        content: SizedBox(
          width: 550,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total CapEx', style: TextStyle(color: Colors.grey)),
                          Text(currencyFormat.format(financials.totalCapEx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const Text('+', style: TextStyle(fontSize: 24, color: Colors.grey)),
                      Column(
                        children: [
                          const Text('Total OpEx', style: TextStyle(color: Colors.grey)),
                          Text(currencyFormat.format(financials.totalOpEx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const Text('=', style: TextStyle(fontSize: 24, color: Colors.grey)),
                      Column(
                        children: [
                          const Text('Total', style: TextStyle(color: Colors.grey)),
                          Text(currencyFormat.format(financials.totalCosts), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // CapEx breakdown
                Text('Capital Expenditures (CapEx)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (capexByCategory.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No CapEx items', style: TextStyle(color: Colors.grey)))
                else
                  ...capexByCategory.entries.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2, size: 20),
                    title: Text(e.key.displayName),
                    trailing: Text(currencyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
                const Divider(height: 32),
                // OpEx breakdown
                Text('Operating Expenditures (OpEx)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (opexByCategory.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No OpEx items', style: TextStyle(color: Colors.grey)))
                else
                  ...opexByCategory.entries.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.repeat, size: 20),
                    title: Text(e.key.displayName),
                    trailing: Text(currencyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
                const Divider(height: 32),
                // Year-by-year breakdown
                Text('Year-by-Year Costs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('CapEx', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('OpEx', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ...List.generate(financials.projectionYears, (i) {
                      final year = financials.startYear + i;
                      final capex = financials.getCapExForYear(year);
                      final opex = financials.getOpExForYear(year);
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('$year')),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(capex))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(opex))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(currencyFormat.format(capex + opex), style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final npv = financials.calculateNPV(FinancialConstants.hurdleRate);
    final irr = financials.calculateIRR();
    final paybackMonths = financials.calculatePaybackMonths();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Net Present Value',
            value: currencyFormat.format(npv),
            subtitle: 'At ${(FinancialConstants.hurdleRate * 100).toInt()}% hurdle rate',
            icon: Icons.trending_up,
            color: npv >= 0 ? Colors.green : Colors.red,
            formula: 'NPV = Σ (Cash Flow / (1 + r)^t)',
            explanation: 'Net Present Value represents the total value of all future cash flows, '
                'discounted back to today\'s dollars using the ${(FinancialConstants.hurdleRate * 100).toInt()}% hurdle rate. '
                'It accounts for the time value of money.',
            interpretation: const [
              'NPV > 0: Project creates value - GOOD',
              'NPV = 0: Project breaks even',
              'NPV < 0: Project destroys value - CAUTION',
            ],
            onTap: () => _showNPVDrillDown(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Internal Rate of Return',
            value: irr != null ? '${(irr * 100).toStringAsFixed(1)}%' : 'N/A',
            subtitle: irr != null && irr >= FinancialConstants.hurdleRate
                ? 'Above hurdle rate'
                : 'Below hurdle rate',
            icon: Icons.percent,
            color: irr != null && irr >= FinancialConstants.hurdleRate ? Colors.green : Colors.orange,
            formula: 'Find r where: Σ (Cash Flow / (1 + r)^t) = 0',
            explanation: 'Internal Rate of Return is the discount rate that makes the NPV equal to zero. '
                'Think of it as the "interest rate" the project earns on invested capital. '
                'Calculated using the Newton-Raphson iterative method.',
            interpretation: [
              'IRR > ${(FinancialConstants.hurdleRate * 100).toInt()}%: Exceeds hurdle rate - GOOD',
              'IRR = ${(FinancialConstants.hurdleRate * 100).toInt()}%: Meets minimum requirement',
              'IRR < ${(FinancialConstants.hurdleRate * 100).toInt()}%: Below hurdle rate - CAUTION',
              'N/A: Cannot calculate (no sign change in cash flows)',
            ],
            onTap: () => _showIRRDrillDown(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Payback Period',
            value: paybackMonths != null
                ? '${paybackMonths ~/ 12}y ${paybackMonths % 12}m'
                : 'N/A',
            subtitle: 'Simple payback',
            icon: Icons.access_time,
            color: paybackMonths != null && paybackMonths <= 36 ? Colors.green : Colors.orange,
            formula: 'Find t where: Cumulative Cash Flow >= 0',
            explanation: 'The payback period is the time it takes for cumulative cash flows to equal zero - '
                'essentially, how long until you "get your money back." This is a simple (non-discounted) calculation.',
            interpretation: const [
              'Under 36 months (3 years): Quick payback - GOOD',
              '36-60 months: Moderate payback',
              'Over 60 months: Slow payback - CAUTION',
              'N/A: No payback within projection period',
            ],
            onTap: () => _showPaybackDrillDown(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Total Investment',
            value: currencyFormat.format(financials.totalCosts),
            subtitle: 'CapEx + OpEx',
            icon: Icons.account_balance_wallet,
            color: Theme.of(context).colorScheme.primary,
            formula: 'Total = CapEx + OpEx (all ${FinancialConstants.projectionYears} years)',
            explanation: 'Total Investment is the sum of all Capital Expenditures (one-time costs like equipment, '
                'software, infrastructure) and Operating Expenditures (ongoing costs like maintenance, licenses, labor) '
                'over the ${FinancialConstants.projectionYears}-year projection period.',
            interpretation: const [
              'Compare against budget allocations',
              'Review cost breakdown for CapEx vs OpEx ratio',
              'Consider phasing of costs across years',
            ],
            onTap: () => _showInvestmentDrillDown(context),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? formula;
  final String? explanation;
  final List<String>? interpretation;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.formula,
    this.explanation,
    this.interpretation,
    this.onTap,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (explanation != null) ...[
                Text(
                  explanation!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if (formula != null) ...[
                Text(
                  'Formula',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formula!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (interpretation != null && interpretation!.isNotEmpty) ...[
                Text(
                  'Interpretation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...interpretation!.map((item) {
                  Color? textColor;
                  IconData itemIcon = Icons.circle;
                  if (item.contains('GOOD') || item.contains('good')) {
                    textColor = Colors.green[700];
                    itemIcon = Icons.check_circle;
                  } else if (item.contains('CAUTION') || item.contains('caution') || item.contains('AVOID')) {
                    textColor = Colors.orange[700];
                    itemIcon = Icons.warning;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(itemIcon, size: 16, color: textColor ?? Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item, style: TextStyle(color: textColor))),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInfo = formula != null || explanation != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (hasInfo)
                    InkWell(
                      onTap: () => _showInfoDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final ProjectFinancials financials;
  final int startYear;

  const _CashFlowChart({required this.financials, required this.startYear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final costs = financials.yearlyCosts;
    final benefits = financials.yearlyBenefits;
    final netCashFlow = financials.yearlyNetCashFlow;

    // Calculate the actual min/max values that will be displayed on the chart
    // Costs are displayed as negative, so we need to consider -costs[i]
    // Net cash flow can also be negative
    final maxCost = costs.isEmpty ? 0.0 : costs.reduce((a, b) => a > b ? a : b);
    final maxBenefit = benefits.isEmpty ? 0.0 : benefits.reduce((a, b) => a > b ? a : b);
    final minNetCashFlow = netCashFlow.isEmpty ? 0.0 : netCashFlow.reduce((a, b) => a < b ? a : b);
    final maxNetCashFlow = netCashFlow.isEmpty ? 0.0 : netCashFlow.reduce((a, b) => a > b ? a : b);

    // maxY is the highest positive value (benefits or positive net cash flow)
    final maxPositive = [maxBenefit, maxNetCashFlow, 100.0].reduce((a, b) => a > b ? a : b);
    final maxY = (maxPositive * 1.2).ceilToDouble();

    // minY is the lowest negative value (negated costs or negative net cash flow)
    final minNegative = [-maxCost, minNetCashFlow, -100.0].reduce((a, b) => a < b ? a : b);
    final minY = (minNegative * 1.2).floorToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Flow Analysis',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendItem(color: Colors.red[400]!, label: 'Costs'),
                const SizedBox(width: 24),
                _LegendItem(color: Colors.green[400]!, label: 'Benefits'),
                const SizedBox(width: 24),
                _LegendItem(color: theme.colorScheme.primary, label: 'Net Cash Flow'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: minY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label;
                        switch (rodIndex) {
                          case 0:
                            label = 'Costs';
                            break;
                          case 1:
                            label = 'Benefits';
                            break;
                          case 2:
                            label = 'Net';
                            break;
                          default:
                            label = '';
                        }
                        return BarTooltipItem(
                          '$label\n\$${NumberFormat.compact().format(rod.toY.abs())}',
                          const TextStyle(color: Colors.white),
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
                          final year = startYear + value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              year.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${NumberFormat.compact().format(value)}',
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
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(FinancialConstants.projectionYears, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: -costs[i], // Negate for display (costs are positive, display as negative)
                          color: Colors.red[400],
                          width: 16,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: benefits[i],
                          color: Colors.green[400],
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: netCashFlow[i],
                          color: const Color(0xFF1E3A5F),
                          width: 16,
                          borderRadius: BorderRadius.vertical(
                            top: netCashFlow[i] >= 0 ? const Radius.circular(4) : Radius.zero,
                            bottom: netCashFlow[i] < 0 ? const Radius.circular(4) : Radius.zero,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CostBreakdownCard extends StatelessWidget {
  final ProjectFinancials financials;

  const _CostBreakdownCard({required this.financials});

  void _showCapExDrillDown(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Group by category
    final byCategory = <CapExCategory, List<CapExItem>>{};
    for (final item in financials.capexItems) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            const Text('CapEx Breakdown'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total CapEx:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(financials.totalCapEx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (byCategory.isEmpty)
                  const Center(child: Text('No CapEx items', style: TextStyle(color: Colors.grey)))
                else
                  ...byCategory.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(entry.key.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...entry.value.map((item) => ListTile(
                      dense: true,
                      title: Text(item.description),
                      trailing: Text(currencyFormat.format(item.totalAmount)),
                    )),
                    const Divider(),
                  ]),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _showOpExDrillDown(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Group by category
    final byCategory = <OpExCategory, List<OpExItem>>{};
    for (final item in financials.opexItems) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            const Text('OpEx Breakdown'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total OpEx:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(financials.totalOpEx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (byCategory.isEmpty)
                  const Center(child: Text('No OpEx items', style: TextStyle(color: Colors.grey)))
                else
                  ...byCategory.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(entry.key.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...entry.value.map((item) => ListTile(
                      dense: true,
                      title: Text(item.description),
                      trailing: Text(currencyFormat.format(item.totalAmount)),
                    )),
                    const Divider(),
                  ]),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _showBenefitsDrillDown(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Group by category
    final byCategory = <BenefitCategory, List<BenefitItem>>{};
    for (final item in financials.benefitItems) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green),
            SizedBox(width: 12),
            Text('Benefits Breakdown'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Benefits:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(financials.totalBenefits), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[700])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (byCategory.isEmpty)
                  const Center(child: Text('No Benefit items', style: TextStyle(color: Colors.grey)))
                else
                  ...byCategory.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(entry.key.displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...entry.value.map((item) => ListTile(
                      dense: true,
                      title: Text(item.description),
                      subtitle: Text(item.businessUnit.displayName),
                      trailing: Text(currencyFormat.format(item.totalAmount), style: TextStyle(color: Colors.green[700])),
                    )),
                    const Divider(),
                  ]),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Click items below for details',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (financials.totalCosts > 0)
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response?.touchedSection != null) {
                          final index = response!.touchedSection!.touchedSectionIndex;
                          if (index == 0) {
                            _showCapExDrillDown(context);
                          } else if (index == 1) {
                            _showOpExDrillDown(context);
                          }
                        }
                      },
                    ),
                    sections: [
                      PieChartSectionData(
                        value: financials.totalCapEx,
                        title: 'CapEx\n${financials.capExPercent}%',
                        color: theme.colorScheme.primary,
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      PieChartSectionData(
                        value: financials.totalOpEx,
                        title: 'OpEx\n${financials.opExPercent}%',
                        color: theme.colorScheme.secondary,
                        radius: 80,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Center(
                  child: Text('No cost data', style: TextStyle(color: Colors.grey[500])),
                ),
              ),
            const SizedBox(height: 24),
            _ClickableCostRow(label: 'Capital Expenditure', value: currencyFormat.format(financials.totalCapEx), color: theme.colorScheme.primary, onTap: () => _showCapExDrillDown(context)),
            const SizedBox(height: 12),
            _ClickableCostRow(label: 'Operating Expenditure', value: currencyFormat.format(financials.totalOpEx), color: theme.colorScheme.secondary, onTap: () => _showOpExDrillDown(context)),
            const Divider(height: 24),
            _ClickableCostRow(label: 'Total Benefits', value: currencyFormat.format(financials.totalBenefits), color: Colors.green, onTap: () => _showBenefitsDrillDown(context)),
          ],
        ),
      ),
    );
  }
}

class _ClickableCostRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ClickableCostRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetailsCard extends StatelessWidget {
  final Project project;

  const _ProjectDetailsCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (project.description != null && project.description!.isNotEmpty) ...[
              Text('Description', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(project.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (project.rationale != null && project.rationale!.isNotEmpty) ...[
              Text('Business Rationale', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(project.rationale!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 16),
            _DetailRow(label: 'Initiative Sponsor', value: project.initiativeSponsor ?? 'Not specified'),
            _DetailRow(label: 'Executive Sponsor', value: project.executiveSponsor ?? 'Not specified'),
            _DetailRow(label: 'Project Requester', value: project.projectRequester ?? 'Not specified'),
            if (project.icCategory != null)
              _DetailRow(label: 'IC Category', value: project.icCategory!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final Project project;

  const _TimelineCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline & Flags',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _TimelineRow(
              icon: Icons.play_arrow,
              label: 'Project Start',
              value: dateFormat.format(project.projectStartDate),
              color: Colors.green,
            ),
            _TimelineRow(
              icon: Icons.stop,
              label: 'Project End',
              value: dateFormat.format(project.projectEndDate),
              color: Colors.red,
            ),
            if (project.benefitStartDate != null)
              _TimelineRow(
                icon: Icons.trending_up,
                label: 'Benefit Start',
                value: dateFormat.format(project.benefitStartDate!),
                color: Colors.blue,
              ),
            const Divider(height: 24),
            Text('Flags', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (project.isCapExBudgeted) _FlagChip(label: 'CapEx Budgeted', active: true),
                if (project.isOpExBudgeted) _FlagChip(label: 'OpEx Budgeted', active: true),
                if (project.replacesCurrentAssets) _FlagChip(label: 'Replaces Assets', active: true),
                if (project.isHoaReimbursed) _FlagChip(label: 'HOA Reimbursed', active: true),
                if (project.hasGuaranteedMarketing) _FlagChip(label: 'Guaranteed Marketing', active: true),
                if (project.hasLongTermCommitment) _FlagChip(label: 'Long-Term Commitment', active: true),
                if (project.hasRealEstateLease) _FlagChip(label: 'Real Estate Lease', active: true),
                if (project.hasEquipmentLease) _FlagChip(label: 'Equipment Lease', active: true),
                if (!project.isCapExBudgeted && !project.isOpExBudgeted && !project.replacesCurrentAssets &&
                    !project.isHoaReimbursed && !project.hasGuaranteedMarketing && !project.hasLongTermCommitment &&
                    !project.hasRealEstateLease && !project.hasEquipmentLease)
                  Text('No flags set', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final bool active;

  const _FlagChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.blue[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? Colors.blue[200]! : Colors.grey[400]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.blue[800] : Colors.grey[600],
        ),
      ),
    );
  }
}

class _YearlyBreakdownTable extends StatelessWidget {
  final ProjectFinancials financials;
  final int startYear;

  const _YearlyBreakdownTable({required this.financials, required this.startYear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yearly Financial Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columns: [
                  const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  ...List.generate(
                    FinancialConstants.projectionYears,
                    (i) => DataColumn(
                      label: Text(
                        '${startYear + i}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                  ),
                  const DataColumn(
                    label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                ],
                rows: [
                  _buildDataRow('CapEx', financials.yearlyCapEx, currencyFormat, Colors.red[700]!),
                  _buildDataRow('OpEx', financials.yearlyOpEx, currencyFormat, Colors.orange[700]!),
                  _buildDataRow('Total Costs', financials.yearlyCosts, currencyFormat, Colors.red[900]!),
                  _buildDataRow('Benefits', financials.yearlyBenefits, currencyFormat, Colors.green[700]!),
                  _buildDataRow('Net Cash Flow', financials.yearlyNetCashFlow, currencyFormat, theme.colorScheme.primary, bold: true),
                  _buildDataRow('Cumulative', financials.yearlyCumulative, currencyFormat, Colors.purple[700]!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(String label, List<double> values, NumberFormat format, Color color, {bool bold = false}) {
    final total = values.fold(0.0, (sum, v) => sum + v);
    return DataRow(
      cells: [
        DataCell(Text(label, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null))),
        ...values.map((v) => DataCell(
          Text(
            format.format(v),
            style: TextStyle(
              color: v < 0 ? Colors.red : null,
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
        )),
        DataCell(Text(
          format.format(total),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        )),
      ],
    );
  }
}

class _VarianceSummarySection extends StatelessWidget {
  final ProjectFinancials financials;
  final int startYear;

  const _VarianceSummarySection({required this.financials, required this.startYear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Budget vs Actuals',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Variance Summary Cards
            Row(
              children: [
                Expanded(
                  child: _VarianceCard(
                    title: 'Cost Variance',
                    budget: financials.totalCosts,
                    actual: financials.totalActualCosts,
                    variance: financials.totalCostVariance,
                    isCost: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _VarianceCard(
                    title: 'Benefit Variance',
                    budget: financials.totalBenefits,
                    actual: financials.totalActualBenefits,
                    variance: financials.totalBenefitVariance,
                    isCost: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Variance Detail Table
            Text(
              'Yearly Variance Detail',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                columnSpacing: 16,
                columns: [
                  const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  ...List.generate(
                    FinancialConstants.projectionYears,
                    (i) => DataColumn(
                      label: Text('${startYear + i}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                  ),
                  const DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: [
                  _buildCategoryRow('CapEx', 'Budget', financials.yearlyCapEx, currencyFormat),
                  _buildCategoryRow('', 'Actual', financials.yearlyActualCapEx, currencyFormat),
                  _buildVarianceRow('', 'Variance', financials.yearlyCapEx, financials.yearlyActualCapEx, currencyFormat, isCost: true),
                  _buildCategoryRow('OpEx', 'Budget', financials.yearlyOpEx, currencyFormat),
                  _buildCategoryRow('', 'Actual', financials.yearlyActualOpEx, currencyFormat),
                  _buildVarianceRow('', 'Variance', financials.yearlyOpEx, financials.yearlyActualOpEx, currencyFormat, isCost: true),
                  _buildCategoryRow('Benefits', 'Budget', financials.yearlyBenefits, currencyFormat),
                  _buildCategoryRow('', 'Actual', financials.yearlyActualBenefits, currencyFormat),
                  _buildVarianceRow('', 'Variance', financials.yearlyBenefits, financials.yearlyActualBenefits, currencyFormat, isCost: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildCategoryRow(String category, String type, List<double> values, NumberFormat format) {
    final total = values.fold(0.0, (sum, v) => sum + v);
    return DataRow(cells: [
      DataCell(Text(category, style: TextStyle(fontWeight: category.isNotEmpty ? FontWeight.bold : null))),
      DataCell(Text(type)),
      ...values.map((v) => DataCell(Text(format.format(v)))),
      DataCell(Text(format.format(total), style: const TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }

  DataRow _buildVarianceRow(String category, String type, List<double> budgets, List<double> actuals,
      NumberFormat format, {required bool isCost}) {
    final variances = List.generate(budgets.length, (i) {
      return isCost ? (budgets[i] - actuals[i]) : (actuals[i] - budgets[i]);
    });
    final totalVariance = variances.fold(0.0, (sum, v) => sum + v);

    return DataRow(cells: [
      DataCell(Text(category)),
      DataCell(Text(type, style: const TextStyle(fontStyle: FontStyle.italic))),
      ...variances.map((v) => DataCell(Text(
        '${v >= 0 ? '+' : ''}${format.format(v)}',
        style: TextStyle(
          color: v >= 0 ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ))),
      DataCell(Text(
        '${totalVariance >= 0 ? '+' : ''}${format.format(totalVariance)}',
        style: TextStyle(
          color: totalVariance >= 0 ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      )),
    ]);
  }
}

class _VarianceCard extends StatelessWidget {
  final String title;
  final double budget;
  final double actual;
  final double variance;
  final bool isCost;

  const _VarianceCard({
    required this.title,
    required this.budget,
    required this.actual,
    required this.variance,
    required this.isCost,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final variancePercent = budget > 0 ? (variance / budget * 100) : 0.0;
    final isFavorable = variance >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFavorable ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFavorable ? Colors.green[300]! : Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFavorable ? Icons.trending_up : Icons.trending_down,
                color: isFavorable ? Colors.green[700] : Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text(currencyFormat.format(budget), style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actual', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text(currencyFormat.format(actual), style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Variance', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text(
                    '${variance >= 0 ? '+' : ''}${currencyFormat.format(variance)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isFavorable ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    '${variancePercent >= 0 ? '+' : ''}${variancePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: isFavorable ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
