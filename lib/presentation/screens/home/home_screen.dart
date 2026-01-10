import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../providers/project_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/user_management_providers.dart';
import '../../../providers/role_permissions_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/seed_data_service.dart';
import '../../widgets/notifications_panel.dart';

/// Home Screen - Main dashboard for PFR application
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectCounts = ref.watch(projectCountsProvider);

    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isAppAdmin = ref.watch(isAppAdminProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final canManageUsers = ref.watch(canManageUsersProvider);
    final canConfigureSystem = ref.watch(canConfigureSystemProvider);
    final hasAdminAccess = canManageUsers || canConfigureSystem;
    final canViewAllProjects = ref.watch(canViewAllProjectsProvider);

    // DEBUG: Print role info to console
    if (user != null) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('DEBUG ROLE INFO:');
      debugPrint('  Auth UID: ${user.uid}');
      debugPrint('  isAdmin (auth): $isAdmin');
      debugPrint('  isAppAdmin (app): $isAppAdmin');
      debugPrint('  Profile Loaded: ${userProfile != null}');
      debugPrint('  Profile Role: ${userProfile?.role.name ?? "NULL"}');
      debugPrint('  Profile Email: ${userProfile?.email ?? "NULL"}');
      debugPrint('═══════════════════════════════════════════');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Funding Request'),
        actions: [
          // Debug role indicator
          if (user != null)
            _RoleDebugIndicator(
              uid: user.uid,
              isAdmin: isAdmin,
              isAppAdmin: isAppAdmin,
              userProfile: userProfile,
            ),
          // Notifications
          if (user != null) const NotificationIconButton(),
          // Theme toggle
          const _ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help & Training',
            onPressed: () => context.go('/help/training'),
          ),
          if (user != null) ...[
            if (isAdmin)
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome${user?.displayName != null ? ', ${user!.displayName}' : ''}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage capital project approvals with financial analysis',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'New Project',
                    subtitle: 'Create a new funding request',
                    color: theme.colorScheme.primary,
                    onTap: () => context.go('/project/new'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.folder_open,
                    title: 'My Projects',
                    subtitle: 'View and manage projects',
                    color: theme.colorScheme.secondary,
                    onTap: () => context.go('/projects'),
                  ),
                ),
                if (hasAdminAccess) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Panel',
                      subtitle: 'Manage users and settings',
                      color: Colors.purple,
                      onTap: () => context.go('/admin'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _LoadSampleDataCard(),
            if (canViewAllProjects) ...[
              const SizedBox(height: 32),
              Text(
                'Analysis Tools',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.compare_arrows,
                      title: 'Compare Projects',
                      subtitle: 'Side-by-side comparison',
                      color: Colors.teal,
                      onTap: () => context.go('/analysis/compare'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.tune,
                      title: 'Sensitivity Analysis',
                      subtitle: 'What-if scenarios',
                      color: Colors.indigo,
                      onTap: () => context.go('/analysis/sensitivity'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.warning_amber,
                      title: 'Risk Assessment',
                      subtitle: 'Risk scoring matrix',
                      color: Colors.deepOrange,
                      onTap: () => context.go('/analysis/risk'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Projects',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/projects'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _RecentProjectsList(),
            const SizedBox(height: 32),
            Text(
              'Portfolio Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            projectCounts.when(
              data: (counts) => Wrap(
                spacing: 16,
                runSpacing: 16,
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
      ),
    );
  }
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

class _LoadSampleDataCard extends StatefulWidget {
  const _LoadSampleDataCard();

  @override
  State<_LoadSampleDataCard> createState() => _LoadSampleDataCardState();
}

class _LoadSampleDataCardState extends State<_LoadSampleDataCard> {
  bool _isLoading = false;

  Future<void> _loadSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Sample Data'),
        content: const Text(
          'This will add 5 sample projects with financial data (CapEx, OpEx, Benefits). Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final seedService = SeedDataService(FirebaseFirestore.instance);
      await seedService.forceSeedSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5 sample projects loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange[50],
      child: InkWell(
        onTap: _isLoading ? null : _loadSampleData,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.dataset, color: Colors.orange[800], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load Sample Data',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add 5 sample projects with financial data for testing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug indicator showing user role information
class _RoleDebugIndicator extends StatelessWidget {
  final String uid;
  final bool isAdmin;
  final bool isAppAdmin;
  final UserProfile? userProfile;

  const _RoleDebugIndicator({
    required this.uid,
    required this.isAdmin,
    required this.isAppAdmin,
    required this.userProfile,
  });

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Colors.orange),
            SizedBox(width: 8),
            Text('Role Debug Info'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DebugRow(label: 'Firebase Auth UID', value: uid),
            const Divider(),
            _DebugRow(label: 'isAdmin (auth)', value: isAdmin.toString()),
            _DebugRow(label: 'isAppAdmin (app)', value: isAppAdmin.toString()),
            const Divider(),
            _DebugRow(
              label: 'Profile Loaded',
              value: userProfile != null ? 'YES' : 'NO - Check Firestore!',
              isError: userProfile == null,
            ),
            if (userProfile != null) ...[
              _DebugRow(label: 'Profile Role', value: userProfile!.role.name),
              _DebugRow(label: 'Profile Email', value: userProfile!.email),
            ],
            const Divider(),
            const Text(
              'Firestore document ID must match the Auth UID exactly!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Expected doc path: users/$uid',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDebugDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAppAdmin ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAppAdmin ? Icons.verified : Icons.bug_report,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              userProfile?.role.name.toUpperCase() ?? 'NO ROLE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _DebugRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isError ? Colors.red : null,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme toggle button with popup menu
class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);

    return PopupMenuButton<AppThemeMode>(
      icon: Icon(currentTheme.icon),
      tooltip: 'Theme: ${currentTheme.displayName}',
      onSelected: (mode) {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      itemBuilder: (context) => AppThemeMode.values.map((mode) {
        final isSelected = mode == currentTheme;
        return PopupMenuItem(
          value: mode,
          child: Row(
            children: [
              Icon(
                mode.icon,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              const SizedBox(width: 12),
              Text(
                mode.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : null,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
