import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/project.dart';
import '../../../providers/providers.dart';

/// Risk probability levels
enum RiskProbability {
  veryLow(1, 'Very Low', '< 10%'),
  low(2, 'Low', '10-25%'),
  medium(3, 'Medium', '25-50%'),
  high(4, 'High', '50-75%'),
  veryHigh(5, 'Very High', '> 75%');

  final int value;
  final String label;
  final String range;

  const RiskProbability(this.value, this.label, this.range);
}

/// Risk impact levels
enum RiskImpact {
  negligible(1, 'Negligible', '< 5%'),
  minor(2, 'Minor', '5-10%'),
  moderate(3, 'Moderate', '10-25%'),
  major(4, 'Major', '25-50%'),
  severe(5, 'Severe', '> 50%');

  final int value;
  final String label;
  final String percentImpact;

  const RiskImpact(this.value, this.label, this.percentImpact);
}

/// Risk factor for a project
class RiskFactor {
  final String name;
  final String description;
  final RiskProbability probability;
  final RiskImpact impact;
  final String category;

  const RiskFactor({
    required this.name,
    required this.description,
    required this.probability,
    required this.impact,
    required this.category,
  });

  int get riskScore => probability.value * impact.value;

  String get riskLevel {
    if (riskScore <= 4) return 'Low';
    if (riskScore <= 9) return 'Medium';
    if (riskScore <= 16) return 'High';
    return 'Critical';
  }

  Color get riskColor {
    if (riskScore <= 4) return Colors.green;
    if (riskScore <= 9) return Colors.orange;
    if (riskScore <= 16) return Colors.deepOrange;
    return Colors.red;
  }

  RiskFactor copyWith({
    String? name,
    String? description,
    RiskProbability? probability,
    RiskImpact? impact,
    String? category,
  }) {
    return RiskFactor(
      name: name ?? this.name,
      description: description ?? this.description,
      probability: probability ?? this.probability,
      impact: impact ?? this.impact,
      category: category ?? this.category,
    );
  }
}

/// Selected project for risk assessment
final riskAssessmentProjectProvider = StateProvider<Project?>((ref) => null);

/// Risk factors for the project
final projectRiskFactorsProvider =
    StateProvider<List<RiskFactor>>((ref) => _defaultRiskFactors);

/// Default risk factors applicable to most IT projects
const _defaultRiskFactors = [
  RiskFactor(
    name: 'Technology Risk',
    description: 'New or unproven technology may not perform as expected',
    probability: RiskProbability.medium,
    impact: RiskImpact.moderate,
    category: 'Technical',
  ),
  RiskFactor(
    name: 'Integration Complexity',
    description: 'Difficulty integrating with existing systems',
    probability: RiskProbability.medium,
    impact: RiskImpact.major,
    category: 'Technical',
  ),
  RiskFactor(
    name: 'Scope Creep',
    description: 'Requirements expand beyond original scope',
    probability: RiskProbability.high,
    impact: RiskImpact.moderate,
    category: 'Project',
  ),
  RiskFactor(
    name: 'Resource Availability',
    description: 'Key resources may not be available when needed',
    probability: RiskProbability.medium,
    impact: RiskImpact.moderate,
    category: 'Resource',
  ),
  RiskFactor(
    name: 'Vendor Dependency',
    description: 'Reliance on external vendors for delivery',
    probability: RiskProbability.low,
    impact: RiskImpact.major,
    category: 'External',
  ),
  RiskFactor(
    name: 'User Adoption',
    description: 'End users may resist or poorly adopt the solution',
    probability: RiskProbability.medium,
    impact: RiskImpact.moderate,
    category: 'Organizational',
  ),
  RiskFactor(
    name: 'Budget Overrun',
    description: 'Project costs exceed approved budget',
    probability: RiskProbability.medium,
    impact: RiskImpact.major,
    category: 'Financial',
  ),
  RiskFactor(
    name: 'Schedule Delay',
    description: 'Project timeline extends beyond plan',
    probability: RiskProbability.high,
    impact: RiskImpact.moderate,
    category: 'Project',
  ),
];

class RiskAssessmentScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const RiskAssessmentScreen({super.key, this.projectId});

  @override
  ConsumerState<RiskAssessmentScreen> createState() =>
      _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends ConsumerState<RiskAssessmentScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProject(widget.projectId!);
      });
    }
  }

  void _loadProject(String projectId) async {
    final project =
        await ref.read(projectRepositoryProvider).getProjectById(projectId);
    if (project != null && mounted) {
      ref.read(riskAssessmentProjectProvider.notifier).state = project;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProject = ref.watch(riskAssessmentProjectProvider);
    final riskFactors = ref.watch(projectRiskFactorsProvider);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment'),
        actions: [
          if (selectedProject != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(projectRiskFactorsProvider.notifier).state = [
                  ..._defaultRiskFactors
                ];
              },
              tooltip: 'Reset to defaults',
            ),
        ],
      ),
      body: Row(
        children: [
          // Project selection panel
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select Project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: projectsAsync.when(
                    data: (projects) {
                      final approvedProjects = projects
                          .where((p) =>
                              p.status == ProjectStatus.approved ||
                              p.status == ProjectStatus.submitted ||
                              p.status == ProjectStatus.pendingApproval)
                          .toList();

                      if (approvedProjects.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No approved projects available for risk assessment',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: approvedProjects.length,
                        itemBuilder: (context, index) {
                          final project = approvedProjects[index];
                          final isSelected =
                              selectedProject?.id == project.id;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor:
                                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            leading: Icon(
                              Icons.folder,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                            title: Text(
                              project.projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              project.businessUnit,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () {
                              ref
                                  .read(riskAssessmentProjectProvider.notifier)
                                  .state = project;
                              // Reset risk factors when project changes
                              ref
                                  .read(projectRiskFactorsProvider.notifier)
                                  .state = [..._defaultRiskFactors];
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),

          // Risk assessment content
          Expanded(
            child: selectedProject == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a project to assess risks',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _RiskAssessmentContent(
                    project: selectedProject,
                    riskFactors: riskFactors,
                    onShowAddRiskDialog: () => _showAddRiskDialog(context),
                    onUpdateRiskFactor: _updateRiskFactor,
                    onRemoveRiskFactor: _removeRiskFactor,
                  ),
          ),
        ],
      ),
      floatingActionButton: selectedProject != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddRiskDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Risk'),
            )
          : null,
    );
  }

  void _updateRiskFactor(RiskFactor oldRisk, RiskFactor newRisk) {
    final factors = ref.read(projectRiskFactorsProvider);
    final index = factors.indexOf(oldRisk);
    if (index != -1) {
      final newList = [...factors];
      newList[index] = newRisk;
      ref.read(projectRiskFactorsProvider.notifier).state = newList;
    }
  }

  void _removeRiskFactor(RiskFactor risk) {
    final factors = ref.read(projectRiskFactorsProvider);
    ref.read(projectRiskFactorsProvider.notifier).state =
        factors.where((r) => r != risk).toList();
  }

  void _showAddRiskDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Technical';
    RiskProbability selectedProbability = RiskProbability.medium;
    RiskImpact selectedImpact = RiskImpact.moderate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Risk Factor'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Risk Name',
                    hintText: 'e.g., Technical Complexity',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the risk factor...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Technical', 'Project', 'Resource', 'External',
                          'Organizational', 'Financial']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RiskProbability>(
                        initialValue: selectedProbability,
                        decoration:
                            const InputDecoration(labelText: 'Probability'),
                        items: RiskProbability.values
                            .map((p) => DropdownMenuItem(
                                value: p, child: Text(p.label)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedProbability = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<RiskImpact>(
                        initialValue: selectedImpact,
                        decoration: const InputDecoration(labelText: 'Impact'),
                        items: RiskImpact.values
                            .map((i) => DropdownMenuItem(
                                value: i, child: Text(i.label)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedImpact = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newRisk = RiskFactor(
                    name: nameController.text,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : 'No description provided',
                    probability: selectedProbability,
                    impact: selectedImpact,
                    category: selectedCategory,
                  );
                  final factors = ref.read(projectRiskFactorsProvider);
                  ref.read(projectRiskFactorsProvider.notifier).state = [
                    ...factors,
                    newRisk
                  ];
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content widget that loads financials and displays risk assessment
class _RiskAssessmentContent extends ConsumerWidget {
  final Project project;
  final List<RiskFactor> riskFactors;
  final VoidCallback onShowAddRiskDialog;
  final void Function(RiskFactor, RiskFactor) onUpdateRiskFactor;
  final void Function(RiskFactor) onRemoveRiskFactor;

  const _RiskAssessmentContent({
    required this.project,
    required this.riskFactors,
    required this.onShowAddRiskDialog,
    required this.onUpdateRiskFactor,
    required this.onRemoveRiskFactor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialsAsync = ref.watch(projectFinancialsProvider((
      projectId: project.id,
      startYear: project.startYear,
    )));

    return financialsAsync.when(
      data: (financials) {
        final baseNPV = financials.calculateNPV(FinancialConstants.hurdleRate);
        return _RiskAssessmentBody(
          project: project,
          riskFactors: riskFactors,
          baseNPV: baseNPV,
          onUpdateRiskFactor: onUpdateRiskFactor,
          onRemoveRiskFactor: onRemoveRiskFactor,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading financials: $e')),
    );
  }
}

/// Body widget for risk assessment (with loaded financials)
class _RiskAssessmentBody extends StatelessWidget {
  final Project project;
  final List<RiskFactor> riskFactors;
  final double baseNPV;
  final void Function(RiskFactor, RiskFactor) onUpdateRiskFactor;
  final void Function(RiskFactor) onRemoveRiskFactor;

  const _RiskAssessmentBody({
    required this.project,
    required this.riskFactors,
    required this.baseNPV,
    required this.onUpdateRiskFactor,
    required this.onRemoveRiskFactor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectHeader(),
          const SizedBox(height: 24),
          _buildRiskMatrix(),
          const SizedBox(height: 24),
          _buildRiskFactorsList(),
          const SizedBox(height: 24),
          _buildProbabilityWeightedNPV(),
          const SizedBox(height: 24),
          _buildRiskSummary(),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.businessUnit} | ${project.segment}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: baseNPV >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('Base NPV', style: TextStyle(fontSize: 12)),
                  Text(
                    currencyFormat.format(baseNPV),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: baseNPV >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskMatrix() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Risk Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Plot of risk factors by probability and impact', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Center(
                      child: Text('PROBABILITY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: RiskProbability.values.reversed
                                    .map((p) => SizedBox(
                                          width: 60,
                                          child: Text(p.label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.right),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: _buildMatrixGrid()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 68),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: RiskImpact.values
                                .map((i) => Expanded(child: Text(i.label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('IMPACT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixGrid() {
    return Column(
      children: RiskProbability.values.reversed.map((prob) {
        return Expanded(
          child: Row(
            children: RiskImpact.values.map((impact) {
              final cellRisks = riskFactors.where((r) => r.probability == prob && r.impact == impact).toList();
              final score = prob.value * impact.value;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(color: _getMatrixCellColor(score), borderRadius: BorderRadius.circular(4)),
                  child: cellRisks.isEmpty
                      ? null
                      : Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: cellRisks
                                .map((r) => Tooltip(
                                      message: r.name,
                                      child: Container(
                                        margin: const EdgeInsets.all(2),
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade700),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Color _getMatrixCellColor(int score) {
    if (score <= 4) return Colors.green.shade200;
    if (score <= 9) return Colors.yellow.shade300;
    if (score <= 16) return Colors.orange.shade300;
    return Colors.red.shade300;
  }

  Widget _buildRiskFactorsList() {
    final sortedFactors = [...riskFactors]..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Risk Factors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${riskFactors.length} identified risks', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedFactors.map((risk) => _buildRiskFactorTile(risk)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFactorTile(RiskFactor risk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: risk.riskColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('${risk.riskScore}', style: TextStyle(fontWeight: FontWeight.bold, color: risk.riskColor))),
        ),
        title: Text(risk.name),
        subtitle: Row(children: [_buildChip(risk.category, Colors.blue), const SizedBox(width: 8), _buildChip(risk.riskLevel, risk.riskColor)]),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.description, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildRiskDropdown('Probability', risk.probability, RiskProbability.values, (v) {
                        if (v != null) onUpdateRiskFactor(risk, risk.copyWith(probability: v));
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRiskDropdown('Impact', risk.impact, RiskImpact.values, (v) {
                        if (v != null) onUpdateRiskFactor(risk, risk.copyWith(impact: v));
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onRemoveRiskFactor(risk),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildRiskDropdown<T>(String label, T currentValue, List<T> values, void Function(T?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: currentValue,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: values.map((v) => DropdownMenuItem(value: v, child: Text(v is RiskProbability ? v.label : v is RiskImpact ? v.label : v.toString(), style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildProbabilityWeightedNPV() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final scenarios = _calculateScenarios(baseNPV, riskFactors);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Probability-Weighted NPV Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('NPV adjusted for risk probability and impact', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildNPVCard('Base Case NPV', baseNPV, Colors.blue, 'No risk adjustment')),
                const SizedBox(width: 16),
                Expanded(child: _buildNPVCard('Expected NPV', scenarios['expected']!, Colors.purple, 'Probability-weighted')),
                const SizedBox(width: 16),
                Expanded(child: _buildNPVCard('Risk-Adjusted NPV', scenarios['riskAdjusted']!, scenarios['riskAdjusted']! >= 0 ? Colors.green : Colors.red, 'After risk mitigation')),
              ],
            ),
            const SizedBox(height: 24),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.5)},
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(padding: EdgeInsets.all(12), child: Text('Scenario', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(12), child: Text('Probability', style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(12), child: Text('NPV', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                _buildScenarioRow('Best Case (no risks)', 0.15, scenarios['bestCase']!, currencyFormat),
                _buildScenarioRow('Likely Case', 0.50, scenarios['likelyCase']!, currencyFormat),
                _buildScenarioRow('Worst Case (all risks)', 0.35, scenarios['worstCase']!, currencyFormat),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Expected NPV = (Best x 15%) + (Likely x 50%) + (Worst x 35%)\nRisk-Adjusted NPV accounts for mitigation strategies',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateScenarios(double npv, List<RiskFactor> risks) {
    double totalRiskImpact = 0;
    for (final risk in risks) {
      final probPercent = risk.probability.value * 0.15;
      final impactPercent = risk.impact.value * 0.10;
      totalRiskImpact += probPercent * impactPercent;
    }
    totalRiskImpact = totalRiskImpact.clamp(0.0, 0.8);

    final bestCase = npv * 1.1;
    final worstCase = npv * (1 - totalRiskImpact);
    final likelyCase = npv * (1 - totalRiskImpact * 0.5);
    final expected = (bestCase * 0.15) + (likelyCase * 0.50) + (worstCase * 0.35);
    final riskAdjusted = npv * (1 - totalRiskImpact * 0.5);

    return {'bestCase': bestCase, 'likelyCase': likelyCase, 'worstCase': worstCase, 'expected': expected, 'riskAdjusted': riskAdjusted};
  }

  Widget _buildNPVCard(String title, double value, Color color, String subtitle) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(currencyFormat.format(value), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  TableRow _buildScenarioRow(String scenario, double probability, double npv, NumberFormat format) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(scenario)),
        Padding(padding: const EdgeInsets.all(12), child: Text('${(probability * 100).toInt()}%')),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(format.format(npv), style: TextStyle(fontWeight: FontWeight.w500, color: npv >= 0 ? Colors.green.shade700 : Colors.red.shade700)),
        ),
      ],
    );
  }

  Widget _buildRiskSummary() {
    final criticalCount = riskFactors.where((r) => r.riskScore > 16).length;
    final highCount = riskFactors.where((r) => r.riskScore > 9 && r.riskScore <= 16).length;
    final mediumCount = riskFactors.where((r) => r.riskScore > 4 && r.riskScore <= 9).length;
    final lowCount = riskFactors.where((r) => r.riskScore <= 4).length;
    final avgScore = riskFactors.isEmpty ? 0.0 : riskFactors.map((r) => r.riskScore).reduce((a, b) => a + b) / riskFactors.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Risk Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              _buildSummaryItem('Critical', criticalCount, Colors.red),
              _buildSummaryItem('High', highCount, Colors.orange),
              _buildSummaryItem('Medium', mediumCount, Colors.yellow.shade700),
              _buildSummaryItem('Low', lowCount, Colors.green),
            ]),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Average Risk Score', style: TextStyle(color: Colors.grey.shade700)),
                Text(avgScore.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: avgScore / 25,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(avgScore <= 5 ? Colors.green : avgScore <= 10 ? Colors.yellow.shade700 : avgScore <= 15 ? Colors.orange : Colors.red),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(child: Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
