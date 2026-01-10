import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/financial_items.dart';
import '../../../data/models/project.dart';
import '../../../providers/providers.dart';

class FinancialInputScreen extends ConsumerStatefulWidget {
  final String projectId;

  const FinancialInputScreen({super.key, required this.projectId});

  @override
  ConsumerState<FinancialInputScreen> createState() => _FinancialInputScreenState();
}

class _FinancialInputScreenState extends ConsumerState<FinancialInputScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Line Items'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/project/${widget.projectId}/analysis'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'CapEx', icon: Icon(Icons.build)),
            Tab(text: 'OpEx', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Benefits', icon: Icon(Icons.trending_up)),
            Tab(text: 'Actuals', icon: Icon(Icons.fact_check)),
          ],
        ),
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _CapExTab(project: project),
              _OpExTab(project: project),
              _BenefitsTab(project: project),
              _ActualsTab(project: project),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CapExTab extends ConsumerWidget {
  final Project project;

  const _CapExTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(capexItemsProvider(project.id));

    return itemsAsync.when(
      data: (items) => _LineItemsList<CapExItem>(
        items: items,
        project: project,
        emptyMessage: 'No CapEx items yet',
        onAdd: () => _showCapExDialog(context, ref, project, null),
        onEdit: (item) => _showCapExDialog(context, ref, project, item),
        onDelete: (item) => _deleteCapEx(context, ref, item),
        itemBuilder: (item) => _CapExListTile(item: item, project: project),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showCapExDialog(BuildContext context, WidgetRef ref, Project project, CapExItem? item) {
    showDialog(
      context: context,
      builder: (context) => _CapExDialog(project: project, item: item),
    );
  }

  Future<void> _deleteCapEx(BuildContext context, WidgetRef ref, CapExItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete CapEx Item'),
        content: Text('Are you sure you want to delete "${item.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(capexRepositoryProvider).delete(item.projectId, item.id);
    }
  }
}

class _OpExTab extends ConsumerWidget {
  final Project project;

  const _OpExTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(opexItemsProvider(project.id));

    return itemsAsync.when(
      data: (items) => _LineItemsList<OpExItem>(
        items: items,
        project: project,
        emptyMessage: 'No OpEx items yet',
        onAdd: () => _showOpExDialog(context, ref, project, null),
        onEdit: (item) => _showOpExDialog(context, ref, project, item),
        onDelete: (item) => _deleteOpEx(context, ref, item),
        itemBuilder: (item) => _OpExListTile(item: item, project: project),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showOpExDialog(BuildContext context, WidgetRef ref, Project project, OpExItem? item) {
    showDialog(
      context: context,
      builder: (context) => _OpExDialog(project: project, item: item),
    );
  }

  Future<void> _deleteOpEx(BuildContext context, WidgetRef ref, OpExItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete OpEx Item'),
        content: Text('Are you sure you want to delete "${item.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(opexRepositoryProvider).delete(item.projectId, item.id);
    }
  }
}

class _BenefitsTab extends ConsumerWidget {
  final Project project;

  const _BenefitsTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(benefitItemsProvider(project.id));

    return itemsAsync.when(
      data: (items) => _LineItemsList<BenefitItem>(
        items: items,
        project: project,
        emptyMessage: 'No Benefit items yet',
        onAdd: () => _showBenefitDialog(context, ref, project, null),
        onEdit: (item) => _showBenefitDialog(context, ref, project, item),
        onDelete: (item) => _deleteBenefit(context, ref, item),
        itemBuilder: (item) => _BenefitListTile(item: item, project: project),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showBenefitDialog(BuildContext context, WidgetRef ref, Project project, BenefitItem? item) {
    showDialog(
      context: context,
      builder: (context) => _BenefitDialog(project: project, item: item),
    );
  }

  Future<void> _deleteBenefit(BuildContext context, WidgetRef ref, BenefitItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Benefit Item'),
        content: Text('Are you sure you want to delete "${item.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(benefitRepositoryProvider).delete(item.projectId, item.id);
    }
  }
}

class _ActualsTab extends ConsumerWidget {
  final Project project;

  const _ActualsTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialsAsync = ref.watch(projectFinancialsProvider((
      projectId: project.id,
      startYear: project.startYear,
    )));

    return financialsAsync.when(
      data: (financials) => _ActualsEntryView(project: project, financials: financials),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ActualsEntryView extends ConsumerWidget {
  final Project project;
  final ProjectFinancials financials;

  const _ActualsEntryView({required this.project, required this.financials});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final hasData = financials.capexItems.isNotEmpty ||
        financials.opexItems.isNotEmpty ||
        financials.benefitItems.isNotEmpty;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No financial items to track actuals for',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Add CapEx, OpEx, or Benefits first',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget vs Actuals Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Total Budget',
                        value: currencyFormat.format(financials.totalCosts + financials.totalBenefits),
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Total Actuals',
                        value: currencyFormat.format(financials.totalActualCosts + financials.totalActualBenefits),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // CapEx Actuals Section
        if (financials.capexItems.isNotEmpty) ...[
          _SectionHeader(title: 'CapEx Actuals', icon: Icons.build, color: Colors.blue),
          ...financials.capexItems.map((item) => _ActualEntryCard(
            description: item.description,
            category: item.category.displayName,
            budgetAmounts: item.yearlyAmounts,
            actualAmounts: item.actualYearlyAmounts,
            startYear: project.startYear,
            isBenefit: false,
            onSave: (actuals) async {
              final updated = item.copyWith(actualYearlyAmounts: actuals);
              await ref.read(capexRepositoryProvider).update(updated);
            },
          )),
          const SizedBox(height: 16),
        ],

        // OpEx Actuals Section
        if (financials.opexItems.isNotEmpty) ...[
          _SectionHeader(title: 'OpEx Actuals', icon: Icons.monetization_on, color: Colors.orange),
          ...financials.opexItems.map((item) => _ActualEntryCard(
            description: item.description,
            category: item.category.displayName,
            budgetAmounts: item.yearlyAmounts,
            actualAmounts: item.actualYearlyAmounts,
            startYear: project.startYear,
            isBenefit: false,
            onSave: (actuals) async {
              final updated = item.copyWith(actualYearlyAmounts: actuals);
              await ref.read(opexRepositoryProvider).update(updated);
            },
          )),
          const SizedBox(height: 16),
        ],

        // Benefits Actuals Section
        if (financials.benefitItems.isNotEmpty) ...[
          _SectionHeader(title: 'Benefits Actuals', icon: Icons.trending_up, color: Colors.green),
          ...financials.benefitItems.map((item) => _ActualEntryCard(
            description: item.description,
            category: '${item.category.displayName} - ${item.businessUnit.displayName}',
            budgetAmounts: item.yearlyAmounts,
            actualAmounts: item.actualYearlyAmounts,
            startYear: project.startYear,
            isBenefit: true,
            onSave: (actuals) async {
              final updated = item.copyWith(actualYearlyAmounts: actuals);
              await ref.read(benefitRepositoryProvider).update(updated);
            },
          )),
        ],
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActualEntryCard extends StatefulWidget {
  final String description;
  final String category;
  final Map<int, double> budgetAmounts;
  final Map<int, double> actualAmounts;
  final int startYear;
  final bool isBenefit;
  final Future<void> Function(Map<int, double> actuals) onSave;

  const _ActualEntryCard({
    required this.description,
    required this.category,
    required this.budgetAmounts,
    required this.actualAmounts,
    required this.startYear,
    required this.isBenefit,
    required this.onSave,
  });

  @override
  State<_ActualEntryCard> createState() => _ActualEntryCardState();
}

class _ActualEntryCardState extends State<_ActualEntryCard> {
  late Map<int, TextEditingController> _controllers;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (int i = 0; i < FinancialConstants.projectionYears; i++) {
      final year = widget.startYear + i;
      final amount = widget.actualAmounts[year] ?? 0.0;
      _controllers[year] = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : '');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final compactFormat = NumberFormat.compact();
    final totalBudget = widget.budgetAmounts.values.fold(0.0, (sum, v) => sum + v);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(widget.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Text('Budget: ${currencyFormat.format(totalBudget)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            // Year columns
            Row(
              children: List.generate(FinancialConstants.projectionYears, (i) {
                final year = widget.startYear + i;
                final budget = widget.budgetAmounts[year] ?? 0.0;
                final actualText = _controllers[year]?.text ?? '';
                final actual = double.tryParse(actualText) ?? 0.0;
                final variance = widget.isBenefit ? (actual - budget) : (budget - actual);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Text('Y${i + 1}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        Text('B: ${budget == 0 ? '-' : compactFormat.format(budget)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 36,
                          child: TextFormField(
                            controller: _controllers[year],
                            decoration: InputDecoration(
                              prefixText: '\$',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => setState(() => _hasChanges = true),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (actual > 0 || budget > 0)
                          Text(
                            '${variance >= 0 ? '+' : ''}${compactFormat.format(variance)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: variance >= 0 ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            // Save button
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: _isSaving ? null : _saveActuals,
                    child: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveActuals() async {
    setState(() => _isSaving = true);
    try {
      final actuals = <int, double>{};
      _controllers.forEach((year, controller) {
        final value = double.tryParse(controller.text) ?? 0;
        if (value > 0) actuals[year] = value;
      });
      await widget.onSave(actuals);
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actuals saved'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _LineItemsList<T> extends StatelessWidget {
  final List<T> items;
  final Project project;
  final String emptyMessage;
  final VoidCallback onAdd;
  final void Function(T item) onEdit;
  final void Function(T item) onDelete;
  final Widget Function(T item) itemBuilder;

  const _LineItemsList({
    required this.items,
    required this.project,
    required this.emptyMessage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    double total = 0;

    if (T == CapExItem) {
      total = (items as List<CapExItem>).fold(0.0, (sum, item) => sum + item.totalAmount);
    } else if (T == OpExItem) {
      total = (items as List<OpExItem>).fold(0.0, (sum, item) => sum + item.totalAmount);
    } else if (T == BenefitItem) {
      total = (items as List<BenefitItem>).fold(0.0, (sum, item) => sum + item.totalAmount);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${currencyFormat.format(total)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Item'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => onEdit(item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(child: itemBuilder(item)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => onDelete(item),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CapExListTile extends StatelessWidget {
  final CapExItem item;
  final Project project;

  const _CapExListTile({required this.item, required this.project});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(currencyFormat.format(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${item.category.displayName} • ${item.usefulLifeMonths} months useful life',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        _YearlyAmountsRow(yearlyAmounts: item.yearlyAmounts, startYear: project.startYear),
      ],
    );
  }
}

class _OpExListTile extends StatelessWidget {
  final OpExItem item;
  final Project project;

  const _OpExListTile({required this.item, required this.project});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(currencyFormat.format(item.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.category.displayName,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        _YearlyAmountsRow(yearlyAmounts: item.yearlyAmounts, startYear: project.startYear),
      ],
    );
  }
}

class _BenefitListTile extends StatelessWidget {
  final BenefitItem item;
  final Project project;

  const _BenefitListTile({required this.item, required this.project});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(currencyFormat.format(item.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${item.category.displayName} • ${item.businessUnit.displayName}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        _YearlyAmountsRow(yearlyAmounts: item.yearlyAmounts, startYear: project.startYear, isPositive: true),
      ],
    );
  }
}

class _YearlyAmountsRow extends StatelessWidget {
  final Map<int, double> yearlyAmounts;
  final int startYear;
  final bool isPositive;

  const _YearlyAmountsRow({
    required this.yearlyAmounts,
    required this.startYear,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final compactFormat = NumberFormat.compact();

    return Row(
      children: List.generate(FinancialConstants.projectionYears, (i) {
        final year = startYear + i;
        final amount = yearlyAmounts[year] ?? 0;
        return Expanded(
          child: Column(
            children: [
              Text('Y${i + 1}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              Text(
                amount == 0 ? '-' : compactFormat.format(amount),
                style: TextStyle(
                  fontSize: 11,
                  color: amount == 0 ? Colors.grey : (isPositive ? Colors.green : null),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Dialogs for adding/editing items
class _CapExDialog extends ConsumerStatefulWidget {
  final Project project;
  final CapExItem? item;

  const _CapExDialog({required this.project, this.item});

  @override
  ConsumerState<_CapExDialog> createState() => _CapExDialogState();
}

class _CapExDialogState extends ConsumerState<_CapExDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late CapExCategory _category;
  late int _usefulLifeMonths;
  late Map<int, TextEditingController> _yearControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _category = widget.item?.category ?? CapExCategory.software;
    _usefulLifeMonths = widget.item?.usefulLifeMonths ?? _category.defaultUsefulLifeMonths;
    _yearControllers = {};

    for (int i = 0; i < FinancialConstants.projectionYears; i++) {
      final year = widget.project.startYear + i;
      final amount = widget.item?.yearlyAmounts[year] ?? 0.0;
      _yearControllers[year] = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : '');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final controller in _yearControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add CapEx Item' : 'Edit CapEx Item'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CapExCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: CapExCategory.values.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c.displayName))
                  ).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _category = v;
                        _usefulLifeMonths = v.defaultUsefulLifeMonths;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _usefulLifeMonths.toString(),
                  decoration: const InputDecoration(labelText: 'Useful Life (months)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _usefulLifeMonths = int.tryParse(v) ?? _usefulLifeMonths,
                ),
                const SizedBox(height: 24),
                Text('Yearly Amounts', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildYearlyInputs(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(widget.item == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildYearlyInputs() {
    return Row(
      children: List.generate(FinancialConstants.projectionYears, (i) {
        final year = widget.project.startYear + i;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextFormField(
              controller: _yearControllers[year],
              decoration: InputDecoration(
                labelText: 'Y${i + 1}',
                prefixText: '\$',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final yearlyAmounts = <int, double>{};
    _yearControllers.forEach((year, controller) {
      final value = double.tryParse(controller.text) ?? 0;
      if (value > 0) yearlyAmounts[year] = value;
    });

    final now = DateTime.now();
    final item = CapExItem(
      id: widget.item?.id ?? '',
      projectId: widget.project.id,
      category: _category,
      description: _descriptionController.text,
      yearlyAmounts: yearlyAmounts,
      usefulLifeMonths: _usefulLifeMonths,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final repo = ref.read(capexRepositoryProvider);
      if (widget.item == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _OpExDialog extends ConsumerStatefulWidget {
  final Project project;
  final OpExItem? item;

  const _OpExDialog({required this.project, this.item});

  @override
  ConsumerState<_OpExDialog> createState() => _OpExDialogState();
}

class _OpExDialogState extends ConsumerState<_OpExDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late OpExCategory _category;
  late Map<int, TextEditingController> _yearControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _category = widget.item?.category ?? OpExCategory.maintenanceFees;
    _yearControllers = {};

    for (int i = 0; i < FinancialConstants.projectionYears; i++) {
      final year = widget.project.startYear + i;
      final amount = widget.item?.yearlyAmounts[year] ?? 0.0;
      _yearControllers[year] = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : '');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final controller in _yearControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add OpEx Item' : 'Edit OpEx Item'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<OpExCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: OpExCategory.values.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c.displayName))
                  ).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 24),
                Text('Yearly Amounts', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildYearlyInputs(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(widget.item == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildYearlyInputs() {
    return Row(
      children: List.generate(FinancialConstants.projectionYears, (i) {
        final year = widget.project.startYear + i;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextFormField(
              controller: _yearControllers[year],
              decoration: InputDecoration(
                labelText: 'Y${i + 1}',
                prefixText: '\$',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final yearlyAmounts = <int, double>{};
    _yearControllers.forEach((year, controller) {
      final value = double.tryParse(controller.text) ?? 0;
      if (value > 0) yearlyAmounts[year] = value;
    });

    final now = DateTime.now();
    final item = OpExItem(
      id: widget.item?.id ?? '',
      projectId: widget.project.id,
      category: _category,
      description: _descriptionController.text,
      yearlyAmounts: yearlyAmounts,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final repo = ref.read(opexRepositoryProvider);
      if (widget.item == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _BenefitDialog extends ConsumerStatefulWidget {
  final Project project;
  final BenefitItem? item;

  const _BenefitDialog({required this.project, this.item});

  @override
  ConsumerState<_BenefitDialog> createState() => _BenefitDialogState();
}

class _BenefitDialogState extends ConsumerState<_BenefitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late BenefitCategory _category;
  late BusinessUnit _businessUnit;
  late Map<int, TextEditingController> _yearControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _category = widget.item?.category ?? BenefitCategory.expenseReductions;
    _businessUnit = widget.item?.businessUnit ?? BusinessUnit.corporate;
    _yearControllers = {};

    for (int i = 0; i < FinancialConstants.projectionYears; i++) {
      final year = widget.project.startYear + i;
      final amount = widget.item?.yearlyAmounts[year] ?? 0.0;
      _yearControllers[year] = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : '');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final controller in _yearControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Benefit Item' : 'Edit Benefit Item'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BenefitCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: BenefitCategory.values.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c.displayName))
                  ).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BusinessUnit>(
                  initialValue: _businessUnit,
                  decoration: const InputDecoration(labelText: 'Business Unit'),
                  items: BusinessUnit.values.map((bu) =>
                    DropdownMenuItem(value: bu, child: Text(bu.displayName))
                  ).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _businessUnit = v);
                  },
                ),
                const SizedBox(height: 24),
                Text('Yearly Amounts', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildYearlyInputs(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(widget.item == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildYearlyInputs() {
    return Row(
      children: List.generate(FinancialConstants.projectionYears, (i) {
        final year = widget.project.startYear + i;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextFormField(
              controller: _yearControllers[year],
              decoration: InputDecoration(
                labelText: 'Y${i + 1}',
                prefixText: '\$',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final yearlyAmounts = <int, double>{};
    _yearControllers.forEach((year, controller) {
      final value = double.tryParse(controller.text) ?? 0;
      if (value > 0) yearlyAmounts[year] = value;
    });

    final now = DateTime.now();
    final item = BenefitItem(
      id: widget.item?.id ?? '',
      projectId: widget.project.id,
      category: _category,
      businessUnit: _businessUnit,
      description: _descriptionController.text,
      yearlyAmounts: yearlyAmounts,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final repo = ref.read(benefitRepositoryProvider);
      if (widget.item == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
