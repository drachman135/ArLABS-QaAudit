import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/bug_model.dart';
import '../data/bug_repository.dart';
import '../../../core/widgets/empty_state.dart';
import '../../attachment/presentation/widgets/attachment_section_widget.dart';

class BugDetailScreen extends ConsumerWidget {
  final String bugId;

  const BugDetailScreen({super.key, required this.bugId});

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFF7F1D1D); // Merah pekat
      case 'High':
        return const Color(0xFFEF4444); // Merah
      case 'Medium':
        return const Color(0xFFF59E0B); // Oranye
      case 'Low':
        return const Color(0xFF10B981); // Hijau
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFF3B82F6); // Blue
      case 'In Progress':
        return const Color(0xFF8B5CF6); // Purple
      case 'Ready To Test':
        return const Color(0xFFF59E0B); // Orange
      case 'Resolved':
        return const Color(0xFF10B981); // Green
      case 'Closed':
        return const Color(0xFF64748B); // Slate
      case 'Rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Bug bug) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bug'),
        content: Text('Are you sure you want to permanently delete bug "${bug.title}"? This action uses soft delete.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(bugsListProvider.notifier).softDelete(bug.id, ref);
              Navigator.pop(context); // Close dialog
              context.pop(); // Close detail screen back to list
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bugAsync = ref.watch(bugDetailProvider(bugId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bug Details'),
        surfaceTintColor: Colors.transparent,
      ),
      body: bugAsync.when(
        data: (bug) {
          final sevColor = _getSeverityColor(bug.severity);
          final statColor = _getStatusColor(bug.status);
          
          final createdStr = "${bug.createdAt.day}/${bug.createdAt.month}/${bug.createdAt.year} ${bug.createdAt.hour}:${bug.createdAt.minute.toString().padLeft(2, '0')}";
          final updatedStr = "${bug.updatedAt.day}/${bug.updatedAt.month}/${bug.updatedAt.year} ${bug.updatedAt.hour}:${bug.updatedAt.minute.toString().padLeft(2, '0')}";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bug.title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Severity Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sevColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: sevColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  'Severity: ${bug.severity}',
                                  style: TextStyle(
                                    color: sevColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  'Status: ${bug.status}',
                                  style: TextStyle(
                                    color: statColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Action Buttons
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push('/bugs/${bug.id}/edit', extra: {'bug': bug});
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirmDialog(context, ref, bug),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Context Info Panel
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
                          'Context Info Path',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoPathRow(context, 'Project', bug.projectName ?? '-'),
                        _buildInfoPathRow(context, 'Module', bug.moduleName ?? '-'),
                        _buildInfoPathRow(context, 'Feature', bug.featureName ?? '-'),
                        _buildInfoPathRow(context, 'Function', bug.functionName ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Description Detail Card
                _buildDetailCard(context, 'Description', bug.description),
                const SizedBox(height: 24),

                // Steps to reproduce
                if (bug.stepsToReproduce != null && bug.stepsToReproduce!.isNotEmpty) ...[
                  _buildDetailCard(context, 'Steps To Reproduce', bug.stepsToReproduce!),
                  const SizedBox(height: 24),
                ],

                // Expected & Actual Results
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bug.expectedResult != null && bug.expectedResult!.isNotEmpty)
                      Expanded(child: _buildDetailCard(context, 'Expected Result', bug.expectedResult!)),
                    if (bug.expectedResult != null && bug.expectedResult!.isNotEmpty && bug.actualResult != null && bug.actualResult!.isNotEmpty)
                      const SizedBox(width: 24),
                    if (bug.actualResult != null && bug.actualResult!.isNotEmpty)
                      Expanded(child: _buildDetailCard(context, 'Actual Result', bug.actualResult!)),
                  ],
                ),
                const SizedBox(height: 32),

                // Attachments Section
                AttachmentSectionWidget(
                  bugId: bug.id,
                  projectId: bug.projectId ?? '',
                  parentName: bug.title,
                ),
                const SizedBox(height: 32),

                // Footer Metadata
                const Divider(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    _buildMetadataText(context, 'Assigned To', bug.assignedTo ?? 'Unassigned', Icons.person_rounded),
                    _buildMetadataText(context, 'Reported At', createdStr, Icons.calendar_today_rounded),
                    _buildMetadataText(context, 'Last Updated', updatedStr, Icons.update_rounded),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Error loading bug details',
          description: err.toString(),
        ),
      ),
    );
  }

  Widget _buildInfoPathRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataText(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
