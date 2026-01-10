import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/project.dart';
import '../../../providers/project_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/role_permissions_provider.dart';
import '../../widgets/excel_import_export.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final filter = ref.watch(projectFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          const _ExcelActionsWrapper(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/project/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _SearchFilterBar(filter: filter),
          // Project List
          Expanded(
            child: filteredProjects.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return _EmptyState(
                    hasFilter: filter.searchQuery.isNotEmpty || filter.statusFilter != null,
                    onClearFilters: () {
                      ref.read(projectFilterProvider.notifier).state = const ProjectFilter();
                    },
                  );
                }
                return _ProjectListView(projects: projects);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchFilterBar extends ConsumerWidget {
  final ProjectFilter filter;

  const _SearchFilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Row
          Row(
            children: [
              // Search TextField
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by project name or PFR number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              ref.read(projectFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    ref.read(projectFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort Dropdown
              PopupMenuButton<ProjectSortField>(
                tooltip: 'Sort by',
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort),
                    const SizedBox(width: 4),
                    Icon(
                      filter.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                    ),
                  ],
                ),
                onSelected: (field) {
                  if (field == filter.sortField) {
                    // Toggle sort direction
                    ref.read(projectFilterProvider.notifier).state =
                        filter.copyWith(sortAscending: !filter.sortAscending);
                  } else {
                    ref.read(projectFilterProvider.notifier).state =
                        filter.copyWith(sortField: field, sortAscending: false);
                  }
                },
                itemBuilder: (context) => [
                  _buildSortMenuItem(ProjectSortField.date, 'Date Created', filter),
                  _buildSortMenuItem(ProjectSortField.name, 'Project Name', filter),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Status:', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'All',
                  isSelected: filter.statusFilter == null,
                  onSelected: () {
                    ref.read(projectFilterProvider.notifier).state =
                        filter.copyWith(clearStatusFilter: true);
                  },
                ),
                const SizedBox(width: 8),
                ...ProjectStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StatusFilterChip(
                    label: status.displayName,
                    isSelected: filter.statusFilter == status.displayName,
                    color: _getStatusColor(status),
                    onSelected: () {
                      ref.read(projectFilterProvider.notifier).state =
                          filter.copyWith(statusFilter: status.displayName);
                    },
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ProjectSortField> _buildSortMenuItem(
    ProjectSortField field,
    String label,
    ProjectFilter filter,
  ) {
    final isSelected = filter.sortField == field;
    return PopupMenuItem(
      value: field,
      child: Row(
        children: [
          if (isSelected)
            Icon(
              filter.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            )
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check, size: 16),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return Colors.grey;
      case ProjectStatus.submitted:
      case ProjectStatus.pendingApproval:
        return Colors.orange;
      case ProjectStatus.approved:
        return Colors.green;
      case ProjectStatus.rejected:
        return Colors.red;
      case ProjectStatus.onHold:
        return Colors.blue;
      case ProjectStatus.cancelled:
        return Colors.grey[700]!;
    }
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color?.withValues(alpha: 0.2) ?? Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: color ?? Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? Theme.of(context).colorScheme.primary) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClearFilters;

  const _EmptyState({required this.hasFilter, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(hasFilter ? 'No matching projects' : 'No projects yet'),
          const SizedBox(height: 16),
          if (hasFilter)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => context.go('/project/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
        ],
      ),
    );
  }
}

class _ProjectListView extends StatelessWidget {
  final List<Project> projects;

  const _ProjectListView({required this.projects});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectCard(project: project);
      },
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final canViewAllProjects = ref.watch(canViewAllProjectsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProject = currentUser?.uid == project.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/project/${project.id}/analysis'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Project Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                project.pfrNumber,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _StatusBadge(status: project.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.projectName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details Row
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.businessUnit,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(project.projectStartDate),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              // Show owner info for projects from other users (when user can view all)
              if (canViewAllProjects && !isOwnProject && project.userId != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 14, color: Colors.amber[800]),
                      const SizedBox(width: 4),
                      Text(
                        'Owner: ${project.userId!.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (project.description != null && project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Footer Row with actions
              Row(
                children: [
                  if (project.initiativeSponsor != null) ...[
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      project.initiativeSponsor!,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go('/project/${project.id}'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/project/${project.id}/analysis'),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Analysis'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  _DeleteButton(project: project),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (status == ProjectStatus.draft) {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[700]!;
    } else if (status == ProjectStatus.submitted || status == ProjectStatus.pendingApproval) {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
    } else if (status == ProjectStatus.approved) {
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
    } else if (status == ProjectStatus.rejected) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
    } else if (status == ProjectStatus.onHold) {
      backgroundColor = Colors.blue[100]!;
      textColor = Colors.blue[800]!;
    } else {
      backgroundColor = Colors.grey[300]!;
      textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  final Project project;

  const _DeleteButton({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showDeleteConfirmation(context, ref),
      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
      label: const Text('Delete', style: TextStyle(color: Colors.red)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this project?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.pfrNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(project.projectName),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. All associated financial data will also be deleted.',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(projectRepositoryProvider);
        await repository.deleteProject(project.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project "${project.projectName}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting project: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ExcelActionsWrapper extends ConsumerWidget {
  const _ExcelActionsWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(filteredProjectsProvider);

    return projectsAsync.maybeWhen(
      data: (projects) => ExcelToolbar(projects: projects),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
