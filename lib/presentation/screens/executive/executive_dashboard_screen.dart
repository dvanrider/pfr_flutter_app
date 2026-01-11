import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/project.dart';
import '../../../providers/providers.dart';
import '../../widgets/dashboard_widgets.dart';

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

    // Check screen size for AppBar responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileAppBar = screenWidth < Breakpoints.mobile;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMobileAppBar ? 'Executive' : 'Executive Dashboard'),
        actions: [
          // Theme toggle button
          Consumer(
            builder: (context, ref, _) {
              final currentTheme = ref.watch(themeModeProvider);
              return IconButton(
                icon: Icon(currentTheme.icon),
                tooltip: 'Theme: ${currentTheme.displayName}',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).cycleTheme();
                },
              );
            },
          ),
          if (user != null) ...[
            // Only show role badge on larger screens
            if (!isMobileAppBar)
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
            // Only show username on larger screens
            if (!isMobileAppBar)
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
                radius: isMobileAppBar ? 16 : 20,
                child: Text(
                  (user.displayName ?? user.email ?? 'E')[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: isMobileAppBar ? 12 : 14),
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
                      Row(
                        children: [
                          Text(
                            user.displayName ?? 'Executive',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              userProfile?.role.displayName ?? 'Executive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = getScreenSize(constraints.maxWidth);
          final padding = getResponsivePadding(screenSize);
          final spacing = getResponsiveSpacing(screenSize);
          final largeSpacing = getResponsiveLargeSpacing(screenSize);
          final isMobileView = screenSize == ScreenSize.mobile;
          final isCompact = isMobileView;
          final availableWidth = constraints.maxWidth - (padding * 2);

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (isMobileView)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time metrics and portfolio analytics',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      configAsync.when(
                        data: (config) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.update, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                'Config: ${DateFormat('MMM dd, HH:mm').format(config.updatedAt)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  )
                else
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
                SizedBox(height: largeSpacing),

                // Key Financial Metrics
                projectsAsync.when(
                  data: (projects) => buildKeyMetricsRow(
                    context: context,
                    projects: projects,
                    screenSize: screenSize,
                    availableWidth: availableWidth,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                SizedBox(height: largeSpacing),

                // Charts Row - Stack on mobile, Row on desktop
                if (isMobileView)
                  Column(
                    children: [
                      ChartCard(
                        title: 'Projects by Status',
                        child: projectsAsync.when(
                          data: (projects) => buildStatusPieChart(context, projects, isCompact: isCompact),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ),
                      SizedBox(height: spacing),
                      ChartCard(
                        title: 'Projects by Segment',
                        child: projectsAsync.when(
                          data: (projects) => buildSegmentPieChart(context, projects, isCompact: isCompact),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ),
                      SizedBox(height: spacing),
                      ChartCard(
                        title: 'Projects by Category',
                        child: projectsAsync.when(
                          data: (projects) => buildCategoryPieChart(context, projects, isCompact: isCompact),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ChartCard(
                          title: 'Projects by Status',
                          child: projectsAsync.when(
                            data: (projects) => buildStatusPieChart(context, projects),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: ChartCard(
                          title: 'Projects by Segment',
                          child: projectsAsync.when(
                            data: (projects) => buildSegmentPieChart(context, projects),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: ChartCard(
                          title: 'Projects by Category',
                          child: projectsAsync.when(
                            data: (projects) => buildCategoryPieChart(context, projects),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: largeSpacing),

                // Approval Pipeline
                Text('Approval Pipeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: spacing),
                projectsAsync.when(
                  data: (projects) => _buildApprovalPipeline(context, projects, currencyFormat, isMobile: isMobileView, spacing: spacing),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                SizedBox(height: largeSpacing),

                // Analysis Tools Section
                Text('Analysis Tools', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: spacing),
                if (isMobileView)
                  Column(
                    children: [
                      _AnalysisToolCard(
                        icon: Icons.compare_arrows,
                        title: 'Compare Projects',
                        subtitle: 'Side-by-side comparison',
                        color: Colors.teal,
                        onTap: () => context.go('/analysis/compare'),
                      ),
                      SizedBox(height: spacing),
                      _AnalysisToolCard(
                        icon: Icons.trending_up,
                        title: 'Sensitivity Analysis',
                        subtitle: 'What-if scenarios',
                        color: Colors.indigo,
                        onTap: () => context.go('/analysis/sensitivity'),
                      ),
                      SizedBox(height: spacing),
                      _AnalysisToolCard(
                        icon: Icons.warning_amber,
                        title: 'Risk Assessment',
                        subtitle: 'Risk scoring matrix',
                        color: Colors.deepOrange,
                        onTap: () => context.go('/analysis/risk'),
                      ),
                    ],
                  )
                else
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
                      SizedBox(width: spacing),
                      Expanded(
                        child: _AnalysisToolCard(
                          icon: Icons.trending_up,
                          title: 'Sensitivity Analysis',
                          subtitle: 'What-if scenarios',
                          color: Colors.indigo,
                          onTap: () => context.go('/analysis/sensitivity'),
                        ),
                      ),
                      SizedBox(width: spacing),
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

                SizedBox(height: largeSpacing),

                // Recent Activity
                Text('Recent Projects', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: spacing),
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
                            leading: isMobileView ? null : ProjectStatusIcon(status: project.status),
                            title: Text(
                              project.projectName,
                              style: TextStyle(fontSize: isMobileView ? 14 : null),
                            ),
                            subtitle: Text(
                              isMobileView
                                  ? project.pfrNumber
                                  : '${project.pfrNumber} | ${project.segment} | ${project.businessUnit}',
                              style: TextStyle(fontSize: isMobileView ? 12 : null),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ProjectStatusBadge(status: project.status),
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

                SizedBox(height: largeSpacing),

                // Configuration & User Summary Row - Stack on mobile
                if (isMobileView)
                  Column(
                    children: [
                      _buildConfigCard(context, configAsync, currencyFormat),
                      SizedBox(height: spacing),
                      _buildUserStatsCard(context, usersAsync),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildConfigCard(context, configAsync, currencyFormat)),
                      SizedBox(width: spacing),
                      Expanded(child: _buildUserStatsCard(context, usersAsync)),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovalPipeline(
    BuildContext context,
    List<Project> projects,
    NumberFormat currencyFormat, {
    required bool isMobile,
    required double spacing,
  }) {
    final submitted = projects.where((p) => p.status == ProjectStatus.submitted).toList();
    final pending = projects.where((p) => p.status == ProjectStatus.pendingApproval).toList();
    final onHold = projects.where((p) => p.status == ProjectStatus.onHold).toList();

    final cards = [
      _PipelineCard(
        title: 'Submitted',
        count: submitted.length,
        color: Colors.blue,
        icon: Icons.send,
        isCompact: isMobile,
        onTap: submitted.isNotEmpty ? () => showProjectDrillDown(
          context: context,
          title: 'Submitted Projects',
          projects: submitted,
          color: Colors.blue,
        ) : null,
      ),
      _PipelineCard(
        title: 'Pending Approval',
        count: pending.length,
        color: Colors.orange,
        icon: Icons.pending_actions,
        isCompact: isMobile,
        onTap: pending.isNotEmpty ? () => showProjectDrillDown(
          context: context,
          title: 'Pending Approval',
          projects: pending,
          color: Colors.orange,
        ) : null,
      ),
      _PipelineCard(
        title: 'On Hold',
        count: onHold.length,
        color: Colors.purple,
        icon: Icons.pause_circle,
        isCompact: isMobile,
        onTap: onHold.isNotEmpty ? () => showProjectDrillDown(
          context: context,
          title: 'Projects On Hold',
          projects: onHold,
          color: Colors.purple,
        ) : null,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing / 2),
            child: const Icon(Icons.arrow_downward, color: Colors.grey),
          ),
          cards[1],
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing / 2),
            child: const Icon(Icons.arrow_downward, color: Colors.grey),
          ),
          cards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Expanded(child: cards[1]),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildConfigCard(BuildContext context, AsyncValue configAsync, NumberFormat currencyFormat) {
    return Card(
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
    );
  }

  Widget _buildUserStatsCard(BuildContext context, AsyncValue usersAsync) {
    return Card(
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
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isCompact;

  const _PipelineCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: isCompact ? 24 : 28),
              SizedBox(height: isCompact ? 4 : 8),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isCompact ? 20 : null,
                ),
              ),
              Text(title, style: TextStyle(color: Colors.grey[700], fontSize: isCompact ? 11 : 12)),
              if (onTap != null && count > 0 && !isCompact) ...[
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
