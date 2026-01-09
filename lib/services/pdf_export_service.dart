import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../core/constants/financial_constants.dart';
import '../data/models/project.dart';
import '../data/models/financial_items.dart';

class PdfExportService {
  static final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _dateFormat = DateFormat('MMM dd, yyyy');

  static Future<void> exportProject({
    required Project project,
    required ProjectFinancials financials,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(project),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildProjectSummary(project),
          pw.SizedBox(height: 20),
          if (financials.hasData) ...[
            _buildKeyMetrics(financials),
            pw.SizedBox(height: 20),
            _buildFinancialSummary(financials),
            pw.SizedBox(height: 20),
            _buildYearlyBreakdown(financials, project.startYear),
          ] else
            _buildNoFinancialData(),
          pw.SizedBox(height: 20),
          _buildProjectDetails(project),
          pw.SizedBox(height: 20),
          _buildFlags(project),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${project.pfrNumber}_Analysis.pdf',
    );
  }

  static pw.Widget _buildHeader(Project project) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Project Funding Request',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1E3A5F'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                project.pfrNumber,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _getStatusColor(project.status),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              project.status.displayName,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return PdfColors.grey600;
      case ProjectStatus.submitted:
      case ProjectStatus.pendingApproval:
        return PdfColors.orange;
      case ProjectStatus.approved:
        return PdfColors.green;
      case ProjectStatus.rejected:
        return PdfColors.red;
      case ProjectStatus.onHold:
        return PdfColors.blue;
      case ProjectStatus.cancelled:
        return PdfColors.grey800;
    }
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectSummary(Project project) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            project.projectName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${project.segment} / ${project.businessUnitGroup} / ${project.businessUnit}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildInfoBox('Currency', project.currency),
              pw.SizedBox(width: 20),
              _buildInfoBox('Start Date', _dateFormat.format(project.projectStartDate)),
              pw.SizedBox(width: 20),
              _buildInfoBox('End Date', _dateFormat.format(project.projectEndDate)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildKeyMetrics(ProjectFinancials financials) {
    final npv = financials.calculateNPV(FinancialConstants.hurdleRate);
    final irr = financials.calculateIRR();
    final paybackMonths = financials.calculatePaybackMonths();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Key Financial Metrics'),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _buildMetricBox(
              'Net Present Value',
              _currencyFormat.format(npv),
              'At ${(FinancialConstants.hurdleRate * 100).toInt()}% hurdle rate',
              npv >= 0 ? PdfColors.green700 : PdfColors.red700,
            ),
            pw.SizedBox(width: 16),
            _buildMetricBox(
              'Internal Rate of Return',
              irr != null ? '${(irr * 100).toStringAsFixed(1)}%' : 'N/A',
              irr != null && irr >= FinancialConstants.hurdleRate
                  ? 'Above hurdle rate'
                  : 'Below hurdle rate',
              irr != null && irr >= FinancialConstants.hurdleRate
                  ? PdfColors.green700
                  : PdfColors.orange700,
            ),
            pw.SizedBox(width: 16),
            _buildMetricBox(
              'Payback Period',
              paybackMonths != null
                  ? '${paybackMonths ~/ 12}y ${paybackMonths % 12}m'
                  : 'N/A',
              'Simple payback',
              paybackMonths != null && paybackMonths <= 36
                  ? PdfColors.green700
                  : PdfColors.orange700,
            ),
            pw.SizedBox(width: 16),
            _buildMetricBox(
              'Total Investment',
              _currencyFormat.format(financials.totalCosts),
              'CapEx + OpEx',
              PdfColor.fromHex('#1E3A5F'),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetricBox(String title, String value, String subtitle, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFinancialSummary(ProjectFinancials financials) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cost & Benefit Summary'),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow('Capital Expenditure (CapEx)', _currencyFormat.format(financials.totalCapEx), PdfColors.red700),
                    pw.SizedBox(height: 6),
                    _buildSummaryRow('Operating Expenditure (OpEx)', _currencyFormat.format(financials.totalOpEx), PdfColors.orange700),
                    pw.Divider(color: PdfColors.grey300),
                    _buildSummaryRow('Total Costs', _currencyFormat.format(financials.totalCosts), PdfColors.red900, bold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow('Total Benefits', _currencyFormat.format(financials.totalBenefits), PdfColors.green700, bold: true),
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.grey300),
                    _buildSummaryRow(
                      'Net Benefit',
                      _currencyFormat.format(financials.totalBenefits - financials.totalCosts),
                      financials.totalBenefits >= financials.totalCosts ? PdfColors.green700 : PdfColors.red700,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, PdfColor color, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildYearlyBreakdown(ProjectFinancials financials, int startYear) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Yearly Financial Breakdown'),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            for (int i = 1; i <= FinancialConstants.projectionYears + 1; i++)
              i: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Category', isHeader: true),
                for (int i = 0; i < FinancialConstants.projectionYears; i++)
                  _buildTableCell('${startYear + i}', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // CapEx row
            _buildTableDataRow('CapEx', financials.yearlyCapEx, PdfColors.red700),
            // OpEx row
            _buildTableDataRow('OpEx', financials.yearlyOpEx, PdfColors.orange700),
            // Total Costs row
            _buildTableDataRow('Total Costs', financials.yearlyCosts, PdfColors.red900),
            // Benefits row
            _buildTableDataRow('Benefits', financials.yearlyBenefits, PdfColors.green700),
            // Net Cash Flow row
            _buildTableDataRow('Net Cash Flow', financials.yearlyNetCashFlow, PdfColor.fromHex('#1E3A5F'), bold: true),
            // Cumulative row
            _buildTableDataRow('Cumulative', financials.yearlyCumulative, PdfColors.purple700),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildTableDataRow(String label, List<double> values, PdfColor color, {bool bold = false}) {
    final total = values.fold(0.0, (sum, v) => sum + v);
    return pw.TableRow(
      children: [
        _buildTableCell(label, color: color, bold: bold),
        for (final v in values)
          _buildTableCell(_currencyFormat.format(v), color: v < 0 ? PdfColors.red : null, bold: bold),
        _buildTableCell(_currencyFormat.format(total), color: color, bold: true),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader || bold ? pw.FontWeight.bold : null,
          color: color,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.right,
      ),
    );
  }

  static pw.Widget _buildNoFinancialData() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          'No financial data available for this project.',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ),
    );
  }

  static pw.Widget _buildProjectDetails(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Project Details'),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (project.description != null && project.description!.isNotEmpty) ...[
                pw.Text('Description', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text(project.description!, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 12),
              ],
              if (project.rationale != null && project.rationale!.isNotEmpty) ...[
                pw.Text('Business Rationale', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text(project.rationale!, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 12),
              ],
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildDetailItem('Initiative Sponsor', project.initiativeSponsor ?? 'Not specified')),
                  pw.Expanded(child: _buildDetailItem('Executive Sponsor', project.executiveSponsor ?? 'Not specified')),
                  pw.Expanded(child: _buildDetailItem('Project Requester', project.projectRequester ?? 'Not specified')),
                ],
              ),
              if (project.icCategory != null) ...[
                pw.SizedBox(height: 8),
                _buildDetailItem('IC Category', project.icCategory!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDetailItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildFlags(Project project) {
    final flags = <String>[];
    if (project.isCapExBudgeted) flags.add('CapEx Budgeted');
    if (project.isOpExBudgeted) flags.add('OpEx Budgeted');
    if (project.replacesCurrentAssets) flags.add('Replaces Current Assets');
    if (project.isHoaReimbursed) flags.add('HOA Reimbursed');
    if (project.hasGuaranteedMarketing) flags.add('Guaranteed Marketing');
    if (project.hasLongTermCommitment) flags.add('Long-Term Commitment');
    if (project.hasRealEstateLease) flags.add('Real Estate Lease');
    if (project.hasEquipmentLease) flags.add('Equipment Lease');

    if (flags.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Project Flags'),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 8,
          runSpacing: 6,
          children: flags.map((flag) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Text(flag, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue800)),
          )).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#1E3A5F'),
      ),
    );
  }
}
