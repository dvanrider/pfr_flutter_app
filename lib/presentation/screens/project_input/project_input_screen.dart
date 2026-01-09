import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/financial_constants.dart';
import '../../../data/models/project.dart';
import '../../../providers/project_providers.dart';
import '../../../providers/auth_providers.dart';

class ProjectInputScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const ProjectInputScreen({super.key, this.projectId});

  @override
  ConsumerState<ProjectInputScreen> createState() => _ProjectInputScreenState();
}

class _ProjectInputScreenState extends ConsumerState<ProjectInputScreen> {
  late FormGroup form;
  bool _isLoading = false;
  bool _isEditing = false;
  Project? _existingProject;

  final List<String> _segments = ['WynD', 'VOI', 'Exchange', 'Corporate'];
  final List<String> _businessUnitGroups = ['Technology', 'Operations', 'Finance', 'Marketing', 'HR', 'Legal'];
  final List<String> _businessUnits = ['IT Infrastructure', 'Software Development', 'Data Analytics', 'Security', 'Support'];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];
  final List<String> _icCategories = ['Strategic', 'Operational', 'Compliance', 'Maintenance', 'Growth'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.projectId != null;
    _initForm();
    if (_isEditing) {
      _loadProject();
    }
  }

  void _initForm() {
    final now = DateTime.now();
    form = FormGroup({
      'pfrNumber': FormControl<String>(
        value: _generatePfrNumber(),
        validators: [Validators.required],
      ),
      'projectName': FormControl<String>(validators: [Validators.required, Validators.minLength(3)]),
      'segment': FormControl<String>(validators: [Validators.required]),
      'businessUnitGroup': FormControl<String>(validators: [Validators.required]),
      'businessUnit': FormControl<String>(validators: [Validators.required]),
      'initiativeSponsor': FormControl<String>(),
      'executiveSponsor': FormControl<String>(),
      'projectRequester': FormControl<String>(),
      'icCategory': FormControl<String>(),
      'physicalAddress': FormControl<String>(),
      'description': FormControl<String>(validators: [Validators.required]),
      'rationale': FormControl<String>(),
      'projectStartDate': FormControl<DateTime>(value: now, validators: [Validators.required]),
      'projectEndDate': FormControl<DateTime>(
        value: now.add(const Duration(days: 365)),
        validators: [Validators.required],
      ),
      'benefitStartDate': FormControl<DateTime>(),
      'currency': FormControl<String>(value: 'USD'),
      'isCapExBudgeted': FormControl<bool>(value: false),
      'isOpExBudgeted': FormControl<bool>(value: false),
      'opExCostCenter': FormControl<String>(),
      'replacesCurrentAssets': FormControl<bool>(value: false),
      'isHoaReimbursed': FormControl<bool>(value: false),
      'hasGuaranteedMarketing': FormControl<bool>(value: false),
      'hasLongTermCommitment': FormControl<bool>(value: false),
      'hasRealEstateLease': FormControl<bool>(value: false),
      'hasEquipmentLease': FormControl<bool>(value: false),
    });
  }

  String _generatePfrNumber() {
    final now = DateTime.now();
    return 'PFR-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(projectRepositoryProvider);
      final project = await repository.getProjectById(widget.projectId!);
      if (project != null && mounted) {
        _existingProject = project;
        _populateForm(project);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(Project project) {
    form.patchValue({
      'pfrNumber': project.pfrNumber,
      'projectName': project.projectName,
      'segment': project.segment,
      'businessUnitGroup': project.businessUnitGroup,
      'businessUnit': project.businessUnit,
      'initiativeSponsor': project.initiativeSponsor,
      'executiveSponsor': project.executiveSponsor,
      'projectRequester': project.projectRequester,
      'icCategory': project.icCategory,
      'physicalAddress': project.physicalAddress,
      'description': project.description,
      'rationale': project.rationale,
      'projectStartDate': project.projectStartDate,
      'projectEndDate': project.projectEndDate,
      'benefitStartDate': project.benefitStartDate,
      'currency': project.currency,
      'isCapExBudgeted': project.isCapExBudgeted,
      'isOpExBudgeted': project.isOpExBudgeted,
      'opExCostCenter': project.opExCostCenter,
      'replacesCurrentAssets': project.replacesCurrentAssets,
      'isHoaReimbursed': project.isHoaReimbursed,
      'hasGuaranteedMarketing': project.hasGuaranteedMarketing,
      'hasLongTermCommitment': project.hasLongTermCommitment,
      'hasRealEstateLease': project.hasRealEstateLease,
      'hasEquipmentLease': project.hasEquipmentLease,
    });
  }

  Future<void> _saveProject() async {
    if (!form.valid) {
      form.markAllAsTouched();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(projectRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final values = form.value;
      final now = DateTime.now();

      final project = Project(
        id: _isEditing ? widget.projectId! : '',
        userId: _existingProject?.userId ?? user?.uid,
        pfrNumber: values['pfrNumber'] as String? ?? '',
        projectName: values['projectName'] as String? ?? '',
        segment: values['segment'] as String? ?? '',
        businessUnitGroup: values['businessUnitGroup'] as String? ?? '',
        businessUnit: values['businessUnit'] as String? ?? '',
        initiativeSponsor: values['initiativeSponsor'] as String?,
        executiveSponsor: values['executiveSponsor'] as String?,
        projectRequester: values['projectRequester'] as String?,
        icCategory: values['icCategory'] as String?,
        physicalAddress: values['physicalAddress'] as String?,
        description: values['description'] as String?,
        rationale: values['rationale'] as String?,
        projectStartDate: values['projectStartDate'] as DateTime? ?? now,
        projectEndDate: values['projectEndDate'] as DateTime? ?? now.add(const Duration(days: 365)),
        benefitStartDate: values['benefitStartDate'] as DateTime?,
        currency: values['currency'] as String? ?? 'USD',
        isCapExBudgeted: values['isCapExBudgeted'] as bool? ?? false,
        isOpExBudgeted: values['isOpExBudgeted'] as bool? ?? false,
        opExCostCenter: values['opExCostCenter'] as String?,
        replacesCurrentAssets: values['replacesCurrentAssets'] as bool? ?? false,
        isHoaReimbursed: values['isHoaReimbursed'] as bool? ?? false,
        hasGuaranteedMarketing: values['hasGuaranteedMarketing'] as bool? ?? false,
        hasLongTermCommitment: values['hasLongTermCommitment'] as bool? ?? false,
        hasRealEstateLease: values['hasRealEstateLease'] as bool? ?? false,
        hasEquipmentLease: values['hasEquipmentLease'] as bool? ?? false,
        status: _existingProject?.status ?? ProjectStatus.draft,
        statusHistory: _existingProject?.statusHistory ?? const [],
        createdAt: _existingProject?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await repository.updateProject(project);
      } else {
        await repository.createProject(project);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Project updated successfully' : 'Project created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/projects');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving project: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Project' : 'New Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/projects'),
        ),
        actions: [
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            TextButton.icon(
              onPressed: _saveProject,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : ReactiveForm(
              formGroup: form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Information', Icons.info_outline),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Stakeholders', Icons.people_outline),
                    _buildStakeholdersSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Project Timeline', Icons.calendar_today),
                    _buildDatesSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Budget & Financials', Icons.attach_money),
                    _buildBudgetSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Project Details', Icons.description),
                    _buildDetailsSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Commitments & Flags', Icons.flag_outlined),
                    _buildFlagsSection(),
                    if (_isEditing && _existingProject != null) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader('Project Status', Icons.assignment_turned_in),
                      _buildStatusSection(),
                    ],
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ReactiveTextField<String>(
                    formControlName: 'pfrNumber',
                    decoration: const InputDecoration(
                      labelText: 'PFR Number *',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ReactiveTextField<String>(
                    formControlName: 'projectName',
                    decoration: const InputDecoration(
                      labelText: 'Project Name *',
                      prefixIcon: Icon(Icons.folder),
                    ),
                    validationMessages: {
                      'required': (error) => 'Project name is required',
                      'minLength': (error) => 'Minimum 3 characters',
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ReactiveDropdownField<String>(
                    formControlName: 'segment',
                    decoration: const InputDecoration(
                      labelText: 'Segment *',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _segments
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    validationMessages: {
                      'required': (error) => 'Segment is required',
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ReactiveDropdownField<String>(
                    formControlName: 'businessUnitGroup',
                    decoration: const InputDecoration(
                      labelText: 'Business Unit Group *',
                      prefixIcon: Icon(Icons.account_tree),
                    ),
                    items: _businessUnitGroups
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    validationMessages: {
                      'required': (error) => 'Business unit group is required',
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ReactiveDropdownField<String>(
                    formControlName: 'businessUnit',
                    decoration: const InputDecoration(
                      labelText: 'Business Unit *',
                      prefixIcon: Icon(Icons.domain),
                    ),
                    items: _businessUnits
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    validationMessages: {
                      'required': (error) => 'Business unit is required',
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeholdersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: ReactiveTextField<String>(
                formControlName: 'initiativeSponsor',
                decoration: const InputDecoration(
                  labelText: 'Initiative Sponsor',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ReactiveTextField<String>(
                formControlName: 'executiveSponsor',
                decoration: const InputDecoration(
                  labelText: 'Executive Sponsor',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ReactiveTextField<String>(
                formControlName: 'projectRequester',
                decoration: const InputDecoration(
                  labelText: 'Project Requester',
                  prefixIcon: Icon(Icons.person_pin),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: ReactiveDatePicker<DateTime>(
                formControlName: 'projectStartDate',
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, picker, child) {
                  return ReactiveTextField<DateTime>(
                    formControlName: 'projectStartDate',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Project Start Date *',
                      prefixIcon: const Icon(Icons.event),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: picker.showPicker,
                      ),
                    ),
                    valueAccessor: DateTimeValueAccessor(
                      dateTimeFormat: DateFormat('MMM dd, yyyy'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ReactiveDatePicker<DateTime>(
                formControlName: 'projectEndDate',
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, picker, child) {
                  return ReactiveTextField<DateTime>(
                    formControlName: 'projectEndDate',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Project End Date *',
                      prefixIcon: const Icon(Icons.event_available),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: picker.showPicker,
                      ),
                    ),
                    valueAccessor: DateTimeValueAccessor(
                      dateTimeFormat: DateFormat('MMM dd, yyyy'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ReactiveDatePicker<DateTime>(
                formControlName: 'benefitStartDate',
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, picker, child) {
                  return ReactiveTextField<DateTime>(
                    formControlName: 'benefitStartDate',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Benefit Start Date',
                      prefixIcon: const Icon(Icons.trending_up),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: picker.showPicker,
                      ),
                    ),
                    valueAccessor: DateTimeValueAccessor(
                      dateTimeFormat: DateFormat('MMM dd, yyyy'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ReactiveDropdownField<String>(
                    formControlName: 'currency',
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ReactiveTextField<String>(
                    formControlName: 'opExCostCenter',
                    decoration: const InputDecoration(
                      labelText: 'OpEx Cost Center',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'isCapExBudgeted',
                    title: const Text('CapEx Budgeted'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'isOpExBudgeted',
                    title: const Text('OpEx Budgeted'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ReactiveDropdownField<String>(
                    formControlName: 'icCategory',
                    decoration: const InputDecoration(
                      labelText: 'IC Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _icCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ReactiveTextField<String>(
                    formControlName: 'physicalAddress',
                    decoration: const InputDecoration(
                      labelText: 'Physical Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ReactiveTextField<String>(
              formControlName: 'description',
              decoration: const InputDecoration(
                labelText: 'Project Description *',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validationMessages: {
                'required': (error) => 'Description is required',
              },
            ),
            const SizedBox(height: 16),
            ReactiveTextField<String>(
              formControlName: 'rationale',
              decoration: const InputDecoration(
                labelText: 'Business Rationale',
                prefixIcon: Icon(Icons.lightbulb_outline),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'replacesCurrentAssets',
                    title: const Text('Replaces Current Assets'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'isHoaReimbursed',
                    title: const Text('HOA Reimbursed'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'hasGuaranteedMarketing',
                    title: const Text('Guaranteed Marketing'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'hasLongTermCommitment',
                    title: const Text('Long-Term Commitment'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'hasRealEstateLease',
                    title: const Text('Real Estate Lease'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: ReactiveCheckboxListTile(
                    formControlName: 'hasEquipmentLease',
                    title: const Text('Equipment Lease'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final dateFormat = DateFormat('MMM dd, yyyy h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: _existingProject!.status),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showStatusChangeDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Change Status'),
                ),
              ],
            ),
            if (_existingProject!.statusHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Status History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...(_existingProject!.statusHistory.reversed.take(5).map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusChip(status: note.status, small: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.note,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFormat.format(note.timestamp)}${note.userName != null ? ' by ${note.userName}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusChangeDialog() async {
    ProjectStatus? selectedStatus = _existingProject!.status;
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Project Status'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ProjectStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'New Status',
                    prefixIcon: Icon(Icons.assignment_turned_in),
                  ),
                  items: ProjectStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedStatus = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for status change *',
                    hintText: 'Enter the reason for this status change...',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a reason for this status change';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedStatus != null && mounted) {
      final user = ref.read(currentUserProvider);
      final newNote = StatusNote(
        status: selectedStatus!,
        note: noteController.text.trim(),
        timestamp: DateTime.now(),
        userId: user?.uid,
        userName: user?.displayName ?? user?.email,
      );

      final updatedHistory = [..._existingProject!.statusHistory, newNote];
      final updatedProject = _existingProject!.copyWith(
        status: selectedStatus,
        statusHistory: updatedHistory,
        updatedAt: DateTime.now(),
      );

      try {
        final repository = ref.read(projectRepositoryProvider);
        await repository.updateProject(updatedProject);

        setState(() {
          _existingProject = updatedProject;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    noteController.dispose();
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/projects'),
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: _isLoading ? null : _saveProject,
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_isEditing ? 'Update Project' : 'Create Project'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;
  final bool small;

  const _StatusChip({required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ProjectStatus.draft:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        break;
      case ProjectStatus.submitted:
      case ProjectStatus.pendingApproval:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case ProjectStatus.approved:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case ProjectStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case ProjectStatus.onHold:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case ProjectStatus.cancelled:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: small ? 11 : 13,
        ),
      ),
    );
  }
}
