import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project_template.dart';
import '../../providers/template_providers.dart';

/// Dialog to select a project template when creating a new project
class TemplateSelector extends ConsumerStatefulWidget {
  const TemplateSelector({super.key});

  @override
  ConsumerState<TemplateSelector> createState() => _TemplateSelectorState();

  /// Show the template selector dialog and return the selected template
  static Future<ProjectTemplate?> show(BuildContext context) {
    return showDialog<ProjectTemplate>(
      context: context,
      builder: (context) => const TemplateSelector(),
    );
  }
}

class _TemplateSelectorState extends ConsumerState<TemplateSelector> {
  TemplateCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(allTemplatesProvider);
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Select a Template',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a template to pre-fill your project with common settings',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Filters
              Row(
                children: [
                  // Search
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search templates...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category filter
                  DropdownButton<TemplateCategory?>(
                    value: _selectedCategory,
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...TemplateCategory.values.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.displayName),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Templates list
              Expanded(
                child: templatesAsync.when(
                  data: (templates) {
                    var filtered = templates;

                    // Apply category filter
                    if (_selectedCategory != null) {
                      filtered = filtered
                          .where((t) => t.category == _selectedCategory)
                          .toList();
                    }

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      filtered = filtered
                          .where((t) =>
                              t.name.toLowerCase().contains(query) ||
                              (t.description?.toLowerCase().contains(query) ?? false))
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No templates found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final template = filtered[index];
                        return _TemplateCard(
                          template: template,
                          onTap: () => Navigator.pop(context, template),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error loading templates: $e'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Initialize default templates if none exist
                      ref.read(initializeDefaultTemplatesProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Default Templates'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Return null to start from scratch
                          Navigator.pop(context, null);
                        },
                        child: const Text('Start from Scratch'),
                      ),
                    ],
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

class _TemplateCard extends StatelessWidget {
  final ProjectTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(template.category),
                    color: _getCategoryColor(template.category),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          template.category.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (template.isSystemTemplate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'System',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              if (template.description != null) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    template.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Show what's included
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (template.defaultCapExItems.isNotEmpty)
                    _IncludedChip(label: 'CapEx'),
                  if (template.defaultOpExItems.isNotEmpty)
                    _IncludedChip(label: 'OpEx'),
                  if (template.defaultBenefitItems.isNotEmpty)
                    _IncludedChip(label: 'Benefits'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.itInfrastructure:
        return Icons.computer;
      case TemplateCategory.realEstate:
        return Icons.business;
      case TemplateCategory.marketing:
        return Icons.campaign;
      case TemplateCategory.operations:
        return Icons.settings;
      case TemplateCategory.technology:
        return Icons.memory;
      case TemplateCategory.other:
        return Icons.description;
    }
  }

  Color _getCategoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.itInfrastructure:
        return Colors.blue;
      case TemplateCategory.realEstate:
        return Colors.green;
      case TemplateCategory.marketing:
        return Colors.orange;
      case TemplateCategory.operations:
        return Colors.purple;
      case TemplateCategory.technology:
        return Colors.teal;
      case TemplateCategory.other:
        return Colors.grey;
    }
  }
}

class _IncludedChip extends StatelessWidget {
  final String label;

  const _IncludedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}
