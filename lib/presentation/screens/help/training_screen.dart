import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use PFR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/help/metrics'),
            icon: const Icon(Icons.calculate),
            label: const Text('Metrics Guide'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(theme),
            const SizedBox(height: 24),
            Text(
              'Workflow Steps',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStep1Card(theme),
            const SizedBox(height: 16),
            _buildStep2Card(theme),
            const SizedBox(height: 16),
            _buildStep3Card(theme),
            const SizedBox(height: 16),
            _buildStep4Card(theme),
            const SizedBox(height: 16),
            _buildStep5Card(theme),
            const SizedBox(height: 24),
            _buildTipsCard(theme),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What is PFR?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Project Funding Request Application',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The PFR app helps you create, manage, and analyze project funding requests. '
              'It calculates key financial metrics like NPV, IRR, and Payback Period to help '
              'evaluate the viability of capital investments.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('Financial Analysis', Icons.analytics),
                _buildFeatureChip('PDF Export', Icons.picture_as_pdf),
                _buildFeatureChip('Multi-Year Projections', Icons.timeline),
                _buildFeatureChip('Cost Tracking', Icons.account_balance_wallet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildStep1Card(ThemeData theme) {
    return _StepCard(
      stepNumber: 1,
      title: 'Create a New Project',
      description: 'Start by creating a new project with basic information.',
      theme: theme,
      details: const [
        'Navigate to the Projects list from the home screen',
        'Click the "New Project" button',
        'Enter the PFR number (unique identifier)',
        'Provide a descriptive project name',
        'Select the business unit and segment',
      ],
      tip: 'Use a consistent naming convention for PFR numbers to make projects easier to find later.',
    );
  }

  Widget _buildStep2Card(ThemeData theme) {
    return _StepCard(
      stepNumber: 2,
      title: 'Enter Project Details',
      description: 'Fill in comprehensive project information.',
      theme: theme,
      details: const [
        'Set the project start and end dates',
        'Enter sponsor and requester information',
        'Add a business rationale explaining why this project is needed',
        'Configure project flags (budgeted, HOA reimbursed, etc.)',
        'Select the appropriate IC category if applicable',
      ],
      tip: 'A clear business rationale helps stakeholders understand the project\'s value.',
    );
  }

  Widget _buildStep3Card(ThemeData theme) {
    return _StepCard(
      stepNumber: 3,
      title: 'Add Financial Data',
      description: 'Enter all costs and expected benefits.',
      theme: theme,
      details: const [
        'CapEx (Capital Expenditure): One-time capital costs like equipment, software, infrastructure',
        'OpEx (Operating Expenditure): Ongoing costs like maintenance, licenses, labor',
        'Benefits: Expected returns, cost savings, or revenue increases',
        'For each item, specify the amount and timing (which year)',
        'Categorize items appropriately for accurate reporting',
      ],
      tip: 'Be thorough with benefits - include both hard savings (cost reduction) and soft savings (efficiency gains).',
    );
  }

  Widget _buildStep4Card(ThemeData theme) {
    return _StepCard(
      stepNumber: 4,
      title: 'Review Analysis Dashboard',
      description: 'Examine calculated financial metrics and visualizations.',
      theme: theme,
      details: const [
        'NPV (Net Present Value): Should be positive for viable projects',
        'IRR (Internal Rate of Return): Should exceed the 15% hurdle rate',
        'Payback Period: Shorter is better, typically target under 3 years',
        'Cash Flow Chart: Visualizes costs vs benefits over time',
        'Cost Breakdown: Shows CapEx vs OpEx distribution',
      ],
      tip: 'Click "Metrics Guide" in the app bar to learn how each metric is calculated.',
    );
  }

  Widget _buildStep5Card(ThemeData theme) {
    return _StepCard(
      stepNumber: 5,
      title: 'Export PDF Report',
      description: 'Generate a professional report for stakeholders.',
      theme: theme,
      details: const [
        'Click the PDF icon in the Analysis Dashboard',
        'Report includes all project details and financial metrics',
        'Share with stakeholders for approval',
        'Use for Investment Committee presentations',
        'Archive for project documentation',
      ],
      tip: 'Review the dashboard before exporting to ensure all data is complete and accurate.',
    );
  }

  Widget _buildTipsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 12),
                Text(
                  'Pro Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem('Start with conservative benefit estimates - it\'s better to under-promise and over-deliver'),
            _buildTipItem('Include contingency in CapEx items (typically 10-15%)'),
            _buildTipItem('Consider all years of the 6-year projection period'),
            _buildTipItem('Review similar past projects for benchmarking'),
            _buildTipItem('Get finance team input on discount rates and assumptions'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  •  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final ThemeData theme;
  final List<String> details;
  final String tip;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.theme,
    required this.details,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text('$stepNumber'),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                ...details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
                      const SizedBox(width: 12),
                      Expanded(child: Text(detail)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
