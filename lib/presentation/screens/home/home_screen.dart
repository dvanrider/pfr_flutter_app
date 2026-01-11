import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../../providers/providers.dart';
import '../../widgets/dashboard_widgets.dart';

/// Home Screen - Main dashboard for PFR application
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectCounts = ref.watch(projectCountsProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final configAsync = ref.watch(systemConfigProvider);

    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(constraints.maxWidth);
        final isMobileView = screenSize == ScreenSize.mobile;

        return Scaffold(
          appBar: AppBar(
            title: Text(isMobileView ? 'PFR' : 'Project Funding Request'),
            leading: isMobileView
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : null,
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
            if (isAdmin && !isMobileView)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (!isMobileView)
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
                backgroundColor: isAdmin ? Colors.amber : Colors.white24,
                child: Text(
                  (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: isAdmin ? Colors.black : Colors.white),
                ),
              ),
              onSelected: (value) async {
                if (value == 'signout') {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.signOut();
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
                            user.displayName ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (userProfile != null)
                        Text(
                          'Role: ${userProfile.role.displayName}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
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
      drawer: isMobileView
          ? _MobileNavigationDrawer(
              user: user,
              isAdmin: isAdmin,
              userProfile: userProfile,
              onSignOut: () async {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.signOut();
              },
            )
          : null,
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
                // Organization Overview Header
                if (isMobileView)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
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
                              style: theme.textTheme.headlineMedium?.copyWith(
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

                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing),
                // Quick Actions - All 3 cards in same row on desktop, wrap on mobile
                _buildQuickActionsSection(
                  context: context,
                  theme: theme,
                  isAdmin: isAdmin,
                  isMobile: isMobileView,
                  spacing: spacing,
                ),
                SizedBox(height: largeSpacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Recent Projects',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/projects'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                const _RecentProjectsList(),
                SizedBox(height: largeSpacing),
                Text(
                  'Portfolio Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing),
                projectCounts.when(
                  data: (counts) => Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      _MetricCard(
                        label: 'Total',
                        value: '${counts['total'] ?? 0}',
                        icon: Icons.folder,
                      ),
                      _MetricCard(
                        label: 'Approved',
                        value: '${counts['approved'] ?? 0}',
                        icon: Icons.check_circle,
                      ),
                      _MetricCard(
                        label: 'Pending',
                        value: '${counts['pending'] ?? 0}',
                        icon: Icons.hourglass_top,
                      ),
                      _MetricCard(
                        label: 'Draft',
                        value: '${counts['draft'] ?? 0}',
                        icon: Icons.edit,
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error loading metrics'),
                ),
              ],
            ),
          );
        },
      ),
    );
      },
    );
  }
}

/// Mobile Navigation Drawer
class _MobileNavigationDrawer extends StatelessWidget {
  final dynamic user;
  final bool isAdmin;
  final dynamic userProfile;
  final VoidCallback onSignOut;

  const _MobileNavigationDrawer({
    required this.user,
    required this.isAdmin,
    required this.userProfile,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isAdmin ? Colors.amber : theme.colorScheme.primary,
                        radius: 24,
                        child: Text(
                          (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: isAdmin ? Colors.black : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.email != null)
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  if (userProfile != null)
                    Text(
                      'Role: ${userProfile.role.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('New Project'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/project/new');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: const Text('My Projects'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/projects');
                    },
                  ),
                  const Divider(),
                  if (isAdmin) ...[
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: Colors.amber[700]),
                      title: const Text('Admin Panel'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/admin');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.dashboard, color: Colors.amber[700]),
                      title: const Text('Executive Dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/executive');
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/help');
                    },
                  ),
                ],
              ),
            ),
            // Theme Toggle
            const Divider(height: 1),
            Consumer(
              builder: (context, ref, _) {
                final currentTheme = ref.watch(themeModeProvider);
                return ListTile(
                  leading: Icon(currentTheme.icon),
                  title: const Text('Theme'),
                  trailing: Text(
                    currentTheme.displayName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    ref.read(themeModeProvider.notifier).cycleTheme();
                  },
                );
              },
            ),
            // Sign Out
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Build Quick Actions section - 3 cards in row on desktop, stack on mobile
Widget _buildQuickActionsSection({
  required BuildContext context,
  required ThemeData theme,
  required bool isAdmin,
  required bool isMobile,
  required double spacing,
}) {
  final cards = [
    _ActionCard(
      icon: Icons.add_circle_outline,
      title: 'New Project',
      subtitle: 'Create a new funding request',
      color: theme.colorScheme.primary,
      onTap: () => context.go('/project/new'),
    ),
    _ActionCard(
      icon: Icons.folder_open,
      title: 'My Projects',
      subtitle: 'View and manage projects',
      color: theme.colorScheme.secondary,
      onTap: () => context.go('/projects'),
    ),
    if (isAdmin)
      _ActionCard(
        icon: Icons.admin_panel_settings,
        title: 'Admin Panel',
        subtitle: 'Manage users, roles & configuration',
        color: Colors.amber[700]!,
        onTap: () => context.go('/admin'),
      ),
  ];

  if (isMobile) {
    return Column(
      children: cards.map((card) => Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: card,
      )).toList(),
    );
  }

  // Desktop: all cards in a row
  return Row(
    children: cards.asMap().entries.map((entry) {
      final isLast = entry.key == cards.length - 1;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : spacing),
          child: entry.value,
        ),
      );
    }).toList(),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentProjectsList extends ConsumerWidget {
  const _RecentProjectsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentProjects = ref.watch(recentProjectsProvider);

    return recentProjects.when(
      data: (projects) {
        if (projects.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No projects yet'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/project/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Project'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: projects.map((project) {
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(project.projectName),
                subtitle: Text(project.pfrNumber),
                trailing: Text(project.status.displayName),
                onTap: () => context.go('/project/${project.id}/analysis'),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Card(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Card(child: Center(child: Text('Error: $e'))),
    );
  }
}
