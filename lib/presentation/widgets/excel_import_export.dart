import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../../data/models/project.dart';
import '../../data/models/financial_items.dart';
import '../../services/excel_service.dart';
import '../../providers/project_providers.dart';
import '../../providers/auth_providers.dart';
import '../../core/constants/financial_constants.dart';

/// Button to export projects list to Excel
class ExportProjectsButton extends ConsumerWidget {
  final List<Project> projects;

  const ExportProjectsButton({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.file_download),
      tooltip: 'Export',
      onSelected: (value) async {
        switch (value) {
          case 'export_list':
            await _exportProjectsList(context);
            break;
          case 'download_template':
            await _downloadImportTemplate(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export_list',
          child: Row(
            children: [
              Icon(Icons.table_chart),
              SizedBox(width: 12),
              Text('Export Projects List'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'download_template',
          child: Row(
            children: [
              Icon(Icons.file_present),
              SizedBox(width: 12),
              Text('Download Import Template'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportProjectsList(BuildContext context) async {
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No projects to export')),
      );
      return;
    }

    try {
      final bytes = ExcelService.exportProjectsList(projects);
      final fileName = 'projects_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${projects.length} projects to $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadImportTemplate(BuildContext context) async {
    try {
      final bytes = ExcelService.generateImportTemplate();
      const fileName = 'project_import_template.xlsx';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import template downloaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Button to export a single project with financials
class ExportProjectDetailButton extends ConsumerWidget {
  final Project project;
  final ProjectFinancials financials;

  const ExportProjectDetailButton({
    super.key,
    required this.project,
    required this.financials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.file_download),
      tooltip: 'Export to Excel',
      onPressed: () => _exportProject(context),
    );
  }

  Future<void> _exportProject(BuildContext context) async {
    try {
      final bytes = ExcelService.exportProjectDetail(project, financials);
      final fileName = '${project.pfrNumber}_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${project.projectName} to Excel'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Button to import projects from Excel
class ImportProjectsButton extends ConsumerStatefulWidget {
  final VoidCallback? onImportComplete;

  const ImportProjectsButton({
    super.key,
    this.onImportComplete,
  });

  @override
  ConsumerState<ImportProjectsButton> createState() => _ImportProjectsButtonState();
}

class _ImportProjectsButtonState extends ConsumerState<ImportProjectsButton> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isImporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_upload),
      tooltip: 'Import from Excel',
      onPressed: _isImporting ? null : _pickAndImportFile,
    );
  }

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file')),
          );
        }
        return;
      }

      setState(() => _isImporting = true);

      // Parse the Excel file
      final importResult = ExcelService.parseProjectsImport(file.bytes!);

      if (!mounted) return;

      if (importResult.errors.isNotEmpty && importResult.projects.isEmpty) {
        // Show errors
        _showImportResultDialog(importResult, null);
      } else if (importResult.projects.isNotEmpty) {
        // Show preview and confirm import
        _showImportPreviewDialog(importResult);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid projects found in file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showImportResultDialog(ImportResult result, int? importedCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              importedCount != null ? Icons.check_circle : Icons.error,
              color: importedCount != null ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(importedCount != null ? 'Import Complete' : 'Import Errors'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (importedCount != null)
                Text('Successfully imported $importedCount project(s).'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.errors.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        '• ${result.errors[index]}',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  void _showImportPreviewDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.preview, color: Colors.blue),
            SizedBox(width: 8),
            Text('Import Preview'),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Found ${result.projects.length} project(s) to import:'),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: result.projects.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final project = result.projects[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(project.projectName),
                      subtitle: Text('${project.segment} - ${project.businessUnit}'),
                    );
                  },
                ),
              ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${result.errors.length} row(s) had errors and will be skipped',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ],
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
              Navigator.pop(context);
              _performImport(result);
            },
            child: Text('Import ${result.projects.length} Project(s)'),
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(ImportResult result) async {
    setState(() => _isImporting = true);

    try {
      final repository = ref.read(projectRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final now = DateTime.now();
      var importedCount = 0;

      for (final imported in result.projects) {
        final pfrNumber = 'PFR-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}${importedCount.toString().padLeft(2, '0')}';

        final project = Project(
          id: '',
          userId: user?.uid,
          pfrNumber: pfrNumber,
          projectName: imported.projectName,
          segment: imported.segment,
          businessUnitGroup: imported.businessUnitGroup.isNotEmpty
              ? imported.businessUnitGroup
              : 'Technology',
          businessUnit: imported.businessUnit,
          initiativeSponsor: imported.initiativeSponsor,
          executiveSponsor: imported.executiveSponsor,
          projectRequester: imported.projectRequester,
          icCategory: imported.icCategory,
          description: imported.description,
          rationale: imported.rationale,
          projectStartDate: imported.startDate ?? now,
          projectEndDate: imported.endDate ?? now.add(const Duration(days: 365)),
          currency: imported.currency,
          isCapExBudgeted: imported.isCapExBudgeted,
          isOpExBudgeted: imported.isOpExBudgeted,
          status: ProjectStatus.draft,
          createdAt: now,
          updatedAt: now,
        );

        await repository.createProject(project);
        importedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount project(s)'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onImportComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing projects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}

/// Combined import/export toolbar widget
class ExcelToolbar extends ConsumerWidget {
  final List<Project> projects;
  final VoidCallback? onImportComplete;

  const ExcelToolbar({
    super.key,
    required this.projects,
    this.onImportComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImportProjectsButton(onImportComplete: onImportComplete),
        ExportProjectsButton(projects: projects),
      ],
    );
  }
}
