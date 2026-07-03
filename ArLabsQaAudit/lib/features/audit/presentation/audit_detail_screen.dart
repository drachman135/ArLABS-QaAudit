import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/audit_model.dart';
import '../data/audit_repository.dart';
import '../../project/data/project_tree_provider.dart';
import '../../project/data/project_repository.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../bug/data/bug_repository.dart';

class AuditDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String moduleId;
  final String featureId;
  final String functionId;
  final String functionName;
  final String moduleName;
  final String featureName;
  final Audit? initialAudit;

  const AuditDetailScreen({
    super.key,
    required this.projectId,
    required this.moduleId,
    required this.featureId,
    required this.functionId,
    required this.functionName,
    required this.moduleName,
    required this.featureName,
    this.initialAudit,
  });

  @override
  ConsumerState<AuditDetailScreen> createState() => _AuditDetailScreenState();
}

class _AuditDetailScreenState extends ConsumerState<AuditDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _status;
  String? _priority;
  late TextEditingController _notesController;
  late TextEditingController _auditorController;
  bool _isSaving = false;

  final List<String> _statusOptions = [
    'Not Tested',
    'Passed',
    'Failed',
    'Warning',
    'Not Implemented',
    'Skipped',
  ];

  final List<String> _priorityOptions = ['P0', 'P1', 'P2', 'P3'];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Passed':
        return const Color(0xFF10B981); // Emerald Green
      case 'Failed':
        return const Color(0xFFEF4444); // Red
      case 'Warning':
        return const Color(0xFFF59E0B); // Amber
      case 'Skipped':
        return const Color(0xFF3B82F6); // Blue
      case 'Not Implemented':
        return const Color(0xFF334155); // Slate/Dark Gray
      default:
        return const Color(0xFF64748B); // Cool Gray for Not Tested
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Passed':
        return Icons.check_circle_rounded;
      case 'Failed':
        return Icons.cancel_rounded;
      case 'Warning':
        return Icons.warning_rounded;
      case 'Skipped':
        return Icons.skip_next_rounded;
      case 'Not Implemented':
        return Icons.construction_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _status = widget.initialAudit?.status ?? 'Not Tested';
    _priority = widget.initialAudit?.priority;
    _notesController = TextEditingController(text: widget.initialAudit?.notes);
    _auditorController = TextEditingController(text: widget.initialAudit?.auditorName ?? 'QA Auditor');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _auditorController.dispose();
    super.dispose();
  }

  Future<void> _saveAudit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(auditRepositoryProvider);
      final savedAudit = await repository.upsertAudit(
        functionId: widget.functionId,
        status: _status,
        priority: _priority,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        auditorName: _auditorController.text.trim().isEmpty ? null : _auditorController.text.trim(),
      );

      // Local State Update inside the project tree notifier (immediate update without full reload)
      ref
          .read(projectTreeProvider(widget.projectId).notifier)
          .updateFunctionAudit(widget.moduleId, widget.featureId, widget.functionId, savedAudit);

      // Invalidate dashboard stats & activity logs
      ref.invalidate(projectListProvider);
      ref.invalidate(recentAuditsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Audit untuk "${widget.functionName}" berhasil disimpan.'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan audit: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
    final bugsAsync = ref.watch(bugsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulir Audit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context Breadcrumbs & Header
                    Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.3) : const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_tree_outlined, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${widget.moduleName}  /  ${widget.featureName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.functionName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Auditor Details Input Card
                    Text(
                      'Profil Auditor',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _auditorController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Auditor',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama auditor wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Status Dropdown
                    Text(
                      'Status Audit',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        prefixIcon: Icon(_getStatusIcon(_status), color: _getStatusColor(_status)),
                      ),
                      items: _statusOptions.map((status) {
                        final color = _getStatusColor(status);
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(status, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _status = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Priority Segmented Control (P0, P1, P2, P3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tingkat Prioritas',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_priority != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _priority = null;
                              });
                            },
                            child: const Text('Hapus'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _priorityOptions.map((opt) {
                        final isSelected = _priority == opt;
                        Color btnColor = Colors.grey.shade400;
                        if (isSelected) {
                          switch (opt) {
                            case 'P0':
                              btnColor = const Color(0xFFEF4444);
                              break;
                            case 'P1':
                              btnColor = const Color(0xFFF97316);
                              break;
                            default:
                              btnColor = const Color(0xFF6366F1);
                              break;
                          }
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _priority = opt;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? btnColor.withOpacity(0.12) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? btnColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? btnColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Notes (multi-line)
                    Text(
                      'Catatan Audit',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Tulis temuan, langkah reproduksi, catatan, atau perilaku yang diharapkan...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Actions Buttons (Save/Cancel)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => context.pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveAudit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Simpan Audit'),
                        ),
                      ],
                    ),

                    // Reported Bugs Section
                    if (widget.initialAudit != null) ...[
                      const SizedBox(height: 48),
                      const Divider(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bug yang Dilaporkan',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push(
                                '/projects/${widget.projectId}/modules/${widget.moduleId}/features/${widget.featureId}/functions/${widget.functionId}/audit/new-bug',
                                extra: {'auditId': widget.initialAudit!.id},
                              );
                            },
                            icon: const Icon(Icons.bug_report_rounded, size: 16),
                            label: const Text('Laporkan Bug'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      bugsAsync.when(
                        data: (bugs) {
                          final auditBugs = bugs.where((b) => b.auditId == widget.initialAudit!.id).toList();
                          if (auditBugs.isEmpty) {
                            return Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF1E293B).withOpacity(0.15) : const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'Belum ada bug yang dilaporkan untuk audit ini.',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: auditBugs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final bug = auditBugs[index];
                              return Card(
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.bug_report_rounded, color: Color(0xFFEF4444)),
                                  title: Text(bug.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Keparahan: ${bug.severity} • Status: ${bug.status}', style: const TextStyle(fontSize: 11)),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 16),
                                  onTap: () => context.push('/bugs/${bug.id}'),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error loading bugs: $err'),
                      ),
                    ] else ...[
                      const SizedBox(height: 48),
                      const Divider(),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 0,
                        color: isDark ? const Color(0xFF1E293B).withOpacity(0.1) : const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Simpan data audit terlebih dahulu untuk dapat melaporkan bug pada fungsi ini.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
