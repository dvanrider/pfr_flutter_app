import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../data/models/project.dart';
import '../data/models/financial_items.dart';
import '../core/constants/financial_constants.dart';

/// Service for Excel import/export operations
class ExcelService {
  static final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  // ============================================================================
  // EXPORT FUNCTIONS
  // ============================================================================

  /// Export a list of projects to Excel (summary view)
  static Uint8List exportProjectsList(List<Project> projects) {
    final excel = Excel.createExcel();
    final sheet = excel['Projects'];

    // Remove default sheet if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Header row
    final headers = [
      'PFR Number',
      'Project Name',
      'Status',
      'Segment',
      'Business Unit',
      'Start Date',
      'End Date',
      'Created',
      'Updated',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows
    for (var row = 0; row < projects.length; row++) {
      final project = projects[row];
      final data = [
        project.pfrNumber,
        project.projectName,
        project.status.displayName,
        project.segment,
        project.businessUnit,
        _dateFormat.format(project.projectStartDate),
        _dateFormat.format(project.projectEndDate),
        _dateFormat.format(project.createdAt),
        _dateFormat.format(project.updatedAt),
      ];

      for (var col = 0; col < data.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
            .value = TextCellValue(data[col]);
      }
    }

    // Auto-fit columns (approximate)
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Export a single project with all details and financials
  static Uint8List exportProjectDetail(
    Project project,
    ProjectFinancials financials,
  ) {
    final excel = Excel.createExcel();

    // Remove default sheet
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Create sheets
    _createProjectInfoSheet(excel, project);
    _createCapExSheet(excel, project, financials);
    _createOpExSheet(excel, project, financials);
    _createBenefitsSheet(excel, project, financials);
    _createSummarySheet(excel, project, financials);

    return Uint8List.fromList(excel.encode()!);
  }

  static void _createProjectInfoSheet(Excel excel, Project project) {
    final sheet = excel['Project Info'];

    final info = [
      ['PFR Number', project.pfrNumber],
      ['Project Name', project.projectName],
      ['Status', project.status.displayName],
      ['Segment', project.segment],
      ['Business Unit Group', project.businessUnitGroup],
      ['Business Unit', project.businessUnit],
      ['Initiative Sponsor', project.initiativeSponsor ?? ''],
      ['Executive Sponsor', project.executiveSponsor ?? ''],
      ['Project Requester', project.projectRequester ?? ''],
      ['IC Category', project.icCategory ?? ''],
      ['Description', project.description ?? ''],
      ['Rationale', project.rationale ?? ''],
      ['Start Date', _dateFormat.format(project.projectStartDate)],
      ['End Date', _dateFormat.format(project.projectEndDate)],
      ['Currency', project.currency],
      ['CapEx Budgeted', project.isCapExBudgeted ? 'Yes' : 'No'],
      ['OpEx Budgeted', project.isOpExBudgeted ? 'Yes' : 'No'],
      ['Has Real Estate Lease', project.hasRealEstateLease ? 'Yes' : 'No'],
      ['Has Equipment Lease', project.hasEquipmentLease ? 'Yes' : 'No'],
      ['Has Long Term Commitment', project.hasLongTermCommitment ? 'Yes' : 'No'],
    ];

    for (var row = 0; row < info.length; row++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      labelCell.value = TextCellValue(info[row][0]);
      labelCell.cellStyle = CellStyle(bold: true);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(info[row][1]);
    }

    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 50);
  }

  static void _createCapExSheet(Excel excel, Project project, ProjectFinancials financials) {
    final sheet = excel['CapEx'];
    final startYear = project.startYear;

    // Headers
    final headers = ['Category', 'Description', 'Useful Life (months)'];
    for (var i = 0; i < FinancialConstants.projectionYears; i++) {
      headers.add('Year ${startYear + i}');
    }
    headers.add('Total');

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows
    for (var row = 0; row < financials.capexItems.length; row++) {
      final item = financials.capexItems[row];
      var col = 0;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.category.displayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.description);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          IntCellValue(item.usefulLifeMonths);

      for (var i = 0; i < FinancialConstants.projectionYears; i++) {
        final amount = item.yearlyAmounts[startYear + i] ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
            DoubleCellValue(amount);
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value =
          DoubleCellValue(item.totalAmount);
    }

    // Totals row
    if (financials.capexItems.isNotEmpty) {
      final totalRow = financials.capexItems.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow)).value =
          TextCellValue('TOTAL');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
          .cellStyle = CellStyle(bold: true);

      for (var i = 0; i < FinancialConstants.projectionYears; i++) {
        final total = financials.getCapExForYear(startYear + i);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + i, rowIndex: totalRow)).value =
            DoubleCellValue(total);
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + FinancialConstants.projectionYears, rowIndex: totalRow)).value =
          DoubleCellValue(financials.totalCapEx);
    }
  }

  static void _createOpExSheet(Excel excel, Project project, ProjectFinancials financials) {
    final sheet = excel['OpEx'];
    final startYear = project.startYear;

    // Headers
    final headers = ['Category', 'Description'];
    for (var i = 0; i < FinancialConstants.projectionYears; i++) {
      headers.add('Year ${startYear + i}');
    }
    headers.add('Total');

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows
    for (var row = 0; row < financials.opexItems.length; row++) {
      final item = financials.opexItems[row];
      var col = 0;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.category.displayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.description);

      for (var i = 0; i < FinancialConstants.projectionYears; i++) {
        final amount = item.yearlyAmounts[startYear + i] ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
            DoubleCellValue(amount);
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value =
          DoubleCellValue(item.totalAmount);
    }

    // Totals row
    if (financials.opexItems.isNotEmpty) {
      final totalRow = financials.opexItems.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow)).value =
          TextCellValue('TOTAL');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
          .cellStyle = CellStyle(bold: true);

      for (var i = 0; i < FinancialConstants.projectionYears; i++) {
        final total = financials.getOpExForYear(startYear + i);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + i, rowIndex: totalRow)).value =
            DoubleCellValue(total);
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2 + FinancialConstants.projectionYears, rowIndex: totalRow)).value =
          DoubleCellValue(financials.totalOpEx);
    }
  }

  static void _createBenefitsSheet(Excel excel, Project project, ProjectFinancials financials) {
    final sheet = excel['Benefits'];
    final startYear = project.startYear;

    // Headers
    final headers = ['Category', 'Business Unit', 'Description'];
    for (var i = 0; i < FinancialConstants.projectionYears; i++) {
      headers.add('Year ${startYear + i}');
    }
    headers.add('Total');

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2ECC71'),
        fontColorHex: ExcelColor.white,
      );
    }

    // Data rows
    for (var row = 0; row < financials.benefitItems.length; row++) {
      final item = financials.benefitItems[row];
      var col = 0;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.category.displayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.businessUnit.displayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
          TextCellValue(item.description);

      for (var i = 0; i < FinancialConstants.projectionYears; i++) {
        final amount = item.yearlyAmounts[startYear + i] ?? 0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row + 1)).value =
            DoubleCellValue(amount);
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value =
          DoubleCellValue(item.totalAmount);
    }

    // Totals row
    if (financials.benefitItems.isNotEmpty) {
      final totalRow = financials.benefitItems.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow)).value =
          TextCellValue('TOTAL');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
          .cellStyle = CellStyle(bold: true);

      for (var i = 0; i < FinancialConstants.projectionYears; i++) {
        final total = financials.getBenefitsForYear(startYear + i);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + i, rowIndex: totalRow)).value =
            DoubleCellValue(total);
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3 + FinancialConstants.projectionYears, rowIndex: totalRow)).value =
          DoubleCellValue(financials.totalBenefits);
    }
  }

  static void _createSummarySheet(Excel excel, Project project, ProjectFinancials financials) {
    final sheet = excel['Summary'];
    final startYear = project.startYear;

    // Headers
    final headers = ['Metric'];
    for (var i = 0; i < FinancialConstants.projectionYears; i++) {
      headers.add('Year ${startYear + i}');
    }
    headers.add('Total');

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.white,
      );
    }

    // Summary rows
    final summaryData = [
      ['CapEx', ...financials.yearlyCapEx, financials.totalCapEx],
      ['OpEx', ...financials.yearlyOpEx, financials.totalOpEx],
      ['Total Costs', ...financials.yearlyCosts, financials.totalCosts],
      ['Benefits', ...financials.yearlyBenefits, financials.totalBenefits],
      ['Net Cash Flow', ...financials.yearlyNetCashFlow, financials.totalBenefits - financials.totalCosts],
      ['Cumulative', ...financials.yearlyCumulative, financials.yearlyCumulative.isNotEmpty ? financials.yearlyCumulative.last : 0],
    ];

    for (var row = 0; row < summaryData.length; row++) {
      final data = summaryData[row];
      for (var col = 0; col < data.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
        if (col == 0) {
          cell.value = TextCellValue(data[col] as String);
          cell.cellStyle = CellStyle(bold: true);
        } else {
          cell.value = DoubleCellValue((data[col] as num).toDouble());
        }
      }
    }

    // Key metrics
    final metricsStartRow = summaryData.length + 3;
    final npv = financials.calculateNPV(FinancialConstants.hurdleRate);
    final irr = financials.calculateIRR();
    final payback = financials.calculatePaybackMonths();

    final metrics = [
      ['Key Metrics', ''],
      ['NPV (at ${(FinancialConstants.hurdleRate * 100).toInt()}% hurdle)', _currencyFormat.format(npv)],
      ['IRR', irr != null ? '${(irr * 100).toStringAsFixed(1)}%' : 'N/A'],
      ['Payback Period', payback != null ? '$payback months' : 'N/A'],
      ['Total Investment', _currencyFormat.format(financials.totalCosts)],
    ];

    for (var row = 0; row < metrics.length; row++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: metricsStartRow + row));
      labelCell.value = TextCellValue(metrics[row][0]);
      labelCell.cellStyle = CellStyle(bold: row == 0);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: metricsStartRow + row)).value =
          TextCellValue(metrics[row][1]);
    }
  }

  // ============================================================================
  // IMPORT FUNCTIONS
  // ============================================================================

  /// Parse a project import template and return validation results
  static ImportResult parseProjectsImport(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final errors = <String>[];
    final projects = <ImportedProject>[];

    // Look for the Projects sheet
    final sheetName = excel.tables.keys.firstWhere(
      (name) => name.toLowerCase() == 'projects',
      orElse: () => excel.tables.keys.first,
    );

    final sheet = excel.tables[sheetName];
    if (sheet == null) {
      return ImportResult(
        success: false,
        errors: ['No data found in Excel file'],
        projects: [],
      );
    }

    // Parse headers from first row
    final headerRow = sheet.rows.first;
    final headers = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell != null && cell.value != null) {
        headers[cell.value.toString().toLowerCase().trim()] = i;
      }
    }

    // Validate required headers
    final requiredHeaders = ['project name', 'segment', 'business unit'];
    for (final header in requiredHeaders) {
      if (!headers.containsKey(header)) {
        errors.add('Missing required column: $header');
      }
    }

    if (errors.isNotEmpty) {
      return ImportResult(success: false, errors: errors, projects: []);
    }

    // Parse data rows
    for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final row = sheet.rows[rowIndex];
      final rowNum = rowIndex + 1;

      try {
        final projectName = _getCellValue(row, headers['project name']);
        if (projectName.isEmpty) {
          continue; // Skip empty rows
        }

        final imported = ImportedProject(
          projectName: projectName,
          segment: _getCellValue(row, headers['segment']),
          businessUnitGroup: _getCellValue(row, headers['business unit group']),
          businessUnit: _getCellValue(row, headers['business unit']),
          initiativeSponsor: _getCellValue(row, headers['initiative sponsor']),
          executiveSponsor: _getCellValue(row, headers['executive sponsor']),
          projectRequester: _getCellValue(row, headers['project requester']),
          icCategory: _getCellValue(row, headers['ic category']),
          description: _getCellValue(row, headers['description']),
          rationale: _getCellValue(row, headers['rationale']),
          startDate: _parseDateCell(row, headers['start date']),
          endDate: _parseDateCell(row, headers['end date']),
          currency: _getCellValue(row, headers['currency'], defaultValue: 'USD'),
          isCapExBudgeted: _parseBoolCell(row, headers['capex budgeted']),
          isOpExBudgeted: _parseBoolCell(row, headers['opex budgeted']),
        );

        // Validate required fields
        final rowErrors = <String>[];
        if (imported.segment.isEmpty) {
          rowErrors.add('Segment is required');
        }
        if (imported.businessUnit.isEmpty) {
          rowErrors.add('Business Unit is required');
        }

        if (rowErrors.isNotEmpty) {
          errors.add('Row $rowNum: ${rowErrors.join(', ')}');
        } else {
          projects.add(imported);
        }
      } catch (e) {
        errors.add('Row $rowNum: Error parsing data - $e');
      }
    }

    return ImportResult(
      success: errors.isEmpty,
      errors: errors,
      projects: projects,
    );
  }

  static String _getCellValue(List<Data?> row, int? colIndex, {String defaultValue = ''}) {
    if (colIndex == null || colIndex >= row.length) return defaultValue;
    final cell = row[colIndex];
    if (cell == null || cell.value == null) return defaultValue;
    return cell.value.toString().trim();
  }

  static DateTime? _parseDateCell(List<Data?> row, int? colIndex) {
    final value = _getCellValue(row, colIndex);
    if (value.isEmpty) return null;

    try {
      // Try various date formats
      final formats = [
        DateFormat('yyyy-MM-dd'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('M/d/yyyy'),
      ];

      for (final format in formats) {
        try {
          return format.parse(value);
        } catch (_) {}
      }

      // Try parsing as Excel date number
      final dateNum = double.tryParse(value);
      if (dateNum != null) {
        return DateTime(1899, 12, 30).add(Duration(days: dateNum.toInt()));
      }
    } catch (_) {}

    return null;
  }

  static bool _parseBoolCell(List<Data?> row, int? colIndex) {
    final value = _getCellValue(row, colIndex).toLowerCase();
    return value == 'yes' || value == 'true' || value == '1' || value == 'y';
  }

  /// Generate a blank import template
  static Uint8List generateImportTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Projects'];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Headers
    final headers = [
      'Project Name*',
      'Segment*',
      'Business Unit Group',
      'Business Unit*',
      'Initiative Sponsor',
      'Executive Sponsor',
      'Project Requester',
      'IC Category',
      'Description',
      'Rationale',
      'Start Date',
      'End Date',
      'Currency',
      'CapEx Budgeted',
      'OpEx Budgeted',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.white,
      );
      sheet.setColumnWidth(i, 20);
    }

    // Add example row
    final exampleData = [
      'Example Project',
      'WynD',
      'Technology',
      'IT Infrastructure',
      'John Doe',
      'Jane Smith',
      'Bob Wilson',
      'Strategic',
      'Sample project description',
      'Business rationale for the project',
      _dateFormat.format(DateTime.now()),
      _dateFormat.format(DateTime.now().add(const Duration(days: 365))),
      'USD',
      'Yes',
      'No',
    ];

    for (var i = 0; i < exampleData.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1)).value =
          TextCellValue(exampleData[i]);
    }

    // Add instructions sheet
    final instructionsSheet = excel['Instructions'];
    final instructions = [
      ['Project Import Template Instructions'],
      [''],
      ['Required fields are marked with *'],
      [''],
      ['Field Descriptions:'],
      ['Project Name*', 'The name of the project'],
      ['Segment*', 'Business segment (WynD, VOI, Exchange, Corporate)'],
      ['Business Unit Group', 'Department group (Technology, Operations, etc.)'],
      ['Business Unit*', 'Specific business unit'],
      ['Initiative Sponsor', 'Person sponsoring the initiative'],
      ['Executive Sponsor', 'Executive overseeing the project'],
      ['Project Requester', 'Person requesting the project'],
      ['IC Category', 'Investment Committee category'],
      ['Description', 'Project description'],
      ['Rationale', 'Business rationale'],
      ['Start Date', 'Project start date (YYYY-MM-DD)'],
      ['End Date', 'Project end date (YYYY-MM-DD)'],
      ['Currency', 'Currency code (USD, EUR, etc.)'],
      ['CapEx Budgeted', 'Is CapEx budgeted? (Yes/No)'],
      ['OpEx Budgeted', 'Is OpEx budgeted? (Yes/No)'],
    ];

    for (var row = 0; row < instructions.length; row++) {
      for (var col = 0; col < instructions[row].length; col++) {
        final cell = instructionsSheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = TextCellValue(instructions[row][col]);
        if (row == 0 || (row >= 5 && col == 0)) {
          cell.cellStyle = CellStyle(bold: true);
        }
      }
    }

    instructionsSheet.setColumnWidth(0, 25);
    instructionsSheet.setColumnWidth(1, 50);

    return Uint8List.fromList(excel.encode()!);
  }
}

/// Result of parsing an import file
class ImportResult {
  final bool success;
  final List<String> errors;
  final List<ImportedProject> projects;

  ImportResult({
    required this.success,
    required this.errors,
    required this.projects,
  });
}

/// Imported project data before creating actual Project
class ImportedProject {
  final String projectName;
  final String segment;
  final String businessUnitGroup;
  final String businessUnit;
  final String? initiativeSponsor;
  final String? executiveSponsor;
  final String? projectRequester;
  final String? icCategory;
  final String? description;
  final String? rationale;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;
  final bool isCapExBudgeted;
  final bool isOpExBudgeted;

  ImportedProject({
    required this.projectName,
    required this.segment,
    this.businessUnitGroup = '',
    required this.businessUnit,
    this.initiativeSponsor,
    this.executiveSponsor,
    this.projectRequester,
    this.icCategory,
    this.description,
    this.rationale,
    this.startDate,
    this.endDate,
    this.currency = 'USD',
    this.isCapExBudgeted = false,
    this.isOpExBudgeted = false,
  });
}
