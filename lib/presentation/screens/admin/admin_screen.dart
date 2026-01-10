import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../services/seed_data_service.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/system_config.dart';
import '../../../data/models/project.dart';
import '../../../data/models/role_permissions.dart';
import '../../../providers/providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManageUsers = ref.watch(canManageUsersProvider);
    final canConfigureSystem = ref.watch(canConfigureSystemProvider);
    final hasAdminAccess = canManageUsers || canConfigureSystem;

    if (!hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Access Denied', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('You do not have permission to access this page.'),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Roles'),
              Tab(icon: Icon(Icons.settings), text: 'Configuration'),
              Tab(icon: Icon(Icons.approval), text: 'Approvals'),
              Tab(icon: Icon(Icons.folder_copy), text: 'Projects'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminDashboardTab(),
            _UserManagementTab(),
            _RoleManagementTab(),
            _SystemConfigTab(),
            _ApprovalWorkflowTab(),
            _BulkProjectsTab(),
          ],
        ),
      ),
    );
  }
}

class _UserManagementTab extends ConsumerWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredUsersAsync = ref.watch(filteredUsersProvider);
    final filter = ref.watch(userFilterProvider);

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    ref.read(userFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Role filter
              DropdownButton<UserRole?>(
                value: filter.roleFilter,
                hint: const Text('All Roles'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                  ...UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  )),
                ],
                onChanged: (value) {
                  ref.read(userFilterProvider.notifier).state =
                      filter.copyWith(roleFilter: value, clearRoleFilter: value == null);
                },
              ),
              const SizedBox(width: 16),
              // Active filter
              DropdownButton<bool?>(
                value: filter.activeFilter,
                hint: const Text('All Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: true, child: Text('Active')),
                  DropdownMenuItem(value: false, child: Text('Inactive')),
                ],
                onChanged: (value) {
                  ref.read(userFilterProvider.notifier).state =
                      filter.copyWith(activeFilter: value, clearActiveFilter: value == null);
                },
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showAddUserDialog(context, ref),
                icon: const Icon(Icons.person_add),
                label: const Text('Add User'),
              ),
            ],
          ),
        ),
        // User list
        Expanded(
          child: filteredUsersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No users found'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserCard(user: user);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _PreRegisterUserDialog(),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AppUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
              child: Text(
                user.initials,
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.displayName ?? user.email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleChip(role: user.role),
                      const SizedBox(width: 8),
                      if (!user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Inactive',
                            style: TextStyle(fontSize: 12, color: Colors.red[800]),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (user.department != null) ...[
                        Icon(Icons.business, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(user.department!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        user.lastLoginAt != null
                            ? 'Last login: ${dateFormat.format(user.lastLoginAt!)}'
                            : 'Never logged in',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit User'))),
                const PopupMenuItem(value: 'role', child: ListTile(leading: Icon(Icons.admin_panel_settings), title: Text('Change Role'))),
                const PopupMenuItem(value: 'reset_password', child: ListTile(leading: Icon(Icons.lock_reset), title: Text('Reset Password'))),
                PopupMenuItem(
                  value: user.isActive ? 'deactivate' : 'activate',
                  child: ListTile(
                    leading: Icon(user.isActive ? Icons.person_off : Icons.person),
                    title: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superUser:
        return Colors.red;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.executive:
        return Colors.deepPurple;
      case UserRole.approver:
        return Colors.blue;
      case UserRole.requester:
        return Colors.green;
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => _EditUserDialog(user: user),
        );
        break;
      case 'role':
        showDialog(
          context: context,
          builder: (context) => _ChangeRoleDialog(user: user),
        );
        break;
      case 'reset_password':
        _sendPasswordReset(context, ref);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserActive(context, ref);
        break;
    }
  }

  void _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Password Reset'),
        content: Text('Send a password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(user.email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleUserActive(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(userManagementRepositoryProvider);
    final newStatus = !user.isActive;

    try {
      await repository.setUserActive(user.uid, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${newStatus ? 'activated' : 'deactivated'} successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (role) {
      case UserRole.superUser:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case UserRole.admin:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case UserRole.executive:
        backgroundColor = Colors.deepPurple[100]!;
        textColor = Colors.deepPurple[800]!;
        break;
      case UserRole.approver:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case UserRole.requester:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Role Management Tab - displays all roles and their permissions
class _RoleManagementTab extends ConsumerWidget {
  const _RoleManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final permissionsAsync = ref.watch(allRolePermissionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.admin_panel_settings,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'View and manage user roles and their permissions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              // Initialize defaults button
              OutlinedButton.icon(
                onPressed: () => _initializeDefaults(context, ref),
                icon: const Icon(Icons.restore),
                label: const Text('Reset All to Defaults'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Role cards
          usersAsync.when(
            data: (users) {
              final roleCounts = <UserRole, int>{};
              for (final role in UserRole.values) {
                roleCounts[role] = users.where((u) => u.role == role).length;
              }

              return permissionsAsync.when(
                data: (allPermissions) {
                  return Column(
                    children: [
                      // Summary row
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: UserRole.values.map((role) {
                          return _RoleSummaryCard(
                            role: role,
                            userCount: roleCounts[role] ?? 0,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Detailed role cards
                      ...UserRole.values.map((role) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _EditableRoleCard(
                              role: role,
                              userCount: roleCounts[role] ?? 0,
                              users: users.where((u) => u.role == role).toList(),
                              rolePermissions: allPermissions[role] ??
                                  RolePermissions.defaults(role),
                            ),
                          )),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading permissions: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading users: $e')),
          ),
        ],
      ),
    );
  }

  void _initializeDefaults(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Permissions?'),
        content: const Text(
          'This will reset all role permissions to their default values. '
          'Any custom permissions you have configured will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(rolePermissionsRepositoryProvider);
        for (final role in UserRole.values) {
          await repository.resetToDefaults(role);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All permissions reset to defaults'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting permissions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Summary card showing role name and user count
class _RoleSummaryCard extends StatelessWidget {
  final UserRole role;
  final int userCount;

  const _RoleSummaryCard({required this.role, required this.userCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(role).withValues(alpha: 0.2),
              child: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
            ),
            const SizedBox(height: 12),
            Text(
              role.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$userCount user${userCount == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superUser:
        return Colors.red;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.executive:
        return Colors.deepPurple;
      case UserRole.approver:
        return Colors.blue;
      case UserRole.requester:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superUser:
        return Icons.security;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.executive:
        return Icons.business;
      case UserRole.approver:
        return Icons.verified_user;
      case UserRole.requester:
        return Icons.person;
    }
  }
}

/// Editable card showing role permissions and users
class _EditableRoleCard extends ConsumerStatefulWidget {
  final UserRole role;
  final int userCount;
  final List<AppUser> users;
  final RolePermissions rolePermissions;

  const _EditableRoleCard({
    required this.role,
    required this.userCount,
    required this.users,
    required this.rolePermissions,
  });

  @override
  ConsumerState<_EditableRoleCard> createState() => _EditableRoleCardState();
}

class _EditableRoleCardState extends ConsumerState<_EditableRoleCard> {
  late Set<Permission> _selectedPermissions;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = Set.from(widget.rolePermissions.permissions);
  }

  @override
  void didUpdateWidget(covariant _EditableRoleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      _selectedPermissions = Set.from(widget.rolePermissions.permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChanges = !_setEquals(_selectedPermissions, widget.rolePermissions.permissions);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(widget.role).withValues(alpha: 0.2),
          child: Icon(_getRoleIcon(widget.role), color: _getRoleColor(widget.role)),
        ),
        title: Row(
          children: [
            Text(
              widget.role.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(widget.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.userCount} user${widget.userCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: _getRoleColor(widget.role),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Editing',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          widget.role.description,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permissions header with edit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Permissions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (_isEditing && hasChanges) ...[
                          TextButton(
                            onPressed: _isSaving ? null : _cancelEdit,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _savePermissions,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save, size: 18),
                            label: Text(_isSaving ? 'Saving...' : 'Save'),
                          ),
                        ] else if (_isEditing) ...[
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Done'),
                          ),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Permissions grid
                if (_isEditing)
                  _buildEditablePermissions()
                else
                  _buildReadOnlyPermissions(),

                // Last updated info
                if (widget.rolePermissions.updatedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.rolePermissions.updatedAt!)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                // Users section
                if (widget.users.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Users with this role',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.users.take(10).map((user) {
                      return Chip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              _getRoleColor(widget.role).withValues(alpha: 0.3),
                          child: Text(
                            user.initials,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        label: Text(
                          user.displayName ?? user.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  if (widget.users.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '...and ${widget.users.length - 10} more',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyPermissions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Permission.values.map((permission) {
        final hasPermission = _selectedPermissions.contains(permission);
        return Chip(
          avatar: Icon(
            _getPermissionIcon(permission),
            size: 16,
            color: hasPermission ? Colors.green : Colors.grey,
          ),
          label: Text(
            permission.displayName,
            style: TextStyle(
              fontSize: 12,
              color: hasPermission ? null : Colors.grey,
              decoration: hasPermission ? null : TextDecoration.lineThrough,
            ),
          ),
          backgroundColor: hasPermission
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
        );
      }).toList(),
    );
  }

  Widget _buildEditablePermissions() {
    return Column(
      children: Permission.values.map((permission) {
        final hasPermission = _selectedPermissions.contains(permission);
        return CheckboxListTile(
          value: hasPermission,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedPermissions.add(permission);
              } else {
                _selectedPermissions.remove(permission);
              }
            });
          },
          secondary: Icon(
            _getPermissionIcon(permission),
            color: hasPermission
                ? _getRoleColor(widget.role)
                : Colors.grey,
          ),
          title: Text(
            permission.displayName,
            style: TextStyle(
              fontWeight: hasPermission ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            permission.description,
            style: const TextStyle(fontSize: 12),
          ),
          activeColor: _getRoleColor(widget.role),
          dense: true,
        );
      }).toList(),
    );
  }

  void _cancelEdit() {
    setState(() {
      _selectedPermissions = Set.from(widget.rolePermissions.permissions);
      _isEditing = false;
    });
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(rolePermissionsRepositoryProvider);
      final updatedPermissions = widget.rolePermissions.copyWith(
        permissions: _selectedPermissions,
        updatedAt: DateTime.now(),
      );

      await repository.savePermissions(updatedPermissions);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.role.displayName} permissions saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _setEquals(Set<Permission> a, Set<Permission> b) {
    if (a.length != b.length) return false;
    return a.every((item) => b.contains(item));
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.createProjects:
        return Icons.add_box;
      case Permission.editOwnProjects:
        return Icons.edit;
      case Permission.viewAllProjects:
        return Icons.visibility;
      case Permission.approveProjects:
        return Icons.check_circle;
      case Permission.viewExecutiveDashboard:
        return Icons.dashboard;
      case Permission.manageUsers:
        return Icons.people;
      case Permission.systemConfiguration:
        return Icons.settings;
      case Permission.fullSystemAccess:
        return Icons.security;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superUser:
        return Colors.red;
      case UserRole.admin:
        return Colors.purple;
      case UserRole.executive:
        return Colors.deepPurple;
      case UserRole.approver:
        return Colors.blue;
      case UserRole.requester:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superUser:
        return Icons.security;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.executive:
        return Icons.business;
      case UserRole.approver:
        return Icons.verified_user;
      case UserRole.requester:
        return Icons.person;
    }
  }
}

class _PreRegisterUserDialog extends ConsumerStatefulWidget {
  const _PreRegisterUserDialog();

  @override
  ConsumerState<_PreRegisterUserDialog> createState() => _PreRegisterUserDialogState();
}

class _PreRegisterUserDialogState extends ConsumerState<_PreRegisterUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  UserRole _selectedRole = UserRole.requester;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add),
          SizedBox(width: 12),
          Text('Pre-Register User'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pre-register an email with a role. When the user signs up with this email, they will automatically be assigned this role.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  helperText: 'User will sign up with this email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (optional)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 8),
              if (_selectedRole != UserRole.requester)
                Text(
                  _selectedRole.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _preRegisterUser,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Pre-Register'),
        ),
      ],
    );
  }

  void _preRegisterUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(userManagementRepositoryProvider);
      final email = _emailController.text.trim().toLowerCase();

      // Check if email is already registered
      final existingUser = await repository.getUserByEmail(email);
      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A user with this email already exists'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Create pre-registration record (uses email as document ID for easy lookup)
      await repository.preRegisterUser(
        email: email,
        role: _selectedRole,
        displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        department: _departmentController.text.trim().isNotEmpty ? _departmentController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pre-registered ${_emailController.text} as ${_selectedRole.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _departmentController = TextEditingController(text: widget.user.department);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit),
          SizedBox(width: 12),
          Text('Edit User'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveUser,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }

  void _saveUser() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(userManagementRepositoryProvider);
      await repository.updateUserProfile(
        widget.user.uid,
        displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        department: _departmentController.text.trim().isNotEmpty ? _departmentController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _ChangeRoleDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const _ChangeRoleDialog({required this.user});

  @override
  ConsumerState<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends ConsumerState<_ChangeRoleDialog> {
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.admin_panel_settings),
          SizedBox(width: 12),
          Text('Change Role'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changing role for: ${widget.user.displayName ?? widget.user.email}'),
            const SizedBox(height: 16),
            ...UserRole.values.map((role) => RadioListTile<UserRole>(
              value: role,
              // ignore: deprecated_member_use
              groupValue: _selectedRole,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
              title: Text(role.displayName),
              subtitle: Text(role.description),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || _selectedRole == widget.user.role ? null : _changeRole,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Change Role'),
        ),
      ],
    );
  }

  void _changeRole() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(userManagementRepositoryProvider);
      await repository.updateUserRole(widget.user.uid, _selectedRole);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role changed to ${_selectedRole.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ============================================================================
// ADMIN DASHBOARD TAB
// ============================================================================

class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final configAsync = ref.watch(systemConfigProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Organization-wide metrics and analytics', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Key Metrics Row
          projectsAsync.when(
            data: (projects) {
              final pendingCount = projects.where((p) => p.status == ProjectStatus.pendingApproval || p.status == ProjectStatus.submitted).length;
              final approvedCount = projects.where((p) => p.status == ProjectStatus.approved).length;
              final approvalRate = projects.isNotEmpty ? (approvedCount / projects.length * 100) : 0;

              return Row(
                children: [
                  _StatCard(title: 'Total Projects', value: '${projects.length}', icon: Icons.folder, color: Colors.blue),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Pending Approval', value: '$pendingCount', icon: Icons.hourglass_empty, color: Colors.orange),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Approved', value: '$approvedCount', icon: Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Approval Rate', value: '${approvalRate.toStringAsFixed(0)}%', icon: Icons.trending_up, color: Colors.purple),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 32),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Projects by Status Chart
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Projects by Status', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: projectsAsync.when(
                            data: (projects) => _buildStatusPieChart(context, projects),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Projects by Segment Chart
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Projects by Segment', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: projectsAsync.when(
                            data: (projects) => _buildSegmentPieChart(context, projects),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Error: $e'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // User Statistics
          Text('User Statistics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          usersAsync.when(
            data: (users) {
              final activeCount = users.where((u) => u.isActive).length;
              final adminCount = users.where((u) => u.role == UserRole.admin).length;
              final executiveCount = users.where((u) => u.role == UserRole.executive).length;
              final approverCount = users.where((u) => u.role == UserRole.approver).length;
              final requesterCount = users.where((u) => u.role == UserRole.requester).length;

              return Row(
                children: [
                  _StatCard(title: 'Total Users', value: '${users.length}', icon: Icons.people, color: Colors.blue),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Active', value: '$activeCount', icon: Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Admins', value: '$adminCount', icon: Icons.admin_panel_settings, color: Colors.purple),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Executives', value: '$executiveCount', icon: Icons.business_center, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Approvers', value: '$approverCount', icon: Icons.verified_user, color: Colors.orange),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Requesters', value: '$requesterCount', icon: Icons.person, color: Colors.teal),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 32),

          // Current Configuration Summary
          Text('Current Configuration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          configAsync.when(
            data: (config) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _ConfigSummaryItem(label: 'Hurdle Rate', value: '${(config.hurdleRate * 100).toStringAsFixed(0)}%', icon: Icons.percent),
                      const SizedBox(width: 32),
                      _ConfigSummaryItem(label: 'Projection Years', value: '${config.projectionYears}', icon: Icons.calendar_today),
                      const SizedBox(width: 32),
                      _ConfigSummaryItem(label: 'Contingency', value: '${(config.contingencyRate * 100).toStringAsFixed(0)}%', icon: Icons.shield),
                      const SizedBox(width: 32),
                      _ConfigSummaryItem(label: 'Auto-Approve Under', value: config.autoApproveThreshold > 0 ? currencyFormat.format(config.autoApproveThreshold) : 'Disabled', icon: Icons.speed),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading config: $e'),
          ),
        ],
      ),
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
          child: PieChart(
            PieChartData(
              sections: statusCounts.entries.map((e) {
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  title: '${e.value}',
                  color: colors[e.key] ?? Colors.grey,
                  radius: 60,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
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
                  Container(width: 12, height: 12, color: colors[e.key]),
                  const SizedBox(width: 8),
                  Text(e.key.displayName, style: const TextStyle(fontSize: 12)),
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

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: segmentCounts.entries.toList().asMap().entries.map((e) {
                return PieChartSectionData(
                  value: e.value.value.toDouble(),
                  title: '${e.value.value}',
                  color: colors[e.key % colors.length],
                  radius: 60,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
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
                  Container(width: 12, height: 12, color: colors[e.key % colors.length]),
                  const SizedBox(width: 8),
                  Text(e.value.key, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ConfigSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ConfigSummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// SYSTEM CONFIGURATION TAB
// ============================================================================

class _SystemConfigTab extends ConsumerStatefulWidget {
  const _SystemConfigTab();

  @override
  ConsumerState<_SystemConfigTab> createState() => _SystemConfigTabState();
}

class _SystemConfigTabState extends ConsumerState<_SystemConfigTab> {
  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(systemConfigProvider);
    final user = ref.watch(currentUserProvider);

    return configAsync.when(
      data: (config) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Configuration', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Manage financial settings and dropdown options', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Financial Settings
              _ConfigSection(
                title: 'Financial Settings',
                icon: Icons.attach_money,
                children: [
                  _ConfigEditRow(
                    label: 'Hurdle Rate (IRR threshold)',
                    value: '${(config.hurdleRate * 100).toStringAsFixed(0)}%',
                    onEdit: () => _editHurdleRate(config, user?.uid ?? ''),
                  ),
                  _ConfigEditRow(
                    label: 'Projection Years',
                    value: '${config.projectionYears} years',
                    onEdit: () => _editProjectionYears(config, user?.uid ?? ''),
                  ),
                  _ConfigEditRow(
                    label: 'Default Contingency Rate',
                    value: '${(config.contingencyRate * 100).toStringAsFixed(0)}%',
                    onEdit: () => _editContingencyRate(config, user?.uid ?? ''),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Dropdown Options
              _ConfigSection(
                title: 'Dropdown Options',
                icon: Icons.list,
                children: [
                  _DropdownConfigRow(
                    label: 'Segments',
                    count: config.segments.length,
                    activeCount: config.activeSegments.length,
                    onEdit: () => _editDropdownOptions('Segments', 'segments', config.segments, user?.uid ?? ''),
                  ),
                  _DropdownConfigRow(
                    label: 'Business Unit Groups',
                    count: config.businessUnitGroups.length,
                    activeCount: config.activeBusinessUnitGroups.length,
                    onEdit: () => _editDropdownOptions('Business Unit Groups', 'businessUnitGroups', config.businessUnitGroups, user?.uid ?? ''),
                  ),
                  _DropdownConfigRow(
                    label: 'Business Units',
                    count: config.businessUnits.length,
                    activeCount: config.activeBusinessUnits.length,
                    onEdit: () => _editDropdownOptions('Business Units', 'businessUnits', config.businessUnits, user?.uid ?? ''),
                  ),
                  _DropdownConfigRow(
                    label: 'IC Categories',
                    count: config.icCategories.length,
                    activeCount: config.activeIcCategories.length,
                    onEdit: () => _editDropdownOptions('IC Categories', 'icCategories', config.icCategories, user?.uid ?? ''),
                  ),
                  _DropdownConfigRow(
                    label: 'Currencies',
                    count: config.currencies.length,
                    activeCount: config.activeCurrencies.length,
                    onEdit: () => _editDropdownOptions('Currencies', 'currencies', config.currencies, user?.uid ?? ''),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Last Updated
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(config.updatedAt)}${config.updatedBy != null ? ' by ${config.updatedBy}' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Data Management
              _ConfigSection(
                title: 'Data Management',
                icon: Icons.storage,
                children: [
                  _DataManagementRow(
                    label: 'Load Sample Data',
                    description: 'Add 5 sample projects with financial data for testing',
                    icon: Icons.dataset,
                    iconColor: Colors.orange,
                    buttonLabel: 'Load Data',
                    onAction: () => _loadSampleData(),
                  ),
                  _DataManagementRow(
                    label: 'Delete All My Projects',
                    description: 'Permanently remove all your projects and financial data',
                    icon: Icons.delete_sweep,
                    iconColor: Colors.red,
                    buttonLabel: 'Delete All',
                    isDestructive: true,
                    onAction: () => _deleteAllProjects(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllProjects() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All My Projects'),
        content: const Text(
          'This will permanently delete ALL your projects and their financial data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final seedService = SeedDataService(FirebaseFirestore.instance);
      final deletedCount = await seedService.cleanupSeedData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount project(s) deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editHurdleRate(SystemConfig config, String userId) {
    final controller = TextEditingController(text: (config.hurdleRate * 100).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Hurdle Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hurdle Rate (%)',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate > 0 && rate <= 100) {
                final repo = ref.read(systemConfigRepositoryProvider);
                await repo.updateHurdleRate(rate / 100, userId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editProjectionYears(SystemConfig config, String userId) {
    final controller = TextEditingController(text: config.projectionYears.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Projection Years'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Projection Years',
            suffixText: 'years',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final years = int.tryParse(controller.text);
              if (years != null && years > 0 && years <= 20) {
                final repo = ref.read(systemConfigRepositoryProvider);
                await repo.updateProjectionYears(years, userId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editContingencyRate(SystemConfig config, String userId) {
    final controller = TextEditingController(text: (config.contingencyRate * 100).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contingency Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Contingency Rate (%)',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final rate = double.tryParse(controller.text);
              if (rate != null && rate >= 0 && rate <= 50) {
                final repo = ref.read(systemConfigRepositoryProvider);
                await repo.saveConfig(config.copyWith(contingencyRate: rate / 100), userId);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDropdownOptions(String title, String field, List<DropdownOption> options, String userId) {
    showDialog(
      context: context,
      builder: (context) => _DropdownOptionsDialog(
        title: title,
        field: field,
        options: options,
        userId: userId,
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ConfigSection({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ConfigEditRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ConfigEditRow({required this.label, required this.value, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
        ],
      ),
    );
  }
}

class _DropdownConfigRow extends StatelessWidget {
  final String label;
  final int count;
  final int activeCount;
  final VoidCallback onEdit;

  const _DropdownConfigRow({required this.label, required this.count, required this.activeCount, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$activeCount active / $count total', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
        ],
      ),
    );
  }
}

class _DataManagementRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String buttonLabel;
  final bool isDestructive;
  final VoidCallback onAction;

  const _DataManagementRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.buttonLabel,
    this.isDestructive = false,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 16),
          isDestructive
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: onAction,
                  child: Text(buttonLabel),
                )
              : FilledButton(
                  onPressed: onAction,
                  child: Text(buttonLabel),
                ),
        ],
      ),
    );
  }
}

class _DropdownOptionsDialog extends ConsumerStatefulWidget {
  final String title;
  final String field;
  final List<DropdownOption> options;
  final String userId;

  const _DropdownOptionsDialog({
    required this.title,
    required this.field,
    required this.options,
    required this.userId,
  });

  @override
  ConsumerState<_DropdownOptionsDialog> createState() => _DropdownOptionsDialogState();
}

class _DropdownOptionsDialogState extends ConsumerState<_DropdownOptionsDialog> {
  late List<DropdownOption> _options;

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.options);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.title}'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _options.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _options.removeAt(oldIndex);
                    _options.insert(newIndex, item);
                    // Update sort orders
                    for (var i = 0; i < _options.length; i++) {
                      _options[i] = DropdownOption(
                        value: _options[i].value,
                        label: _options[i].label,
                        isActive: _options[i].isActive,
                        sortOrder: i,
                      );
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final option = _options[index];
                  return ListTile(
                    key: ValueKey(option.value),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(option.label),
                    subtitle: Text(option.value, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: option.isActive,
                          onChanged: (value) {
                            setState(() {
                              _options[index] = DropdownOption(
                                value: option.value,
                                label: option.label,
                                isActive: value,
                                sortOrder: option.sortOrder,
                              );
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() => _options.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final repo = ref.read(systemConfigRepositoryProvider);
            await repo.updateDropdownOptions(field: widget.field, options: _options, userId: widget.userId);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addOption() {
    final valueController = TextEditingController();
    final labelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: valueController, decoration: const InputDecoration(labelText: 'Value (unique identifier)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label (display name)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (valueController.text.isNotEmpty && labelController.text.isNotEmpty) {
                setState(() {
                  _options.add(DropdownOption(
                    value: valueController.text.trim().toLowerCase().replaceAll(' ', '-'),
                    label: labelController.text.trim(),
                    isActive: true,
                    sortOrder: _options.length,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// APPROVAL WORKFLOW TAB
// ============================================================================

class _ApprovalWorkflowTab extends ConsumerWidget {
  const _ApprovalWorkflowTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(systemConfigProvider);
    final user = ref.watch(currentUserProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return configAsync.when(
      data: (config) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approval Workflow', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Configure approval chain and thresholds', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),

              // Auto-Approve Threshold
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed, color: Colors.green),
                          const SizedBox(width: 12),
                          Text('Auto-Approval', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              config.autoApproveThreshold > 0
                                  ? 'Projects under ${currencyFormat.format(config.autoApproveThreshold)} are auto-approved'
                                  : 'Auto-approval is disabled',
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _editAutoApprove(context, ref, config, user?.uid ?? ''),
                            child: const Text('Configure'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Approval Chain
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_tree, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text('Approval Chain', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _editApprovalChain(context, ref, config, user?.uid ?? ''),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Chain'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (config.approvalChain.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No approval levels configured'),
                          ),
                        )
                      else
                        ...config.approvalChain.map((level) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text('${level.order}'),
                            ),
                            title: Text(level.name),
                            subtitle: Text('Role: ${level.role}'),
                            trailing: Text(
                              level.maxApprovalAmount != null
                                  ? 'Up to ${currencyFormat.format(level.maxApprovalAmount)}'
                                  : 'Unlimited',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _editAutoApprove(BuildContext context, WidgetRef ref, SystemConfig config, String userId) {
    final controller = TextEditingController(text: config.autoApproveThreshold > 0 ? config.autoApproveThreshold.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Approval Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Projects with total investment under this amount will be auto-approved.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Threshold Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Set to 0 to disable auto-approval',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              final repo = ref.read(systemConfigRepositoryProvider);
              await repo.updateAutoApproveThreshold(amount, userId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editApprovalChain(BuildContext context, WidgetRef ref, SystemConfig config, String userId) {
    showDialog(
      context: context,
      builder: (context) => _ApprovalChainDialog(config: config, userId: userId),
    );
  }
}

class _ApprovalChainDialog extends ConsumerStatefulWidget {
  final SystemConfig config;
  final String userId;

  const _ApprovalChainDialog({required this.config, required this.userId});

  @override
  ConsumerState<_ApprovalChainDialog> createState() => _ApprovalChainDialogState();
}

class _ApprovalChainDialogState extends ConsumerState<_ApprovalChainDialog> {
  late List<ApprovalLevel> _chain;

  @override
  void initState() {
    super.initState();
    _chain = List.from(widget.config.approvalChain);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Edit Approval Chain'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _chain.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _chain.removeAt(oldIndex);
                    _chain.insert(newIndex, item);
                    // Update orders
                    for (var i = 0; i < _chain.length; i++) {
                      _chain[i] = _chain[i].copyWith(order: i + 1);
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final level = _chain[index];
                  return Card(
                    key: ValueKey(level.id),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(level.name),
                      subtitle: Text('Role: ${level.role} | Max: ${level.maxApprovalAmount != null ? currencyFormat.format(level.maxApprovalAmount) : "Unlimited"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editLevel(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() => _chain.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            TextButton.icon(
              onPressed: _addLevel,
              icon: const Icon(Icons.add),
              label: const Text('Add Approval Level'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final repo = ref.read(systemConfigRepositoryProvider);
            await repo.updateApprovalChain(_chain, widget.userId);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addLevel() {
    _showLevelDialog(null, (level) {
      setState(() => _chain.add(level.copyWith(order: _chain.length + 1)));
    });
  }

  void _editLevel(int index) {
    _showLevelDialog(_chain[index], (level) {
      setState(() => _chain[index] = level);
    });
  }

  void _showLevelDialog(ApprovalLevel? existing, Function(ApprovalLevel) onSave) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final roleController = TextEditingController(text: existing?.role ?? '');
    final maxController = TextEditingController(text: existing?.maxApprovalAmount?.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing != null ? 'Edit Level' : 'Add Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Level Name (e.g., Manager)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role Key (e.g., manager)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max Approval Amount', prefixText: '\$ ', border: OutlineInputBorder(), helperText: 'Leave empty for unlimited'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && roleController.text.isNotEmpty) {
                final maxAmount = double.tryParse(maxController.text);
                onSave(ApprovalLevel(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  role: roleController.text.trim().toLowerCase(),
                  order: existing?.order ?? 0,
                  maxApprovalAmount: maxAmount,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BULK PROJECTS TAB
// ============================================================================

class _BulkProjectsTab extends ConsumerStatefulWidget {
  const _BulkProjectsTab();

  @override
  ConsumerState<_BulkProjectsTab> createState() => _BulkProjectsTabState();
}

class _BulkProjectsTabState extends ConsumerState<_BulkProjectsTab> {
  final Set<String> _selectedIds = {};
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context, ) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              // Status filter
              DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _statusFilter = value);
                },
              ),
              const SizedBox(width: 16),
              Text('${_selectedIds.length} selected'),
              const Spacer(),
              if (_selectedIds.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () => _bulkApprove(user?.uid ?? ''),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve Selected'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _bulkReject(user?.uid ?? ''),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject Selected'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedIds.clear()),
                  child: const Text('Clear Selection'),
                ),
              ],
            ],
          ),
        ),

        // Projects list
        Expanded(
          child: projectsAsync.when(
            data: (projects) {
              final filtered = projects.where((p) {
                if (_statusFilter == 'all') return true;
                if (_statusFilter == 'pending') return p.status == ProjectStatus.pendingApproval || p.status == ProjectStatus.submitted;
                if (_statusFilter == 'draft') return p.status == ProjectStatus.draft;
                if (_statusFilter == 'approved') return p.status == ProjectStatus.approved;
                if (_statusFilter == 'rejected') return p.status == ProjectStatus.rejected;
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No projects match the filter'));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final project = filtered[index];
                  final isSelected = _selectedIds.contains(project.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(project.id);
                        } else {
                          _selectedIds.remove(project.id);
                        }
                      });
                    },
                    title: Text(project.projectName),
                    subtitle: Text('${project.pfrNumber} | ${project.segment} | ${project.status.displayName}'),
                    secondary: _StatusChipSmall(status: project.status),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _bulkApprove(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Approve'),
        content: Text('Approve ${_selectedIds.length} selected projects?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve All')),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(projectRepositoryProvider);
      for (final id in _selectedIds) {
        final project = await repo.getProjectById(id);
        if (project != null) {
          await repo.updateProject(project.copyWith(
            status: ProjectStatus.approved,
            statusHistory: [
              ...project.statusHistory,
              StatusNote(
                status: ProjectStatus.approved,
                note: 'Bulk approved by admin',
                timestamp: DateTime.now(),
                userId: userId,
              ),
            ],
          ));
        }
      }
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projects approved'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _bulkReject(String userId) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Reject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${_selectedIds.length} selected projects?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(projectRepositoryProvider);
      final note = noteController.text.isNotEmpty ? noteController.text : 'Bulk rejected by admin';
      for (final id in _selectedIds) {
        final project = await repo.getProjectById(id);
        if (project != null) {
          await repo.updateProject(project.copyWith(
            status: ProjectStatus.rejected,
            statusHistory: [
              ...project.statusHistory,
              StatusNote(
                status: ProjectStatus.rejected,
                note: note,
                timestamp: DateTime.now(),
                userId: userId,
              ),
            ],
          ));
        }
      }
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projects rejected'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatusChipSmall extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChipSmall({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status.displayName, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
