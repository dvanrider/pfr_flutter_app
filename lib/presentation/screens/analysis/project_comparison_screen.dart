import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/project.dart';
import '../../../providers/providers.dart';

/// Enum for comparison metrics
enum ComparisonMetric {
  npv('NPV', 'Net Present Value'),
  irr('IRR', 'Internal Rate of Return'),
  payback('Payback', 'Payback Period'),
  totalInvestment('Investment', 'Total Investment'),
  totalBenefits('Benefits', 'Total Benefits');

  final String label;
  final String description;
  const ComparisonMetric(this.label, this.description);
}

/// Provider for selected projects to compare
final selectedProjectsProvider = StateProvider<List<String>>((ref) => []);

/// Provider for comparison sort metric
final comparisonSortMetricProvider = StateProvider<ComparisonMetric>((ref) => ComparisonMetric.npv);

/// Project Comparison Screen
class ProjectComparisonScreen extends ConsumerWidget {
  const ProjectComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final selectedIds = ref.watch(selectedProjectsProvider);
    final sortMetric = ref.watch(comparisonSortMetricProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(constraints.maxWidth);
        final isMobile = screenSize == ScreenSize.mobile;

        return Scaffold(
          appBar: AppBar(
            title: Text(isMobile ? 'Compare' : 'Project Comparison'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/projects'),
            ),
            actions: [
              if (selectedIds.isNotEmpty)
                isMobile
                    ? IconButton(
                        icon: const Icon(Icons.clear_all),
                        onPressed: () => ref.read(selectedProjectsProvider.notifier).state = [],
                        tooltip: 'Clear selection',
                      )
                    : TextButton.icon(
                        onPressed: () => ref.read(selectedProjectsProvider.notifier).state = [],
                        icon: const Icon(Icons.clear_all, color: Colors.white),
                        label: const Text('Clear', style: TextStyle(color: Colors.white)),
                      ),
            ],
          ),
          body: projectsAsync.when(
            data: (projects) => _ComparisonBody(
              projects: projects,
              selectedIds: selectedIds,
              sortMetric: sortMetric,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }
}

class _ComparisonBody extends ConsumerWidget {
  final List<Project> projects;
  final List<String> selectedIds;
  final ComparisonMetric sortMetric;

  const _ComparisonBody({
    required this.projects,
    required this.selectedIds,
    required this.sortMetric,
  });

  void _showProjectSelectionSheet(BuildContext context, WidgetRef ref, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Projects',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Choose 2-3 projects to compare',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final isSelected = selectedIds.contains(project.id);
                  final canSelect = selectedIds.length < 3 || isSelected;

                  return ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: canSelect
                          ? (value) {
                              final notifier = ref.read(selectedProjectsProvider.notifier);
                              if (value == true) {
                                notifier.state = [...selectedIds, project.id];
                              } else {
                                notifier.state = selectedIds.where((id) => id != project.id).toList();
                              }
                            }
                          : null,
                    ),
                    title: Text(
                      project.projectName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      project.pfrNumber.isNotEmpty ? project.pfrNumber : 'No PFR #',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(constraints.maxWidth);
        final isMobile = screenSize == ScreenSize.mobile;

        if (isMobile) {
          // Mobile layout - FAB to select projects, cards stacked
          return Stack(
            children: [
              selectedIds.length < 2
                  ? _EmptyComparison(isMobile: true, onSelectProjects: () => _showProjectSelectionSheet(context, ref, theme))
                  : _ComparisonView(
                      projectIds: selectedIds,
                      allProjects: projects,
                      sortMetric: sortMetric,
                      isMobile: true,
                    ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _showProjectSelectionSheet(context, ref, theme),
                  icon: const Icon(Icons.checklist),
                  label: Text('Select (${selectedIds.length})'),
                ),
              ),
            ],
          );
        }

        // Desktop layout - side panel
        return Row(
          children: [
            // Left panel - Project selection
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Projects',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose 2-3 projects to compare',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final isSelected = selectedIds.contains(project.id);
                        final canSelect = selectedIds.length < 3 || isSelected;

                        return ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: canSelect
                                ? (value) {
                                    final notifier = ref.read(selectedProjectsProvider.notifier);
                                    if (value == true) {
                                      notifier.state = [...selectedIds, project.id];
                                    } else {
                                      notifier.state = selectedIds.where((id) => id != project.id).toList();
                                    }
                                  }
                                : null,
                          ),
                          title: Text(
                            project.projectName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            project.pfrNumber.isNotEmpty ? project.pfrNumber : 'No PFR #',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          selected: isSelected,
                          selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Right panel - Comparison view
            Expanded(
              child: selectedIds.length < 2
                  ? _EmptyComparison()
                  : _ComparisonView(
                      projectIds: selectedIds,
                      allProjects: projects,
                      sortMetric: sortMetric,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyComparison extends StatelessWidget {
  final bool isMobile;
  final VoidCallback? onSelectProjects;

  const _EmptyComparison({this.isMobile = false, this.onSelectProjects});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: isMobile ? 48 : 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select at least 2 projects to compare',
              style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can select up to 3 projects for side-by-side comparison',
              style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (isMobile && onSelectProjects != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onSelectProjects,
                icon: const Icon(Icons.checklist),
                label: const Text('Select Projects'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonView extends ConsumerWidget {
  final List<String> projectIds;
  final List<Project> allProjects;
  final ComparisonMetric sortMetric;
  final bool isMobile;

  const _ComparisonView({
    required this.projectIds,
    required this.allProjects,
    required this.sortMetric,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Get selected projects
    final selectedProjects = allProjects.where((p) => projectIds.contains(p.id)).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sort options
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparison Results',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rank by: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<ComparisonMetric>(
                        value: sortMetric,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: ComparisonMetric.values.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.description),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(comparisonSortMetricProvider.notifier).state = value;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comparison Results',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Text('Rank by: '),
                    const SizedBox(width: 8),
                    SegmentedButton<ComparisonMetric>(
                      segments: ComparisonMetric.values.map((m) => ButtonSegment(
                        value: m,
                        label: Text(m.label),
                      )).toList(),
                      selected: {sortMetric},
                      onSelectionChanged: (selected) {
                        ref.read(comparisonSortMetricProvider.notifier).state = selected.first;
                      },
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Project cards - stacked on mobile, side by side on desktop
          if (isMobile)
            Column(
              children: selectedProjects.map((project) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProjectComparisonCard(
                    project: project,
                    sortMetric: sortMetric,
                    isCompact: true,
                  ),
                );
              }).toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedProjects.map((project) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _ProjectComparisonCard(
                      project: project,
                      sortMetric: sortMetric,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),

          // Ranking table
          _RankingTable(
            projectIds: projectIds,
            allProjects: allProjects,
            sortMetric: sortMetric,
            isMobile: isMobile,
          ),

          // Extra space at bottom for FAB on mobile
          if (isMobile) const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProjectComparisonCard extends ConsumerWidget {
  final Project project;
  final ComparisonMetric sortMetric;
  final bool isCompact;

  const _ProjectComparisonCard({
    required this.project,
    required this.sortMetric,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final financialsAsync = ref.watch(projectFinancialsProvider((
      projectId: project.id,
      startYear: project.startYear,
    )));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.folder, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.projectName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        project.pfrNumber.isNotEmpty ? project.pfrNumber : project.status.displayName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Financial metrics
            financialsAsync.when(
              data: (financials) {
                final npv = financials.calculateNPV(FinancialConstants.hurdleRate);
                final irr = financials.calculateIRR();
                final paybackMonths = financials.calculatePaybackMonths();

                return Column(
                  children: [
                    _MetricRow(
                      label: 'NPV',
                      value: currencyFormat.format(npv),
                      isHighlighted: sortMetric == ComparisonMetric.npv,
                      valueColor: npv >= 0 ? Colors.green : Colors.red,
                    ),
                    _MetricRow(
                      label: 'IRR',
                      value: irr != null ? '${(irr * 100).toStringAsFixed(1)}%' : 'N/A',
                      isHighlighted: sortMetric == ComparisonMetric.irr,
                      valueColor: irr != null && irr >= FinancialConstants.hurdleRate
                          ? Colors.green
                          : Colors.orange,
                    ),
                    _MetricRow(
                      label: 'Payback',
                      value: paybackMonths != null ? '$paybackMonths months' : 'N/A',
                      isHighlighted: sortMetric == ComparisonMetric.payback,
                    ),
                    const Divider(),
                    _MetricRow(
                      label: 'Total Investment',
                      value: currencyFormat.format(financials.totalCosts),
                      isHighlighted: sortMetric == ComparisonMetric.totalInvestment,
                    ),
                    _MetricRow(
                      label: 'Total Benefits',
                      value: currencyFormat.format(financials.totalBenefits),
                      isHighlighted: sortMetric == ComparisonMetric.totalBenefits,
                      valueColor: Colors.green,
                    ),
                    const Divider(),
                    _MetricRow(
                      label: 'CapEx',
                      value: currencyFormat.format(financials.totalCapEx),
                    ),
                    _MetricRow(
                      label: 'OpEx',
                      value: currencyFormat.format(financials.totalOpEx),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isHighlighted
          ? BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTable extends ConsumerWidget {
  final List<String> projectIds;
  final List<Project> allProjects;
  final ComparisonMetric sortMetric;
  final bool isMobile;

  const _RankingTable({
    required this.projectIds,
    required this.allProjects,
    required this.sortMetric,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Build ranking data
    final rankings = <_ProjectRanking>[];

    for (final projectId in projectIds) {
      final project = allProjects.firstWhere((p) => p.id == projectId);
      final financialsAsync = ref.watch(projectFinancialsProvider((
        projectId: projectId,
        startYear: project.startYear,
      )));

      financialsAsync.whenData((financials) {
        rankings.add(_ProjectRanking(
          project: project,
          npv: financials.calculateNPV(FinancialConstants.hurdleRate),
          irr: financials.calculateIRR(),
          paybackMonths: financials.calculatePaybackMonths(),
          totalInvestment: financials.totalCosts,
          totalBenefits: financials.totalBenefits,
        ));
      });
    }

    // Sort by selected metric
    rankings.sort((a, b) {
      switch (sortMetric) {
        case ComparisonMetric.npv:
          return b.npv.compareTo(a.npv);
        case ComparisonMetric.irr:
          return (b.irr ?? -999).compareTo(a.irr ?? -999);
        case ComparisonMetric.payback:
          return (a.paybackMonths ?? 999).compareTo(b.paybackMonths ?? 999);
        case ComparisonMetric.totalInvestment:
          return a.totalInvestment.compareTo(b.totalInvestment);
        case ComparisonMetric.totalBenefits:
          return b.totalBenefits.compareTo(a.totalBenefits);
      }
    });

    if (rankings.isEmpty) {
      return const SizedBox.shrink();
    }

    // On mobile, use a simplified card-based list instead of table
    if (isMobile) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rankings (by ${sortMetric.label})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...rankings.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final r = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rank == 1 ? Colors.amber.withValues(alpha: 0.15) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: rank == 1 ? Colors.amber : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: rank == 1 ? Colors.amber : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: rank == 1
                              ? const Icon(Icons.emoji_events, color: Colors.white, size: 18)
                              : Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Project info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.project.projectName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              children: [
                                Text(
                                  currencyFormat.format(r.npv),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: r.npv >= 0 ? Colors.green[700] : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  r.irr != null ? '${(r.irr! * 100).toStringAsFixed(1)}%' : 'IRR N/A',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  r.paybackMonths != null ? '${r.paybackMonths}mo' : 'N/A',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // Desktop table view
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Rankings (by ${sortMetric.description})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(50),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Project', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('NPV', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('IRR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Payback', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...rankings.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final r = entry.value;
                  return TableRow(
                    decoration: rank == 1
                        ? BoxDecoration(color: Colors.amber.withValues(alpha: 0.2))
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (rank == 1)
                              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                            if (rank != 1) Text('#$rank'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r.project.projectName),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          currencyFormat.format(r.npv),
                          style: TextStyle(color: r.npv >= 0 ? Colors.green : Colors.red),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r.irr != null ? '${(r.irr! * 100).toStringAsFixed(1)}%' : 'N/A'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r.paybackMonths != null ? '${r.paybackMonths} mo' : 'N/A'),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectRanking {
  final Project project;
  final double npv;
  final double? irr;
  final int? paybackMonths;
  final double totalInvestment;
  final double totalBenefits;

  _ProjectRanking({
    required this.project,
    required this.npv,
    this.irr,
    this.paybackMonths,
    required this.totalInvestment,
    required this.totalBenefits,
  });
}
