import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/financial_constants.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Metrics Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/help/training'),
            icon: const Icon(Icons.school),
            label: const Text('Training Guide'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(theme),
            const SizedBox(height: 24),
            Text(
              'Key Financial Metrics',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNPVCard(theme),
            const SizedBox(height: 16),
            _buildIRRCard(theme),
            const SizedBox(height: 16),
            _buildPaybackCard(theme),
            const SizedBox(height: 24),
            Text(
              'Supporting Metrics',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSupportingMetricsCard(theme),
            const SizedBox(height: 24),
            _buildConstantsCard(theme),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
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
                    Icons.calculate,
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
                        'Understanding Financial Analysis',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How PFR evaluates project viability',
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
              'The PFR application uses industry-standard financial metrics to evaluate capital investment projects. '
              'These metrics help determine whether a project will generate sufficient returns to justify the investment.',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNPVCard(ThemeData theme) {
    return _MetricCard(
      theme: theme,
      icon: Icons.trending_up,
      iconColor: Colors.green,
      title: 'Net Present Value (NPV)',
      subtitle: 'The gold standard for investment decisions',
      whatItIs: 'NPV represents the total value of all future cash flows, discounted back to today\'s dollars. '
          'It accounts for the time value of money - the principle that a dollar today is worth more than a dollar in the future.',
      formula: 'NPV = Sum of [Cash Flow / (1 + r)^t]',
      formulaExplanation: 'Where:\n'
          '  - Cash Flow = Benefits - Costs for each year\n'
          '  - r = Discount rate (${(FinancialConstants.hurdleRate * 100).toInt()}% hurdle rate)\n'
          '  - t = Year number (1 through ${FinancialConstants.projectionYears})',
      interpretation: [
        'NPV > 0: Project creates value - GOOD',
        'NPV = 0: Project breaks even',
        'NPV < 0: Project destroys value - AVOID',
        'Higher NPV = More valuable project',
      ],
      example: 'If a project has Year 1 cash flow of \$100,000:\n'
          'Present Value = \$100,000 / (1.15)^1 = \$86,957\n\n'
          'The \$100,000 received in Year 1 is worth \$86,957 in today\'s dollars.',
    );
  }

  Widget _buildIRRCard(ThemeData theme) {
    return _MetricCard(
      theme: theme,
      icon: Icons.percent,
      iconColor: Colors.blue,
      title: 'Internal Rate of Return (IRR)',
      subtitle: 'The project\'s effective interest rate',
      whatItIs: 'IRR is the discount rate that makes the NPV equal to zero. '
          'Think of it as the "interest rate" the project earns on the invested capital.',
      formula: 'Find r where: Sum of [Cash Flow / (1 + r)^t] = 0',
      formulaExplanation: 'The app uses the Newton-Raphson iterative method:\n'
          '  1. Start with an initial guess (10%)\n'
          '  2. Calculate NPV and its derivative\n'
          '  3. Adjust the rate: new_rate = rate - (NPV / derivative)\n'
          '  4. Repeat until convergence (within 0.01%)',
      interpretation: [
        'IRR > ${(FinancialConstants.hurdleRate * 100).toInt()}% hurdle rate: Project exceeds required return - GOOD',
        'IRR = ${(FinancialConstants.hurdleRate * 100).toInt()}%: Project meets minimum requirements',
        'IRR < ${(FinancialConstants.hurdleRate * 100).toInt()}%: Project doesn\'t meet hurdle rate - CAUTION',
        'N/A: Cannot calculate (no sign change in cash flows)',
      ],
      example: 'If a project has IRR of 25%:\n'
          'The project earns an effective 25% return on investment.\n'
          'Since 25% > 15% hurdle rate, this exceeds requirements.',
    );
  }

  Widget _buildPaybackCard(ThemeData theme) {
    return _MetricCard(
      theme: theme,
      icon: Icons.access_time,
      iconColor: Colors.orange,
      title: 'Payback Period',
      subtitle: 'Time to recover the initial investment',
      whatItIs: 'The payback period is the time it takes for cumulative cash flows to equal zero - '
          'essentially, how long until you "get your money back." This is a simple (non-discounted) calculation.',
      formula: 'Find t where: Cumulative Cash Flow >= 0',
      formulaExplanation: 'The app calculates:\n'
          '  1. Accumulates net cash flows year by year\n'
          '  2. When cumulative becomes positive, that\'s the payback year\n'
          '  3. Interpolates within the year to get months\n'
          '  4. Returns total months for payback',
      interpretation: [
        'Under 36 months (3 years): Quick payback - GOOD (shown in green)',
        '36-60 months: Moderate payback - ACCEPTABLE (shown in orange)',
        'Over 60 months: Slow payback - CAUTION',
        'N/A: Project doesn\'t pay back within ${FinancialConstants.projectionYears} years',
      ],
      example: 'If Year 1 cumulative = -\$500K and Year 2 cumulative = +\$100K:\n'
          'Payback is in Year 2. Cash flow in Year 2 = \$600K\n'
          'Months into Year 2 = (\$500K / \$600K) x 12 = 10 months\n'
          'Total payback = 12 + 10 = 22 months (1y 10m)',
    );
  }

  Widget _buildSupportingMetricsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Calculations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSupportingMetric(
              theme,
              'Total Investment',
              'Total CapEx + Total OpEx over all ${FinancialConstants.projectionYears} years',
              'Represents the complete cost of the project',
            ),
            const Divider(height: 24),
            _buildSupportingMetric(
              theme,
              'Net Cash Flow',
              'Benefits - (CapEx + OpEx) for each year',
              'Shows whether each year is profitable or not',
            ),
            const Divider(height: 24),
            _buildSupportingMetric(
              theme,
              'Cumulative Cash Flow',
              'Running total of Net Cash Flow',
              'Tracks progress toward payback',
            ),
            const Divider(height: 24),
            _buildSupportingMetric(
              theme,
              'Cost Breakdown',
              'CapEx% = (Total CapEx / Total Costs) x 100',
              'Shows the proportion of capital vs operating costs',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportingMetric(ThemeData theme, String title, String formula, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            formula,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildConstantsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Text(
                  'Financial Constants',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConstantRow('Hurdle Rate (Discount Rate)', '${(FinancialConstants.hurdleRate * 100).toInt()}%'),
            _buildConstantRow('Projection Period', '${FinancialConstants.projectionYears} years'),
            _buildConstantRow('Default Tax Rate', '${(FinancialConstants.defaultTaxRate * 100).toInt()}%'),
            _buildConstantRow('Default Contingency', '${(FinancialConstants.defaultContingencyRate * 100).toInt()}%'),
            _buildConstantRow('IC Approval Threshold', '\$${(FinancialConstants.icApprovalThreshold / 1000000).toStringAsFixed(0)}M'),
            _buildConstantRow('Max Payback Period', '${FinancialConstants.maxPaybackMonths} months'),
          ],
        ),
      ),
    );
  }

  Widget _buildConstantRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String whatItIs;
  final String formula;
  final String formulaExplanation;
  final List<String> interpretation;
  final String example;

  const _MetricCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.whatItIs,
    required this.formula,
    required this.formulaExplanation,
    required this.interpretation,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                _buildSection('What it is', whatItIs),
                const SizedBox(height: 16),
                _buildFormulaSection(),
                const SizedBox(height: 16),
                _buildInterpretationSection(),
                const SizedBox(height: 16),
                _buildExampleSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildFormulaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formula',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            formula,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              color: Colors.greenAccent,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            formulaExplanation,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterpretationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to interpret',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...interpretation.map((item) {
          Color? textColor;
          IconData itemIcon = Icons.circle;

          if (item.contains('GOOD')) {
            textColor = Colors.green[700];
            itemIcon = Icons.check_circle;
          } else if (item.contains('AVOID') || item.contains('CAUTION')) {
            textColor = Colors.orange[700];
            itemIcon = Icons.warning;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(itemIcon, size: 16, color: textColor ?? Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExampleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Example',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            example,
            style: TextStyle(
              color: Colors.blue[900],
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
