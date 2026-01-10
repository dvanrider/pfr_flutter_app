import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/project.dart';
import '../../../providers/providers.dart';

/// Executive Dashboard - Main screen for executive users
/// Shows comprehensive organization-wide metrics and analytics
class ExecutiveDashboardScreen extends ConsumerWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);
    final configAsync = ref.watch(systemConfigProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Dashboard'),
        actions: [
          if (user != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business_center, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    userProfile?.role.displayName.toUpperCase() ?? 'EXECUTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  user.displayName ?? user.email ?? 'User',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  (user.displayName ?? user.email ?? 'E')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onSelected: (value) async {
                if (value == 'signout') {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.signOut();
                  // Invalidate cached providers to ensure fresh data on next login
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) {
                    context.go('/login');
                  }
                } else if (value == 'home') {
                  context.go('/');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Executive',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'home',
                  child: Row(
                    children: [
                      Icon(Icons.home, size: 20),
                      SizedBox(width: 8),
                      Text('Home'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Overview',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time metrics and portfolio analytics',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // Last updated indicator
                configAsync.when(
                  data: (config) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Config: ${DateFormat('MMM dd, HH:mm').format(config.updatedAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Key Financial Metrics
            projectsAsync.when(
              data: (projects) => _buildKeyMetrics(context, projects, currencyFormat),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 32),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Projects by Status
                Expanded(
                  child: _ChartCard(
                    title: 'Projects by Status',
                    child: projectsAsync.when(
                      data: (projects) => _buildStatusPieChart(context, projects),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Projects by Segment
                Expanded(
                  child: _ChartCard(
                    title: 'Projects by Segment',
                    child: projectsAsync.when(
                      data: (projects) => _buildSegmentPieChart(context, projects),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Projects by IC Category
                Expanded(
                  child: _ChartCard(
                    title: 'Projects by Category',
                    child: projectsAsync.when(
                      data: (projects) => _buildCategoryPieChart(context, projects),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Approval Pipeline
            Text('Approval Pipeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            projectsAsync.when(
              data: (projects) => _buildApprovalPipeline(context, projects, currencyFormat),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 32),

            // Configuration & User Summary Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Configuration Summary
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text('System Configuration', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const Divider(height: 24),
                          configAsync.when(
                            data: (config) => Column(
                              children: [
                                _ConfigRow(label: 'Hurdle Rate (IRR)', value: '${(config.hurdleRate * 100).toStringAsFixed(0)}%'),
                                _ConfigRow(label: 'Projection Years', value: '${config.projectionYears} years'),
                                _ConfigRow(label: 'Contingency Rate', value: '${(config.contingencyRate * 100).toStringAsFixed(0)}%'),
                                _ConfigRow(
                                  label: 'Auto-Approve Threshold',
                                  value: config.autoApproveThreshold > 0
                                      ? currencyFormat.format(config.autoApproveThreshold)
                                      : 'Disabled',
                                ),
                                _ConfigRow(label: 'Approval Levels', value: '${config.approvalChain.length} levels'),
                              ],
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // User Summary
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text('User Statistics', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const Divider(height: 24),
                          usersAsync.when(
                            data: (users) {
                              final activeCount = users.where((u) => u.isActive).length;
                              final adminCount = users.where((u) => u.role == UserRole.admin).length;
                              final execCount = users.where((u) => u.role == UserRole.executive).length;
                              final approverCount = users.where((u) => u.role == UserRole.approver).length;
                              final requesterCount = users.where((u) => u.role == UserRole.requester).length;
                              return Column(
                                children: [
                                  _ConfigRow(label: 'Total Users', value: '${users.length}'),
                                  _ConfigRow(label: 'Active Users', value: '$activeCount'),
                                  _ConfigRow(label: 'Admins', value: '$adminCount'),
                                  _ConfigRow(label: 'Executives', value: '$execCount'),
                                  _ConfigRow(label: 'Approvers', value: '$approverCount'),
                                  _ConfigRow(label: 'Requesters', value: '$requesterCount'),
                                ],
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Analysis Tools Section
            Text('Analysis Tools', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AnalysisToolCard(
                    icon: Icons.compare_arrows,
                    title: 'Compare Projects',
                    subtitle: 'Side-by-side comparison',
                    color: Colors.teal,
                    onTap: () => context.go('/analysis/compare'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnalysisToolCard(
                    icon: Icons.trending_up,
                    title: 'Sensitivity Analysis',
                    subtitle: 'What-if scenarios',
                    color: Colors.indigo,
                    onTap: () => context.go('/analysis/sensitivity'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnalysisToolCard(
                    icon: Icons.warning_amber,
                    title: 'Risk Assessment',
                    subtitle: 'Risk scoring matrix',
                    color: Colors.deepOrange,
                    onTap: () => context.go('/analysis/risk'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Activity
            Text('Recent Projects', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            projectsAsync.when(
              data: (projects) {
                final recent = projects.take(10).toList();
                if (recent.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No projects yet')),
                    ),
                  );
                }
                return Card(
                  child: Column(
                    children: recent.map((project) {
                      return ListTile(
                        leading: _StatusIcon(status: project.status),
                        title: Text(project.projectName),
                        subtitle: Text('${project.pfrNumber} | ${project.segment} | ${project.businessUnit}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusBadge(status: project.status),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd').format(project.updatedAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        onTap: () => context.go('/project/${project.id}/analysis'),
                      );
                    }).toList(),
                  ),
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

  Widget _buildKeyMetrics(BuildContext context, List<Project> projects, NumberFormat currencyFormat) {
    final totalProjects = projects.length;
    final approvedProjects = projects.where((p) => p.status == ProjectStatus.approved).toList();
    final pendingProjects = projects.where((p) => p.status == ProjectStatus.pendingApproval || p.status == ProjectStatus.submitted).toList();
    final rejectedProjects = projects.where((p) => p.status == ProjectStatus.rejected).toList();
    final draftProjects = projects.where((p) => p.status == ProjectStatus.draft).toList();
    final approvalRate = totalProjects > 0 ? (approvedProjects.length / totalProjects * 100) : 0;

    return Row(
      children: [
        _KeyMetricCard(
          title: 'Total Projects',
          value: '$totalProjects',
          icon: Icons.folder,
          color: Colors.blue,
          onTap: projects.isNotEmpty ? () => _showProjectDrillDown(
            context: context,
            title: 'All Projects',
            projects: projects,
            color: Colors.blue,
          ) : null,
        ),
        const SizedBox(width: 16),
        _KeyMetricCard(
          title: 'Approved',
          value: '${approvedProjects.length}',
          subtitle: approvalRate > 0 ? '${approvalRate.toStringAsFixed(0)}% rate' : null,
          icon: Icons.check_circle,
          color: Colors.green,
          onTap: approvedProjects.isNotEmpty ? () => _showProjectDrillDown(
            context: context,
            title: 'Approved Projects',
            projects: approvedProjects,
            color: Colors.green,
          ) : null,
        ),
        const SizedBox(width: 16),
        _KeyMetricCard(
          title: 'Pending Approval',
          value: '${pendingProjects.length}',
          icon: Icons.hourglass_empty,
          color: Colors.orange,
          onTap: pendingProjects.isNotEmpty ? () => _showProjectDrillDown(
            context: context,
            title: 'Pending Approval',
            projects: pendingProjects,
            color: Colors.orange,
          ) : null,
        ),
        const SizedBox(width: 16),
        _KeyMetricCard(
          title: 'Rejected',
          value: '${rejectedProjects.length}',
          icon: Icons.cancel,
          color: Colors.red,
          onTap: rejectedProjects.isNotEmpty ? () => _showProjectDrillDown(
            context: context,
            title: 'Rejected Projects',
            projects: rejectedProjects,
            color: Colors.red,
          ) : null,
        ),
        const SizedBox(width: 16),
        _KeyMetricCard(
          title: 'Drafts',
          value: '${draftProjects.length}',
          icon: Icons.edit_note,
          color: Colors.grey,
          onTap: draftProjects.isNotEmpty ? () => _showProjectDrillDown(
            context: context,
            title: 'Draft Projects',
            projects: draftProjects,
            color: Colors.grey,
          ) : null,
        ),
      ],
    );
  }

  Widget _buildApprovalPipeline(BuildContext context, List<Project> projects, NumberFormat currencyFormat) {
    final submitted = projects.where((p) => p.status == ProjectStatus.submitted).toList();
    final pending = projects.where((p) => p.status == ProjectStatus.pendingApproval).toList();
    final onHold = projects.where((p) => p.status == ProjectStatus.onHold).toList();

    return Row(
      children: [
        Expanded(
          child: _PipelineCard(
            title: 'Submitted',
            count: submitted.length,
            color: Colors.blue,
            icon: Icons.send,
            onTap: submitted.isNotEmpty ? () => _showProjectDrillDown(
              context: context,
              title: 'Submitted Projects',
              projects: submitted,
              color: Colors.blue,
            ) : null,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Expanded(
          child: _PipelineCard(
            title: 'Pending Approval',
            count: pending.length,
            color: Colors.orange,
            icon: Icons.pending_actions,
            onTap: pending.isNotEmpty ? () => _showProjectDrillDown(
              context: context,
              title: 'Pending Approval',
              projects: pending,
              color: Colors.orange,
            ) : null,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Expanded(
          child: _PipelineCard(
            title: 'On Hold',
            count: onHold.length,
            color: Colors.purple,
            icon: Icons.pause_circle,
            onTap: onHold.isNotEmpty ? () => _showProjectDrillDown(
              context: context,
              title: 'Projects On Hold',
              projects: onHold,
              color: Colors.purple,
            ) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPieChart(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(child: Text('No projects'));
    }

    final statusCounts = <ProjectStatus, int>{};
    for (final project in projects) {
      statusCounts[project.status] = (statusCounts[project.status] ?? 0) + 1;
    }

    final colors = {
      ProjectStatus.draft: Colors.grey,
      ProjectStatus.submitted: Colors.blue,
      ProjectStatus.pendingApproval: Colors.orange,
      ProjectStatus.approved: Colors.green,
      ProjectStatus.rejected: Colors.red,
      ProjectStatus.onHold: Colors.purple,
      ProjectStatus.cancelled: Colors.brown,
    };

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: statusCounts.entries.map((e) {
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${e.value}',
                    color: colors[e.key] ?? Colors.grey,
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 25,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: statusCounts.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(e.key.displayName, style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSegmentPieChart(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(child: Text('No projects'));
    }

    final segmentCounts = <String, int>{};
    for (final project in projects) {
      final segment = project.segment.isNotEmpty ? project.segment : 'Unknown';
      segmentCounts[segment] = (segmentCounts[segment] ?? 0) + 1;
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: segmentCounts.entries.toList().asMap().entries.map((e) {
                  return PieChartSectionData(
                    value: e.value.value.toDouble(),
                    title: '${e.value.value}',
                    color: colors[e.key % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 25,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: segmentCounts.entries.toList().asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(e.value.key, style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(child: Text('No projects'));
    }

    final categoryCounts = <String, int>{};
    for (final project in projects) {
      final category = project.icCategory?.isNotEmpty == true ? project.icCategory! : 'Unknown';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final colors = [Colors.indigo, Colors.cyan, Colors.lime, Colors.deepOrange, Colors.blueGrey, Colors.red];

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: categoryCounts.entries.toList().asMap().entries.map((e) {
                  return PieChartSectionData(
                    value: e.value.value.toDouble(),
                    title: '${e.value.value}',
                    color: colors[e.key % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 25,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: categoryCounts.entries.toList().asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text(e.value.key, style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _KeyMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KeyMetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(icon, size: 36, color: color),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
                if (onTap != null) ...[
                  const SizedBox(height: 8),
                  Text('Tap to view', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _PipelineCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              if (onTap != null && count > 0) ...[
                const SizedBox(height: 4),
                Text('Tap to view', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AnalysisToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnalysisToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ProjectStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case ProjectStatus.draft:
        icon = Icons.edit;
        color = Colors.grey;
        break;
      case ProjectStatus.submitted:
        icon = Icons.send;
        color = Colors.blue;
        break;
      case ProjectStatus.pendingApproval:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case ProjectStatus.approved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ProjectStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case ProjectStatus.onHold:
        icon = Icons.pause_circle;
        color = Colors.purple;
        break;
      case ProjectStatus.cancelled:
        icon = Icons.block;
        color = Colors.brown;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ProjectStatus.draft:
        color = Colors.grey;
        break;
      case ProjectStatus.submitted:
      case ProjectStatus.pendingApproval:
        color = Colors.orange;
        break;
      case ProjectStatus.approved:
        color = Colors.green;
        break;
      case ProjectStatus.rejected:
        color = Colors.red;
        break;
      case ProjectStatus.onHold:
        color = Colors.purple;
        break;
      case ProjectStatus.cancelled:
        color = Colors.brown;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Drill-down dialog showing filtered projects
void _showProjectDrillDown({
  required BuildContext context,
  required String title,
  required List<Project> projects,
  required Color color,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${projects.length} project${projects.length == 1 ? '' : 's'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Project list
            Flexible(
              child: projects.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No projects in this category'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return ListTile(
                          leading: _StatusIcon(status: project.status),
                          title: Text(project.projectName),
                          subtitle: Text(
                            '${project.pfrNumber} | ${project.segment} | ${project.businessUnit}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StatusBadge(status: project.status),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(project.updatedAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/project/${project.id}/analysis');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
