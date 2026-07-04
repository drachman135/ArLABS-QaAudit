import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/bug_model.dart';
import '../data/bug_repository.dart';
import '../../project/data/project_repository.dart';
import '../../project/domain/project_model.dart';

class BugFormScreen extends ConsumerStatefulWidget {
  final String? bugId;
  final Bug? initialBug;
  final String? projectId;
  final String? moduleId;
  final String? featureId;
  final String? functionId;
  final String? auditId;

  const BugFormScreen({
    super.key,
    this.bugId,
    this.initialBug,
    this.projectId,
    this.moduleId,
    this.featureId,
    this.functionId,
    this.auditId,
  });

  @override
  ConsumerState<BugFormScreen> createState() => _BugFormScreenState();
}

class _BugFormScreenState extends ConsumerState<BugFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _stepsController;
  late TextEditingController _expectedController;
  late TextEditingController _actualController;
  late TextEditingController _assignedController;

  String _severity = 'Medium';
  String _status = 'Open';
  bool _isSaving = false;

  // Selected hierarchy values for global creation
  String? _selectedProjectId;
  String? _selectedModuleId;
  String? _selectedFeatureId;
  String? _selectedFunctionId;

  // Cache lists for cascade selectors
  List<Map<String, dynamic>> _moduleList = [];
  List<Map<String, dynamic>> _featureList = [];
  List<Map<String, dynamic>> _functionList = [];

  bool _isContextLocked = false;

  @override
  void initState() {
    super.initState();
    _isContextLocked = widget.functionId != null;

    final bug = widget.initialBug;
    _titleController = TextEditingController(text: bug?.title ?? '');
    _descController = TextEditingController(text: bug?.description ?? '');
    _stepsController = TextEditingController(text: bug?.stepsToReproduce ?? '');
    _expectedController = TextEditingController(text: bug?.expectedResult ?? '');
    _actualController = TextEditingController(text: bug?.actualResult ?? '');
    _assignedController = TextEditingController(text: bug?.assignedTo ?? '');
    
    if (bug != null) {
      _severity = bug.severity;
      _status = bug.status;
    }

    if (_isContextLocked) {
      _selectedProjectId = widget.projectId;
      _selectedModuleId = widget.moduleId;
      _selectedFeatureId = widget.featureId;
      _selectedFunctionId = widget.functionId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _assignedController.dispose();
    super.dispose();
  }

  void _onProjectChanged(String? projId, List<ProjectWithStats> projects) {
    setState(() {
      _selectedProjectId = projId;
      _selectedModuleId = null;
      _selectedFeatureId = null;
      _selectedFunctionId = null;
      _moduleList = [];
      _featureList = [];
      _functionList = [];

      if (projId != null) {
        final p = projects.firstWhere((p) => p.project.id == projId);
        _moduleList = (p.rawModulesJson as List? ?? [])
            .map((m) => m as Map<String, dynamic>)
            .toList();
      }
    });
  }

  void _onModuleChanged(String? modId) {
    setState(() {
      _selectedModuleId = modId;
      _selectedFeatureId = null;
      _selectedFunctionId = null;
      _featureList = [];
      _functionList = [];

      if (modId != null) {
        final mod = _moduleList.firstWhere((m) => m['id'] == modId);
        _featureList = (mod['features'] as List? ?? [])
            .map((f) => f as Map<String, dynamic>)
            .toList();
      }
    });
  }

  void _onFeatureChanged(String? featId) {
    setState(() {
      _selectedFeatureId = featId;
      _selectedFunctionId = null;
      _functionList = [];

      if (featId != null) {
        final feat = _featureList.firstWhere((f) => f['id'] == featId);
        _functionList = (feat['functions'] as List? ?? [])
            .map((fn) => fn as Map<String, dynamic>)
            .toList();
      }
    });
  }

  String _getProjectName(List<ProjectWithStats> projects, String id) {
    try {
      return projects.firstWhere((p) => p.project.id == id).project.name;
    } catch (_) {
      return id;
    }
  }

  String _getModuleName(List<ProjectWithStats> projects, String projId, String modId) {
    try {
      final p = projects.firstWhere((p) => p.project.id == projId);
      final m = p.rawModulesJson.firstWhere((m) => m['id'] == modId);
      return m['name'] as String;
    } catch (_) {
      return modId;
    }
  }

  String _getFeatureName(List<ProjectWithStats> projects, String projId, String modId, String featId) {
    try {
      final p = projects.firstWhere((p) => p.project.id == projId);
      final m = p.rawModulesJson.firstWhere((m) => m['id'] == modId);
      final f = (m['features'] as List).firstWhere((f) => f['id'] == featId);
      return f['name'] as String;
    } catch (_) {
      return featId;
    }
  }

  String _getFunctionName(List<ProjectWithStats> projects, String projId, String modId, String featId, String funcId) {
    try {
      final p = projects.firstWhere((p) => p.project.id == projId);
      final m = p.rawModulesJson.firstWhere((m) => m['id'] == modId);
      final f = (m['features'] as List).firstWhere((f) => f['id'] == featId);
      final fn = (f['functions'] as List).firstWhere((fn) => fn['id'] == funcId);
      return fn['name'] as String;
    } catch (_) {
      return funcId;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFunctionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target Function for the bug.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(bugRepositoryProvider);
      final listNotifier = ref.read(bugsListProvider.notifier);

      // Get or create audit ID for this function if not pre-provided
      String? auditId = widget.auditId;
      if (auditId == null) {
        auditId = await repository.getOrCreateAuditId(_selectedFunctionId!);
      }

      if (widget.bugId == null) {
        // Create new bug
        await listNotifier.addBug(
          auditId: auditId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          severity: _severity,
          status: _status,
          stepsToReproduce: _stepsController.text.trim().isEmpty ? null : _stepsController.text.trim(),
          expectedResult: _expectedController.text.trim().isEmpty ? null : _expectedController.text.trim(),
          actualResult: _actualController.text.trim().isEmpty ? null : _actualController.text.trim(),
          assignedTo: _assignedController.text.trim().isEmpty ? null : _assignedController.text.trim(),
          ref: ref,
        );
      } else {
        // Edit existing bug
        final updatedBug = widget.initialBug!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          severity: _severity,
          status: _status,
          stepsToReproduce: _stepsController.text.trim().isEmpty ? null : _stepsController.text.trim(),
          expectedResult: _expectedController.text.trim().isEmpty ? null : _expectedController.text.trim(),
          actualResult: _actualController.text.trim().isEmpty ? null : _actualController.text.trim(),
          assignedTo: _assignedController.text.trim().isEmpty ? null : _assignedController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await listNotifier.editBug(updatedBug, ref);
        ref.invalidate(bugDetailProvider(widget.bugId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.bugId == null ? 'Bug reported successfully.' : 'Bug updated successfully.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bugId == null ? 'Report Bug' : 'Edit Bug'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cascade Selectors Card or Lock info
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.2) : const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bug Context Hierarchy',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_isContextLocked) ...[
                        projectsAsync.when(
                          data: (projects) {
                            final projName = _getProjectName(projects, widget.projectId ?? '');
                            final modName = _getModuleName(projects, widget.projectId ?? '', widget.moduleId ?? '');
                            final featName = _getFeatureName(projects, widget.projectId ?? '', widget.moduleId ?? '', widget.featureId ?? '');
                            final funcName = _getFunctionName(projects, widget.projectId ?? '', widget.moduleId ?? '', widget.featureId ?? '', widget.functionId ?? '');
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLockedHierarchyRow('Project', projName),
                                _buildLockedHierarchyRow('Module', modName),
                                _buildLockedHierarchyRow('Feature', featName),
                                _buildLockedHierarchyRow('Function', funcName),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, st) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLockedHierarchyRow('Project', widget.projectId ?? ''),
                              _buildLockedHierarchyRow('Module', widget.moduleId ?? ''),
                              _buildLockedHierarchyRow('Feature', widget.featureId ?? ''),
                              _buildLockedHierarchyRow('Function', widget.functionId ?? ''),
                            ],
                          ),
                        ),
                      ] else ...[
                        projectsAsync.when(
                          data: (projects) {
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildDropdownSelector(
                                  label: 'Project',
                                  value: _selectedProjectId,
                                  items: projects.map((p) => DropdownMenuItem(value: p.project.id, child: Text(p.project.name))).toList(),
                                  onChanged: (val) => _onProjectChanged(val, projects),
                                ),
                                _buildDropdownSelector(
                                  label: 'Module',
                                  value: _selectedModuleId,
                                  items: _moduleList.map((m) => DropdownMenuItem<String>(value: m['id'] as String, child: Text(m['name'] as String))).toList(),
                                  onChanged: _onModuleChanged,
                                  enabled: _selectedProjectId != null,
                                ),
                                _buildDropdownSelector(
                                  label: 'Feature',
                                  value: _selectedFeatureId,
                                  items: _featureList.map((f) => DropdownMenuItem<String>(value: f['id'] as String, child: Text(f['name'] as String))).toList(),
                                  onChanged: _onFeatureChanged,
                                  enabled: _selectedModuleId != null,
                                ),
                                _buildDropdownSelector(
                                  label: 'Function',
                                  value: _selectedFunctionId,
                                  items: _functionList.map((fn) => DropdownMenuItem<String>(value: fn['id'] as String, child: Text(fn['name'] as String))).toList(),
                                  onChanged: (val) => setState(() => _selectedFunctionId = val),
                                  enabled: _selectedFeatureId != null,
                                ),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (err, st) => Text('Error loading projects: $err'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Form details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bug Information',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Bug Title *',
                          hintText: 'e.g., App crashes when saving blank username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Provide a brief summary of the bug...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Severity Selector Chips
                      Text('Severity *', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildSeverityChips(),
                      const SizedBox(height: 20),

                      // Status Selector Chips
                      Text('Status *', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildStatusChips(),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _stepsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Steps To Reproduce',
                          hintText: '1. Go to settings page\n2. Clear username field\n3. Click save',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expectedController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Expected Result',
                                hintText: 'Error warning should appear saying username cannot be blank',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _actualController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Actual Result',
                                hintText: 'The screen freezes and shows loading spinner indefinitely',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _assignedController,
                        decoration: const InputDecoration(
                          labelText: 'Assigned To',
                          hintText: 'e.g., John Doe (Lead Developer)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_rounded),
                            label: Text(widget.bugId == null ? 'Report Bug' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedHierarchyRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: enabled ? items : [],
        onChanged: enabled ? onChanged : null,
        disabledHint: Text('Select $label'),
      ),
    );
  }

  Widget _buildSeverityChips() {
    final severities = ['Critical', 'High', 'Medium', 'Low'];
    return Wrap(
      spacing: 8,
      children: severities.map((sev) {
        final isSelected = _severity == sev;
        Color color = Colors.grey;
        if (sev == 'Critical') color = const Color(0xFF7F1D1D); // Merah pekat
        if (sev == 'High') color = const Color(0xFFEF4444); // Merah
        if (sev == 'Medium') color = const Color(0xFFF59E0B); // Oranye
        if (sev == 'Low') color = const Color(0xFF10B981); // Hijau

        return ChoiceChip(
          label: Text(
            sev,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
          selected: isSelected,
          selectedColor: color,
          backgroundColor: color.withOpacity(0.08),
          onSelected: (selected) {
            if (selected) setState(() => _severity = sev);
          },
        );
      }).toList(),
    );
  }

  Widget _buildStatusChips() {
    final statuses = ['Open', 'In Progress', 'Ready To Test', 'Resolved', 'Closed', 'Rejected'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((st) {
        final isSelected = _status == st;
        Color color = Colors.grey;
        if (st == 'Open') color = const Color(0xFF3B82F6); // Blue
        if (st == 'In Progress') color = const Color(0xFF8B5CF6); // Purple
        if (st == 'Ready To Test') color = const Color(0xFFF59E0B); // Orange
        if (st == 'Resolved') color = const Color(0xFF10B981); // Green
        if (st == 'Closed') color = const Color(0xFF64748B); // Slate
        if (st == 'Rejected') color = const Color(0xFFEF4444); // Red

        return ChoiceChip(
          label: Text(
            st,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
          selected: isSelected,
          selectedColor: color,
          backgroundColor: color.withOpacity(0.08),
          onSelected: (selected) {
            if (selected) setState(() => _status = st);
          },
        );
      }).toList(),
    );
  }
}
